import type { ReactNode } from 'react';
import { Tooltips } from '../Tip';

export interface ShellProps {
  /** The page's own class, so its CSS stays inside it. */
  page: string;
  /** "dark" or "". */
  theme?: string;
  aside: ReactNode;
  /** Extra classes on the floating frame, such as the shake. */
  frClass?: string;
  /** Things that float over the frame: toasts, glows, dialogs. */
  overlays?: ReactNode;
  children: ReactNode;
}

/** The floating frame, the menu and the page. The sizes fill the window instead of the canvas board. */
export function Shell({ page, theme, aside, frClass, overlays, children }: ShellProps) {
  return (
    <div className={`pg-${page} nest ${theme ?? ''}`} style={{ width: '100%', minHeight: '100dvh', padding: 12 }}>
      <div className={`fr ${frClass ?? ''}`} style={{ minHeight: 'calc(100dvh - 24px)' }}>
        <div className="app" style={{ minHeight: 'calc(100dvh - 24px)' }}>
          {aside}
          {children}
        </div>
        {overlays}
      </div>
      <Tooltips />
    </div>
  );
}
