///|
/// Local filtering preserves real family fragments and the static catalogue.
extern "js" fn gallery_browser() -> Unit =
  #| () => {
  #|   const root = document.querySelector('[data-gallery-index]');
  #|   if (!root || root.hasAttribute('data-enhanced')) return;
  #|   const tools = root.querySelector('.gallery-tools');
  #|   const rail = root.querySelector('.gallery-rail');
  #|   const groups = [...root.querySelectorAll('.gallery-group')];
  #|   if (!tools || !rail) return;
  #|   const links = [...rail.querySelectorAll('[data-gallery-family]')];
  #|   const label = document.createElement('label');
  #|   label.textContent = 'Filter examples';
  #|   const input = document.createElement('input');
  #|   input.type = 'search';
  #|   input.placeholder = 'Title, family or description';
  #|   label.append(input);
  #|   const count = document.createElement('p');
  #|   count.className = 'gallery-results';
  #|   count.setAttribute('role', 'status');
  #|   count.setAttribute('aria-live', 'polite');
  #|   count.setAttribute('aria-atomic', 'true');
  #|   const reset = document.createElement('button');
  #|   reset.type = 'button';
  #|   reset.textContent = 'Reset filters';
  #|   const empty = document.createElement('div');
  #|   empty.className = 'gallery-empty';
  #|   const message = document.createElement('p');
  #|   message.textContent = 'No examples match these filters.';
  #|   const emptyReset = reset.cloneNode(true);
  #|   empty.append(message, emptyReset);
  #|   const all = document.createElement('a');
  #|   all.href = '#gallery-all';
  #|   all.textContent = 'All examples';
  #|   const familyFromHash = () => links.find(a => a.hash === location.hash)?.dataset.galleryFamily;
  #|   const update = () => {
  #|     const family = familyFromHash();
  #|     const query = input.value.trim().toLocaleLowerCase();
  #|     let matches = 0;
  #|     for (const group of groups) {
  #|       let visible = 0;
  #|       for (const card of group.querySelectorAll('.gallery-card')) {
  #|         const show = (!family || group.id === family) && card.dataset.gallerySearch.toLocaleLowerCase().includes(query);
  #|         card.hidden = !show;
  #|         if (show) visible++;
  #|       }
  #|       group.hidden = visible === 0;
  #|       matches += visible;
  #|     }
  #|     for (const link of [...links, all]) {
  #|       if (family ? link.dataset.galleryFamily === family : link === all) link.setAttribute('aria-current', 'true');
  #|       else link.removeAttribute('aria-current');
  #|     }
  #|     count.textContent = `${matches} ${matches === 1 ? 'example' : 'examples'}`;
  #|     empty.hidden = matches !== 0;
  #|   };
  #|   const clear = () => {
  #|     input.value = '';
  #|     if (location.hash) history.pushState(null, '', location.pathname + location.search);
  #|     update();
  #|     input.focus();
  #|   };
  #|   input.addEventListener('input', update);
  #|   reset.addEventListener('click', clear);
  #|   emptyReset.addEventListener('click', clear);
  #|   window.addEventListener('hashchange', update);
  #|   window.addEventListener('popstate', update);
  #|   tools.append(label, reset, count);
  #|   rail.prepend(all);
  #|   tools.after(empty);
  #|   root.setAttribute('data-enhanced', 'true');
  #|   update();
  #| }

///|
/// Both sections are visible until tab setup succeeds. Copy reads literal text.
extern "js" fn gallery_detail() -> Unit =
  #| () => {
  #|   for (const root of document.querySelectorAll('[data-gallery-workbench]')) {
  #|     if (root.hasAttribute('data-enhanced')) continue;
  #|     const mount = root.querySelector('.gallery-tabs');
  #|     const panels = [...root.querySelectorAll(':scope > .gallery-panel')];
  #|     if (!mount || panels.length !== 2) continue;
  #|     const tabs = panels.map((panel, i) => {
  #|       const tab = document.createElement('button');
  #|       tab.type = 'button';
  #|       tab.className = 'gallery-tab';
  #|       tab.id = panel.id + '-tab';
  #|       tab.textContent = i === 0 ? 'Preview' : 'Source';
  #|       tab.setAttribute('role', 'tab');
  #|       tab.setAttribute('aria-controls', panel.id);
  #|       return tab;
  #|     });
  #|     const select = (selected, focus = false) => {
  #|       tabs.forEach((tab, i) => {
  #|         tab.setAttribute('aria-selected', String(i === selected));
  #|         tab.tabIndex = i === selected ? 0 : -1;
  #|         panels[i].hidden = i !== selected;
  #|       });
  #|       if (focus) tabs[selected].focus();
  #|     };
  #|     tabs.forEach((tab, i) => {
  #|       tab.addEventListener('click', () => select(i));
  #|       tab.addEventListener('keydown', e => {
  #|         const target = { ArrowLeft: (i + tabs.length - 1) % tabs.length, ArrowRight: (i + 1) % tabs.length, Home: 0, End: tabs.length - 1 }[e.key];
  #|         if (target !== undefined) { e.preventDefault(); select(target, true); }
  #|       });
  #|       panels[i].setAttribute('role', 'tabpanel');
  #|       panels[i].setAttribute('aria-labelledby', tab.id);
  #|       panels[i].tabIndex = 0;
  #|     });
  #|     const files = [...root.querySelectorAll('.gallery-source-file')];
  #|     if (files.length > 1) {
  #|       const label = document.createElement('label');
  #|       label.className = 'gallery-source-select';
  #|       label.textContent = 'Source file';
  #|       const select = document.createElement('select');
  #|       select.id = panels[1].id + '-file-select';
  #|       label.htmlFor = select.id;
  #|       files.forEach((file, i) => {
  #|         const option = document.createElement('option');
  #|         option.value = String(i);
  #|         option.textContent = file.querySelector('h3').textContent;
  #|         select.append(option);
  #|       });
  #|       const selectFile = () => files.forEach((file, i) => { file.hidden = String(i) !== select.value; });
  #|       select.addEventListener('change', selectFile);
  #|       label.append(select);
  #|       panels[1].querySelector('h2').after(label);
  #|       selectFile();
  #|     }
  #|     for (const file of files) {
  #|       const code = file.querySelector('pre code');
  #|       const actions = file.querySelector('.gallery-actions');
  #|       if (!code || !actions) continue;
  #|       const button = document.createElement('button');
  #|       button.type = 'button';
  #|       button.textContent = 'Copy source';
  #|       button.setAttribute('aria-label', 'Copy source: ' + file.querySelector('h3').textContent);
  #|       const status = document.createElement('span');
  #|       status.setAttribute('role', 'status');
  #|       status.setAttribute('aria-live', 'polite');
  #|       button.addEventListener('click', async () => {
  #|         try {
  #|           if (!navigator.clipboard) throw new Error('Clipboard unavailable');
  #|           await navigator.clipboard.writeText(code.textContent);
  #|           status.textContent = 'Source copied.';
  #|         } catch {
  #|           const selection = window.getSelection();
  #|           const range = document.createRange();
  #|           range.selectNodeContents(code);
  #|           selection?.removeAllRanges();
  #|           selection?.addRange(range);
  #|           status.textContent = 'Copy unavailable. Select and copy the source text, or download it.';
  #|         }
  #|       });
  #|       actions.append(button, status);
  #|     }
  #|     mount.setAttribute('role', 'tablist');
  #|     mount.setAttribute('aria-label', root.closest('.gallery-card') ? root.dataset.galleryTitle + ' inspection' : 'Example inspection');
  #|     mount.append(...tabs);
  #|     root.setAttribute('data-enhanced', 'true');
  #|     select(0);
  #|   }
  #| }
