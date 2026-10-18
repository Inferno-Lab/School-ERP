import { describe, expect, it } from 'vitest';
import { colourEdges } from './greenfield.js';

function check(edges: [string, string][], k: number) {
  const colours = colourEdges(edges, k);
  const seen = new Set<string>();
  edges.forEach(([u, v], i) => {
    expect(colours[i]).toBeGreaterThanOrEqual(0);
    expect(colours[i]).toBeLessThan(k);
    for (const key of [`L${u}|${colours[i]}`, `R${v}|${colours[i]}`]) { expect(seen.has(key)).toBe(false); seen.add(key); }
  });
}

describe('colourEdges', () => {
  it('colours a regular graph that uses every colour at every node', () => {
    const edges: [string, string][] = [];
    for (let c = 0; c < 12; c++) for (let j = 0; j < 8; j++) for (let i = 0; i < 5; i++) edges.push([`c${c}`, `t${(c + j) % 12}`]);
    check(edges, 40);
  });
  it('colours an uneven graph', () => {
    const edges: [string, string][] = [];
    for (let c = 0; c < 20; c++) for (let j = 0; j < 6; j++) for (let i = 0; i < 3; i++) edges.push([`c${c}`, `t${(c * 3 + j) % 17}`]);
    check(edges, 40);
  });
  it('refuses a node with more edges than colours', () => {
    expect(() => colourEdges(Array.from({ length: 5 }, () => ['a', 'b'] as [string, string]), 4)).toThrow();
  });
});
