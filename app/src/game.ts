export type Box = {
  x: number;
  y: number;
  w: number;
  h: number;
};

export type GameState = 'ready' | 'playing' | 'gameover';

export function jump(t: number, totalTicks = 60, height = 80): number {
  if (t <= 0 || t >= totalTicks) return 0;
  const p = t / totalTicks;
  return 4 * height * p * (1 - p);
}

export function hit(a: Box, b: Box): boolean {
  return a.x < b.x + b.w && a.x + a.w > b.x && a.y < b.y + b.h && a.y + a.h > b.y;
}

export function score(passed: number, ticks: number): number {
  return passed * 10 + Math.floor(ticks / 60);
}

export function transition(state: GameState, event: 'space' | 'collision'): GameState {
  if (state === 'ready' && event === 'space') return 'playing';
  if (state === 'playing' && event === 'collision') return 'gameover';
  if (state === 'gameover' && event === 'space') return 'ready';
  return state;
}

export function speed(ticks: number): number {
  return Math.min(4 + Math.floor(ticks / 600), 10);
}

export function milestone(previous: number, next: number): { at: number } | null {
  const prevBand = Math.floor(previous / 100);
  const nextBand = Math.floor(next / 100);
  if (nextBand > prevBand) return { at: nextBand * 100 };
  return null;
}
