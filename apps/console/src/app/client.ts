import { consoleApi, createHttp, type Tokens } from '@edunest/api-client';
import type { ConsoleTokens } from '@edunest/contracts';

const API = (import.meta.env.VITE_API_URL as string | undefined) ?? '';
const KEY = 'edunest.console';

export interface Stored extends Tokens {
  user: ConsoleTokens['user'];
}

export const session = {
  read(): Stored | null {
    try { return JSON.parse(localStorage.getItem(KEY) ?? 'null') as Stored | null; } catch { return null; }
  },
  write(s: Stored | null): void {
    try { if (s) localStorage.setItem(KEY, JSON.stringify(s)); else localStorage.removeItem(KEY); } catch { /* storage can be blocked */ }
  },
};

/** The school admin's address for a school, used when a support session opens it. */
export const ADMIN_URL = (import.meta.env.VITE_ADMIN_URL as string | undefined) ?? '';

/** One client for the console. A 401 refreshes the tokens once, then signs out. */
export function makeClient(onSignedOut: () => void) {
  const http = createHttp({
    baseUrl: API,
    tokens: {
      get: () => { const s = session.read(); return s ? { accessToken: s.accessToken, refreshToken: s.refreshToken } : null; },
      set: (t) => { const s = session.read(); if (!t) session.write(null); else if (s) session.write({ ...s, ...t }); },
    },
    refreshPath: '/console/v1/auth/refresh',
    onSignedOut,
  });
  return { http, api: consoleApi(http) };
}

export type Client = ReturnType<typeof makeClient>;
