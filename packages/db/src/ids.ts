import { randomBytes } from 'node:crypto';

const ALPHABET = '0123456789abcdefghjkmnpqrstvwxyz';

/** A short, sortable-enough, URL-safe id with a readable prefix, like `stu_7k3m9q2x4d1f`. */
export function newId(prefix: string): string {
  const bytes = randomBytes(10);
  let out = '';
  for (const b of bytes) out += ALPHABET[b % 32];
  return `${prefix}_${out}`;
}
