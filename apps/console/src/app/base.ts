/** The console may be served from a folder (`/console/` on the combined test server) or from the root. Links carry the folder; the router does not. */
export const BASE = import.meta.env.BASE_URL.replace(/\/$/, '');
export const url = (p: string) => `${BASE}${p}`;
export const path = (href: string) => (BASE && href.startsWith(BASE) ? href.slice(BASE.length) || '/' : href);
