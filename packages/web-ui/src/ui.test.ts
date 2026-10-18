import { describe, expect, it } from 'vitest';
import { rollDigits } from './digits';
import { TINTS, tintFor } from './tints';

describe('rollDigits', () => {
  it('rolls digits and leaves separators still', () => {
    const d = rollDigits('1,498');
    expect(d.map((x) => x.c).join('')).toBe('1,498');
    expect(d.filter((x) => x.isD)).toHaveLength(4);
    expect(d[1]).toMatchObject({ isD: false, notD: true, y: 0 });
    expect(d[0]!.y).toBeCloseTo(1.1);
    expect(d[4]!.y).toBeCloseTo(8.8);
  });
});

describe('tintFor', () => {
  it('gives the same person the same colours every time', () => {
    expect(tintFor('Aarav Sharma')).toEqual(tintFor('Aarav Sharma'));
  });
  it('always picks one of the approved pairs', () => {
    for (const name of ['', 'Neha Menon', 'Kavita Iyer', '🙂', 'x'.repeat(500)]) {
      const t = tintFor(name);
      expect(TINTS.some(([bg, fg]) => bg === t.bg && fg === t.fg)).toBe(true);
    }
  });
});
