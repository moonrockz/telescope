// Original Telescope fixture, Apache-2.0. Route-specific progressive enhancement.
const mount = document.getElementById('consumer-counter');
if (mount) {
  const button = document.createElement('button');
  let count = 0;
  button.type = 'button';
  button.textContent = 'Count: 0';
  button.addEventListener('click', () => { button.textContent = `Count: ${++count}`; });
  mount.append(button);
}
