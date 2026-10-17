import type { ApiErrorBody, ErrorCode } from '@edunest/contracts';

/** A failed call, with what the server said. `message` is always safe to show a person. */
export class HttpError extends Error {
  readonly status: number;
  readonly code: ErrorCode;
  readonly fields: Record<string, string>;
  readonly attemptsLeft?: number;
  readonly retryAfter?: number;

  constructor(status: number, body: Partial<ApiErrorBody>) {
    super(body.message ?? 'Something went wrong. Try again in a moment.');
    this.status = status;
    this.code = body.code ?? 'internal';
    this.fields = body.fields ?? {};
    this.attemptsLeft = body.attemptsLeft;
    this.retryAfter = body.retryAfter;
  }
}

export interface Tokens {
  accessToken: string;
  refreshToken: string;
}

export interface HttpOptions {
  baseUrl: string;
  /** Headers sent with every call, such as X-School. */
  headers?: () => Record<string, string>;
  tokens: { get: () => Tokens | null; set: (t: Tokens | null) => void };
  /** Where a refresh goes. A 401 triggers one refresh and one retry. */
  refreshPath: string;
  onSignedOut?: () => void;
  fetch?: typeof fetch;
}

export type Query = Record<string, string | number | boolean | undefined | null>;

export interface Http {
  get<T>(path: string, query?: Query): Promise<T>;
  post<T>(path: string, body?: unknown): Promise<T>;
  put<T>(path: string, body?: unknown): Promise<T>;
  patch<T>(path: string, body?: unknown): Promise<T>;
  del<T>(path: string): Promise<T>;
  text(path: string, query?: Query): Promise<string>;
}

export function createHttp(opts: HttpOptions): Http {
  const doFetch = opts.fetch ?? ((...a: Parameters<typeof fetch>) => fetch(...a));
  let refreshing: Promise<boolean> | null = null;

  const url = (path: string, query?: Query) => {
    const q = Object.entries(query ?? {}).filter(([, v]) => v !== undefined && v !== null && v !== '').map(([k, v]) => `${encodeURIComponent(k)}=${encodeURIComponent(String(v))}`).join('&');
    return `${opts.baseUrl.replace(/\/$/, '')}${path}${q ? `?${q}` : ''}`;
  };

  async function refresh(): Promise<boolean> {
    const t = opts.tokens.get();
    if (!t) return false;
    refreshing ??= (async () => {
      try {
        const res = await doFetch(url(opts.refreshPath), { method: 'POST', headers: { 'content-type': 'application/json', ...opts.headers?.() }, body: JSON.stringify({ refreshToken: t.refreshToken }) });
        if (!res.ok) return false;
        const next = (await res.json()) as Tokens;
        opts.tokens.set({ accessToken: next.accessToken, refreshToken: next.refreshToken });
        return true;
      } catch {
        return false;
      } finally {
        setTimeout(() => { refreshing = null; }, 0);
      }
    })();
    return refreshing;
  }

  async function send(method: string, path: string, body: unknown, query: Query | undefined, retry: boolean): Promise<Response> {
    const t = opts.tokens.get();
    let res: Response;
    try {
      res = await doFetch(url(path, query), {
        method,
        headers: { ...(body !== undefined ? { 'content-type': 'application/json' } : {}), ...(t ? { authorization: `Bearer ${t.accessToken}` } : {}), ...opts.headers?.() },
        body: body !== undefined ? JSON.stringify(body) : undefined,
      });
    } catch {
      throw new HttpError(0, { code: 'school_unavailable', message: 'We cannot reach the server. Check your connection and try again.' });
    }
    if (res.status === 401 && retry && t && !path.includes('/auth/')) {
      if (await refresh()) return send(method, path, body, query, false);
      opts.tokens.set(null);
      opts.onSignedOut?.();
    }
    if (!res.ok) {
      const body = (await res.json().catch(() => ({}))) as Partial<ApiErrorBody>;
      throw new HttpError(res.status, body);
    }
    return res;
  }

  const json = async <T>(method: string, path: string, body?: unknown, query?: Query): Promise<T> => {
    const res = await send(method, path, body, query, true);
    if (res.status === 204) return undefined as T;
    return (await res.json()) as T;
  };

  return {
    get: (path, query) => json('GET', path, undefined, query),
    post: (path, body) => json('POST', path, body ?? {}),
    put: (path, body) => json('PUT', path, body ?? {}),
    patch: (path, body) => json('PATCH', path, body ?? {}),
    del: (path) => json('DELETE', path),
    text: async (path, query) => (await send('GET', path, undefined, query, true)).text(),
  };
}
