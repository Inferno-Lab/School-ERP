import { createHmac } from 'node:crypto';
import { describe, expect, it } from 'vitest';
import { JWT_ISSUER, hashPassword, jwtKey, passwordNeedsRehash, randomCode, seal, signJwt, unseal, verifyJwt, verifyPassword } from './index.js';

describe('security', () => {
  it('hashes and verifies passwords, and flags an older cost for a rewrite', async () => {
    const h = await hashPassword('nest2026');
    expect(await verifyPassword('nest2026', h)).toBe(true);
    expect(await verifyPassword('nest2027', h)).toBe(false);
    expect(await verifyPassword('x', null)).toBe(false);
    expect(passwordNeedsRehash(h)).toBe(false);
    expect(passwordNeedsRehash('scrypt$16384$8$1$c2FsdA$aGFzaA')).toBe(true);
  });
  it('seals and unseals, and refuses a wrong key or a tampered value', () => {
    const s = seal('postgres://u:p@h/db', 'k1');
    expect(unseal(s, 'k1')).toBe('postgres://u:p@h/db');
    expect(() => unseal(s, 'k2')).toThrow();
    expect(() => unseal(s.slice(0, -2) + 'AA', 'k1')).toThrow();
  });
  it('signs JWTs that expire, bind to an audience, and cannot be forged', () => {
    const t = signJwt({ sub: 'u1', aud: 'greenfield' }, 's', 60);
    expect(verifyJwt(t, 's')?.sub).toBe('u1');
    expect(verifyJwt(t, 's')?.iss).toBe(JWT_ISSUER);
    expect(verifyJwt(t, 's')?.aud).toBe('greenfield');
    expect(verifyJwt(t, 'other')).toBeNull();
    expect(verifyJwt(signJwt({ sub: 'u1', aud: 'greenfield' }, 's', -5), 's')).toBeNull();
    const school = signJwt({ sub: 'u1', aud: 'greenfield' }, 's', 60);
    expect(verifyJwt(school, 's')?.aud).toBe('greenfield');
    const consoleTok = signJwt({ sub: 'u1', aud: 'console' }, 's', 60);
    expect(createHmac('sha256', jwtKey('s', 'greenfield')).update('x').digest('hex')).not.toBe(
      createHmac('sha256', jwtKey('s', 'console')).update('x').digest('hex'),
    );
    expect(verifyJwt(consoleTok, 's')?.aud).toBe('console');
    const [h, , sig] = t.split('.');
    expect(verifyJwt(`${h}.${Buffer.from(JSON.stringify({ sub: 'admin', aud: 'greenfield', iss: JWT_ISSUER, exp: 99999999999 })).toString('base64url')}.${sig}`, 's')).toBeNull();
    const none = Buffer.from(JSON.stringify({ alg: 'none', typ: 'JWT' })).toString('base64url');
    expect(verifyJwt(`${none}.${t.split('.')[1]}.${sig}`, 's')).toBeNull();
  });
  it('accepts a token signed with the previous secret during rotation', () => {
    const old = signJwt({ sub: 'u1', aud: 'greenfield' }, 'old-secret', 60);
    expect(verifyJwt(old, 'new-secret', 'old-secret')?.sub).toBe('u1');
    expect(verifyJwt(old, 'new-secret')).toBeNull();
  });
  it('refuses a token missing aud', () => {
    expect(() => signJwt({ sub: 'u1' }, 's', 60)).toThrow(/aud/);
  });
  it('makes numeric codes of the right length', () => {
    for (let i = 0; i < 50; i++) expect(randomCode(6)).toMatch(/^\d{6}$/);
  });
});
