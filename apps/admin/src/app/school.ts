/**
 * Which school this browser tab is for.
 *  - `/s/<slug>/...` on a shared test address,
 *  - `<slug>.<domain>` on a school's own address,
 *  - or the one a build was made for (`VITE_DEFAULT_SCHOOL`).
 */
export interface SchoolRoute {
  slug: string | null;
  /** The part of the path the router should ignore. */
  basepath: string;
}

export function resolveSchool(loc: Pick<Location, 'pathname' | 'hostname'> = window.location, fallback = import.meta.env.VITE_DEFAULT_SCHOOL as string | undefined): SchoolRoute {
  const m = /^\/s\/([a-z][a-z0-9-]{2,30}[a-z0-9])(?=\/|$)/.exec(loc.pathname);
  if (m) return { slug: m[1]!, basepath: `/s/${m[1]}` };
  const host = loc.hostname.split('.');
  if (host.length >= 3 && !/^(www|app|admin)$/.test(host[0]!) && /^[a-z][a-z0-9-]{2,30}[a-z0-9]$/.test(host[0]!)) return { slug: host[0]!, basepath: '' };
  return { slug: fallback ?? null, basepath: '' };
}
