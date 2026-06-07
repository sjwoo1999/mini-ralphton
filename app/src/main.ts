import { render } from './render';

const root = document.querySelector<HTMLElement>('#app');
if (root) {
  render(root, { state: 'ready', score: 0 });
}
