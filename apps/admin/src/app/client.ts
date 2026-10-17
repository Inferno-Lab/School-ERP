import { createHttp, schoolApi, type Tokens } from '@edunest/api-client';
import type { SessionUser } from '@edunest/contracts';

const API = (import.meta.env.VITE_API_URL as string | undefined) ?? '';

const key = (slug: string) => `edunest.admin.${slug}`;

export interface Stored extends Tokens {
  user: SessionUser;
  /** Set for a console support session: it ends at this time and cannot change anything. */
  support?: { until: number };
}

export const session = {
  read(slug: string): Stored | null {
    try { return JSON.parse(localStorage.getItem(key(slug)) ?? 'null') as Stored | null; } catch { return null; }
  },
  write(slug: string, s: Stored | null): void {
    try { if (s) localStorage.setItem(key(slug), JSON.stringify(s)); else localStorage.removeItem(key(slug)); } catch { /* storage can be blocked */ }
  },
};

/** A support session arrives from the console as `#support=<token>`: read-only, short, for one school. */
export function readSupportHash(slug: string): boolean {
  const m = /[#&]support=([^&]+)/.exec(window.location.hash);
  if (!m) return false;
  const payload = JSON.parse(atob(m[1]!.split('.')[1]!.replace(/-/g, '+').replace(/_/g, '/'))) as { name: string; exp: number; perms: string[] };
  session.write(slug, { accessToken: m[1]!, refreshToken: 'support', support: { until: payload.exp * 1000 }, user: { id: 'support', name: payload.name, email: null, phone: null, initials: 'ES', roles: ['support'], roleNames: ['EduNest support'], permissions: payload.perms as SessionUser['permissions'] } });
  history.replaceState(null, '', window.location.pathname + window.location.search);
  return true;
}

export function supportUntil(slug: string): number | null {
  return session.read(slug)?.support?.until ?? null;
}

/** One client per school. A 401 refreshes the tokens once, then signs out. */
export function makeClient(slug: string, onSignedOut: () => void) {
  const http = createHttp({
    baseUrl: API,
    headers: () => ({ 'x-school': slug }),
    tokens: {
      get: () => { const s = session.read(slug); return s ? { accessToken: s.accessToken, refreshToken: s.refreshToken } : null; },
      set: (t) => { const s = session.read(slug); if (!t) session.write(slug, null); else if (s) session.write(slug, { ...s, ...t }); },
    },
    refreshPath: '/v1/auth/refresh',
    onSignedOut,
  });
  return { http, api: schoolApi(http) };
}

export type Client = ReturnType<typeof makeClient>;
