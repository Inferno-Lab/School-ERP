import { useSyncExternalStore } from 'react';

/** True while the window matches a media query, and updates when it stops or starts matching (a phone turned sideways, a window resized). */
export function useMedia(query: string): boolean {
  return useSyncExternalStore(
    (cb) => { const m = window.matchMedia(query); m.addEventListener('change', cb); return () => m.removeEventListener('change', cb); },
    () => window.matchMedia(query).matches,
    () => false,
  );
}

export const useIsPhone = () => useMedia('(max-width: 900px)');
