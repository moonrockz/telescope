// Original Telescope qualification fixture, Apache-2.0.
const mount = document.getElementById('registered-counter');
if (mount) {
  let count = 0;
  const button = document.createElement('button');
  button.textContent = 'Registered observations: 0';
  button.addEventListener('click', () => {
    button.textContent = `Registered observations: ${++count}`;
  });
  mount.replaceChildren(button);
}
