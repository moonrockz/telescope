import { spawn, execFileSync, type ChildProcess } from 'node:child_process';
import { cp, mkdir, readFile, rm, writeFile } from 'node:fs/promises';
import { createServer } from 'node:net';
import { resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const repo = fileURLToPath(new URL('../../', import.meta.url));
export const work = resolve(repo, '_build/browser/work');
export const statePath = resolve(work, 'servers.json');
export type Servers = Record<string, { base: string; plain: string; versions: string; prerelease: string; registered: string }>;

async function freePort(): Promise<number> {
  const reservation = createServer();
  await new Promise<void>(done => reservation.listen(0, '127.0.0.1', done));
  const address = reservation.address();
  if (!address || typeof address === 'string') throw new Error('No loopback port');
  await new Promise<void>((done, reject) => reservation.close(error => error ? reject(error) : done()));
  return address.port;
}

async function stop(child: ChildProcess) {
  if (child.exitCode !== null || child.signalCode !== null) return;
  const exited = new Promise<void>(done => child.once('exit', () => done()));
  child.kill('SIGTERM');
  const timer = setTimeout(() => child.kill('SIGKILL'), 3000);
  await exited;
  clearTimeout(timer);
}

export default async function setup() {
  const cli = resolve(repo, process.env.TELESCOPE_CLI || '_build/telescope/telescope');
  const driver = resolve(repo, process.env.TELESCOPE_BROWSER_DRIVER ||
    '_build/native/release/build/qualification/browser-driver/cmd/cmd.exe');
  const cliVersion = execFileSync(cli, ['--version'], { encoding: 'utf8' }).trim();
  const children: ChildProcess[] = [];
  const commands: { executable: string; args: string[]; cwd: string; stdout: string; stderr: string }[] = [];
  const serveCommands: { executable: string; args: string[]; cwd: string; stdout: string; stderr: string; pid: number | undefined }[] = [];
  function run(args: string[], cwd: string, executable = cli) {
    const child = spawn(executable, args, { cwd, stdio: ['ignore', 'pipe', 'pipe'] });
    let stdout = '', stderr = '';
    child.stdout.on('data', data => { stdout += data; });
    child.stderr.on('data', data => { stderr += data; });
    return new Promise<void>((done, reject) => {
      child.once('error', reject);
      child.once('exit', code => {
        commands.push({ executable, args, cwd, stdout, stderr });
        if (code === 0) done();
        else reject(new Error(`CLI ${args.join(' ')} exited ${code}\n${stdout}\n${stderr}`));
      });
    });
  }
  async function serve(out: string, config: string, base: string) {
    const port = await freePort();
    const args = ['serve', '--config', config, '--out', out, '--base', base, '--port', String(port)];
    const child = spawn(cli, args, { cwd: repo, stdio: ['ignore', 'pipe', 'pipe'] });
    children.push(child);
    const execution = { executable: cli, args, cwd: repo, stdout: '', stderr: '', pid: child.pid };
    serveCommands.push(execution);
    let log = '';
    child.stdout?.on('data', data => { log += data; execution.stdout += data; });
    child.stderr?.on('data', data => { log += data; execution.stderr += data; });
    let failure: Error | undefined;
    child.once('error', error => { failure = error; });
    const origin = `http://127.0.0.1:${port}`;
    const deadline = Date.now() + 10_000;
    while (Date.now() < deadline) {
      if (failure || child.exitCode !== null) throw failure || new Error(`CLI serve exited: ${log}`);
      try {
        if ((await fetch(origin + base)).ok) return origin;
      } catch { /* The listener is not ready yet. */ }
      await new Promise(done => setTimeout(done, 50));
    }
    throw new Error(`CLI serve not ready: ${log}`);
  }

  await rm(work, { recursive: true, force: true });
  await mkdir(work, { recursive: true });
  const servers: Servers = {};
  try {
    for (const [name, base] of [['root', '/'], ['nested', '/example/']]) {
      const dir = resolve(work, name);
      await mkdir(dir, { recursive: true });
      const built: Record<string, { out: string; config: string; base_path: string }> = {};
      for (const id of ['plain', 'next', '0.2', '0.1']) {
        const project = resolve(dir, `input-${id}`);
        await cp(new URL('./fixture/', import.meta.url), project, { recursive: true });
        if (id !== 'next' && id !== 'plain') await rm(resolve(project, 'docs/next-only.md'));
        if (id !== '0.1') await rm(resolve(project, 'docs/retired.md'));
        const base_path = base + (id === 'plain' ? '' : id === 'next' ? 'next/' : `v/${id}/`);
        const config = resolve(project, 'site/site.json');
        const json = JSON.parse(await readFile(config, 'utf8'));
        await writeFile(config, JSON.stringify({ ...json, base_path,
          site_url: `https://observatory.example${base_path}` }, null, 2));
        const out = resolve(dir, `tree-${id}`);
        await run(['build', '--config', 'site/site.json', '--out', out], project);
        await run(['check', '--config', 'site/site.json', '--out', out, '--format', 'json'], project);
        built[id] = { out, config, base_path };
      }
      for (const [kind, latest, ids] of [
        ['versions', '0.2', ['next', '0.2', '0.1']],
        ['prerelease', '', ['next']],
      ] as const) {
        const manifest = resolve(dir, `${kind}.json`);
        await writeFile(manifest, JSON.stringify({ schema_version: 1, base_path: base,
          site_url: `https://observatory.example${base}`, ...(latest ? { latest } : {}),
          trees: ids.map(id => ({ id, path: `tree-${id}`, base_path: built[id].base_path })) }));
        await run(['assemble', '--manifest', manifest, '--out', resolve(dir, kind)], repo);
      }
      const registered = resolve(dir, 'registered');
      const registeredInput = resolve(dir, 'input-registered');
      await cp(resolve(dir, 'input-plain'), registeredInput, { recursive: true });
      await cp(new URL('./driver/consumer/', import.meta.url), resolve(registeredInput, 'consumer'), { recursive: true });
      const registeredConfig = resolve(registeredInput, 'site/site.json');
      const registeredJSON = JSON.parse(await readFile(registeredConfig, 'utf8'));
      await writeFile(registeredConfig, JSON.stringify({ ...registeredJSON,
        source_roots: [...registeredJSON.source_roots, 'consumer'] }));
      await run([registeredConfig, registered, registeredInput], registeredInput, driver);
      await run(['check', '--config', registeredConfig, '--out', registered, '--format', 'json'], repo);
      servers[name] = { base,
        plain: await serve(built.plain.out, built.plain.config, base),
        versions: await serve(resolve(dir, 'versions'), built.plain.config, base),
        prerelease: await serve(resolve(dir, 'prerelease'), built.plain.config, base),
        registered: await serve(registered, registeredConfig, base) };
    }
    await writeFile(statePath, JSON.stringify(servers));
    await writeFile(resolve(work, '../cli-evidence.json'), JSON.stringify({
      cli, driver, cliVersion, platform: process.platform, architecture: process.arch,
      playwright: '1.64.1', commands, serveCommands, servers,
      note: 'CLI trees come from native build/assemble; registered tree comes from the public host.build library driver with explicit providers. All are checked and served by native CLI. No output patching.',
    }, null, 2));
  } catch (error) {
    await Promise.all(children.map(stop));
    await writeFile(resolve(work, '../cli-evidence.json'), JSON.stringify({ cli, cliVersion, commands, serveCommands,
      error: String(error) }, null, 2));
    throw error;
  }
  return async () => { await Promise.all(children.map(stop)); };
}
