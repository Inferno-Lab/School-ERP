import { describe, expect, it } from 'vitest';
import { colourEdges } from './greenfield.js';

describe('colourEdges', () => {
  it('never gives two edges at one node the same colour', () => {
    const edges: [string, string][] = [];
    for (let c = 0; c < 20; c++) for (let t = 0; t < 6; t++) for (let i = 0; i < 4; i++) edges.push([`c${c}`, `t${(c + t) % 12}`]);
    const colours = colourEdges(edges, 40);
    const seen = new Set<string>();
    edges.forEach(([u, v], i) => {
      for (const key of [`L${u}|${colours[i]}`, `R${v}|${colours[i]}`]) { expect(seen.has(key)).toBe(false); seen.add(key); }
    });
  });
});
