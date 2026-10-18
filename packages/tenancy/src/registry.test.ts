import { describe, expect, it } from 'vitest';
import { Registry } from './index';

describe('Registry', () => {
  it('is created without connecting, and can be closed again', async () => {
    const r = new Registry({ url: 'postgres://u:p@127.0.0.1:1/none', secret: 'x'.repeat(32) });
    r.invalidate('anything');
    r.invalidate();
    await r.close();
    expect(r.pool.ended).toBe(true);
  });
});
