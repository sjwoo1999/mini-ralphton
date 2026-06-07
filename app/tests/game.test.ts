import { describe, expect, it, vi } from 'vitest';
import { hit, jump, milestone, score, speed, transition } from '../src/game';
import { attachSpaceHandler, render } from '../src/render';

describe('Busan Gull Runner SPEC-B', () => {
  it('[S1] jump(t) follows the golden parabola', () => {
    expect(jump(0)).toBe(0);
    expect(jump(30)).toBe(80);
    expect(jump(60)).toBe(0);
  });

  it('[S2] hit(a,b) uses AABB and excludes touching edges', () => {
    expect(hit({ x: 0, y: 0, w: 10, h: 10 }, { x: 5, y: 5, w: 10, h: 10 })).toBe(true);
    expect(hit({ x: 0, y: 0, w: 10, h: 10 }, { x: 20, y: 20, w: 10, h: 10 })).toBe(false);
    expect(hit({ x: 0, y: 0, w: 10, h: 10 }, { x: 10, y: 0, w: 10, h: 10 })).toBe(false);
  });

  it('[S3] score(passed,ticks) combines obstacles and elapsed seconds', () => {
    expect(score(3, 300)).toBe(35);
  });

  it('[S4] state machine allows only the specified transitions', () => {
    expect(transition('ready', 'space')).toBe('playing');
    expect(transition('playing', 'collision')).toBe('gameover');
    expect(transition('gameover', 'space')).toBe('ready');
    expect(transition('ready', 'collision')).toBe('ready');
  });

  it('[S5] DOM render exposes gull, obstacle, score, and retry copy', () => {
    const root = document.createElement('main');
    render(root, { state: 'gameover', score: 12 });
    expect(root.querySelector('[data-role="gull"]')).not.toBeNull();
    expect(root.querySelector('[data-role="obstacle"]')).not.toBeNull();
    expect(root.querySelector('[data-role="score"]')?.textContent).toBe('12');
    expect(root.textContent).toContain('다시 도전');
  });

  it('[S6] space input jumps while playing and resets from gameover', () => {
    let state: 'ready' | 'playing' | 'gameover' = 'playing';
    const onJump = vi.fn();
    attachSpaceHandler(document, () => state, (next) => { state = next; }, onJump);
    document.dispatchEvent(new KeyboardEvent('keydown', { code: 'Space' }));
    expect(onJump).toHaveBeenCalledOnce();
    state = 'gameover';
    document.dispatchEvent(new KeyboardEvent('keydown', { code: 'Space' }));
    expect(state).toBe('ready');
  });

  it('[S7] speed(t) follows the clamped monotonic difficulty curve', () => {
    expect(speed(0)).toBe(4);
    expect(speed(1800)).toBe(7);
    expect(speed(6000)).toBe(10);
    expect([0, 600, 1200, 6000].map(speed)).toEqual([4, 5, 6, 10]);
  });

  it('[S8] milestone(prev,new) reports 100-point crossings and renders burst', () => {
    expect(milestone(95, 105)).toEqual({ at: 100 });
    expect(milestone(100, 150)).toBeNull();
    expect(milestone(199, 210)).toEqual({ at: 200 });
    const root = document.createElement('main');
    render(root, { state: 'playing', score: 200, milestone: 200 });
    expect(root.querySelector('.burst')?.textContent).toBe('200');
  });
});
