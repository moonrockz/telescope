// Keep shared fixture and report destinations exclusive across Orca workers.
import { spawn } from 'node:child_process';
import { mkdir, rm, writeFile } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';

const lock = new URL('../../_build/browser.lock/', import.meta.url);
await mkdir(new URL('../../_build/', import.meta.url), { recursive: true });
try {
  await mkdir(lock);
} catch (error) {
  if (error.code !== 'EEXIST') throw error;
  throw new Error(`Another browser qualification owns ${fileURLToPath(lock)}. Wait for it to finish; if its owner process has exited, remove the stale lock.`);
}
try {
  await writeFile(new URL('owner.txt', lock), `PID ${process.pid}\n`);
  const child = spawn(process.execPath, [
    fileURLToPath(new URL('./node_modules/@playwright/test/cli.js', import.meta.url)),
    'test', ...process.argv.slice(2),
  ], { cwd: fileURLToPath(new URL('./', import.meta.url)), stdio: 'inherit' });
  const interrupt = () => child.kill('SIGINT');
  const terminate = () => child.kill('SIGTERM');
  process.on('SIGINT', interrupt);
  process.on('SIGTERM', terminate);
  const status = await new Promise((done, reject) => {
    child.once('error', reject);
    child.once('exit', (code, signal) => done(code ?? (signal ? 1 : 0)));
  });
  process.off('SIGINT', interrupt);
  process.off('SIGTERM', terminate);
  process.exitCode = status;
} finally {
  await rm(lock, { recursive: true, force: true });
}
