import { GameState, transition } from './game';

export type RenderModel = {
  state: GameState;
  score: number;
  milestone?: number | null;
};

export function render(root: HTMLElement, model: RenderModel): void {
  root.innerHTML = '';

  const title = document.createElement('h1');
  title.textContent = 'Busan Gull Runner';
  root.append(title);

  const gull = document.createElement('div');
  gull.dataset.role = 'gull';
  gull.textContent = 'seagull';
  root.append(gull);

  const obstacle = document.createElement('div');
  obstacle.dataset.role = 'obstacle';
  obstacle.textContent = 'obstacle';
  root.append(obstacle);

  const scoreNode = document.createElement('output');
  scoreNode.dataset.role = 'score';
  scoreNode.textContent = String(model.score);
  root.append(scoreNode);

  if (model.state === 'gameover') {
    const retry = document.createElement('button');
    retry.textContent = '다시 도전';
    root.append(retry);
  }

  if (model.milestone) {
    const burst = document.createElement('div');
    burst.className = 'burst';
    burst.textContent = String(model.milestone);
    root.append(burst);
  }
}

export function attachSpaceHandler(target: Document, getState: () => GameState, setState: (state: GameState) => void, onJump: () => void): void {
  target.addEventListener('keydown', (event) => {
    if (event.code !== 'Space') return;
    const state = getState();
    if (state === 'playing') {
      onJump();
      return;
    }
    setState(transition(state, 'space'));
  });
}
