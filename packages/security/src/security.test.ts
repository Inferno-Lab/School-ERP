import { describe, expect, it } from 'vitest';
import { hashPassword, randomCode, seal, signJwt, unseal, verifyJwt, verifyPassword } from './index.js';

describe('security', () => {
  it('hashes and verifies passwords', async () => {
    const h = await hashPassword('nest2026');
    expect(await verifyPassword('nest2026', h)).toBe(true);
    expect(await verifyPassword('nest2027', h)).toBe(false);
    expect(await verifyPassword('x', null)).toBe(false);
  });
  it('seals and unseals, and refuses a wrong key or a tampered value', () => {
    const s = seal('postgres://u:p@h/db', 'k1');
    expect(unseal(s, 'k1')).toBe('postgres://u:p@h/db');
    expect(() => unseal(s, 'k2')).toThrow();
    expect(() => unseal(s.slice(0, -2) + 'AA', 'k1')).toThrow();
  });
  it('signs JWTs that expire and cannot be forged', () => {
    const t = signJwt({ sub: 'u1' }, 's', 60);
    expect(verifyJwt(t, 's')?.sub).toBe('u1');
    expect(verifyJwt(t, 'other')).toBeNull();
    expect(verifyJwt(signJwt({ sub: 'u1' }, 's', -5), 's')).toBeNull();
    const [h, , sig] = t.split('.');
    expect(verifyJwt(`${h}.${Buffer.from('{"sub":"admin","exp":99999999999}').toString('base64url')}.${sig}`, 's')).toBeNull();
  });
  it('makes numeric codes of the right length', () => {
    for (let i = 0; i < 50; i++) expect(randomCode(6)).toMatch(/^\d{6}$/);
  });
});
