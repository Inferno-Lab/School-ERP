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
  // A school's own address (`<slug>.<base domain>`) only counts when the build says which base domain is ours; any other host
  // (the test site's onrender.com name, localhost) is not a school.
  const base = import.meta.env.VITE_BASE_DOMAIN as string | undefined;
  if (base && loc.hostname.endsWith(`.${base}`)) {
    const first = loc.hostname.slice(0, -(base.length + 1));
    if (!/^(www|app|admin)$/.test(first) && /^[a-z][a-z0-9-]{2,30}[a-z0-9]$/.test(first)) return { slug: first, basepath: '' };
  }
  return { slug: fallback ?? null, basepath: '' };
}
