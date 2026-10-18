import { useEffect, useId, useRef, type ReactNode } from 'react';

export interface DialogProps {
  title: string;
  /** A small label above the title, like "Cannot be undone". */
  tag?: { text: string; tone: 'v' | 'c' | 'a' | 'g' | 'r' | 'b' };
  dark?: boolean;
  onClose: () => void;
  /** Applied to the card, for the vibrate on a wrong answer. */
  shake?: string;
  width?: number;
  children: ReactNode;
}

/** A card over a blurred page. Escape and the backdrop close it, and focus stays inside until it does. */
export function Dialog({ title, tag, dark, onClose, shake, width, children }: DialogProps) {
  const id = useId();
  const ref = useRef<HTMLDivElement>(null);
  useEffect(() => {
    const prev = document.activeElement as HTMLElement | null;
    const first = ref.current?.querySelector<HTMLElement>('input,select,textarea,button:not(.xb)');
    first?.focus();
    const key = (e: KeyboardEvent) => {
      if (e.key === 'Escape') onClose();
      if (e.key !== 'Tab' || !ref.current) return;
      const items = [...ref.current.querySelectorAll<HTMLElement>('input,select,textarea,button,a[href]')].filter((x) => !x.hasAttribute('disabled'));
      if (!items.length) return;
      const a = items[0]!, z = items[items.length - 1]!;
      if (e.shiftKey && document.activeElement === a) { e.preventDefault(); z.focus(); }
      else if (!e.shiftKey && document.activeElement === z) { e.preventDefault(); a.focus(); }
    };
    document.addEventListener('keydown', key);
    return () => { document.removeEventListener('keydown', key); prev?.focus(); };
  }, [onClose]);
  return (
    <>
      <div className="scrim" onClick={onClose}></div>
      <div className="mod">
        <div ref={ref} className={`dlg ${dark ? 'dk' : ''} ${shake ?? ''}`} role="dialog" aria-modal="true" aria-labelledby={id} style={width ? { width, maxHeight: 'calc(100dvh - 32px)', overflow: 'auto' } : { maxHeight: 'calc(100dvh - 32px)', overflow: 'auto' }}>
          {tag && <span className={`chip ${tag.tone}`}>{tag.text}</span>}
          <h3 id={id}>{title}</h3>
          {children}
        </div>
      </div>
    </>
  );
}
