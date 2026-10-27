// Original Telescope qualification fixture, Apache-2.0.
const mount = document.getElementById('fixture-counter');
if (mount) {
  let count = 0;
  const button = document.createElement('button');
  button.textContent = 'Observations: 0';
  button.addEventListener('click', () => {
    button.textContent = `Observations: ${++count}`;
  });
  mount.replaceChildren(button);
}
