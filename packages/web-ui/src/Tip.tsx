import { useEffect, useRef, useState } from 'react';
import { createPortal } from 'react-dom';

/** The words for an element: its own data-tip, or for a usage bar (a label, a number and a bar) what that row says. */
function tipText(el: HTMLElement): string | null {
  if (el.dataset.tip) return el.dataset.tip;
  if (!el.matches('.us')) return null;
  const r = el.querySelector('.r');
  const label = r?.firstChild?.textContent?.trim();
  const value = r?.querySelector('b')?.textContent?.trim();
  if (label && value) return `${label}\n${value}`;
  return el.textContent?.trim().replace(/\s+/g, ' ') || null;
}

interface Shown { text: string; x: number; y: number; below: boolean; side: boolean; root: HTMLElement }

/**
 * One tooltip for the whole page. Anything with `data-tip="First line\nmore"` shows it on hover or keyboard focus,
 * above the element (or `data-tip-side="right"` beside it). Charts, bars and the collapsed menu use it, so a number
 * never has to be read off an axis.
 */
export function Tooltips() {
  const [shown, setShown] = useState<Shown | null>(null);
  const cur = useRef<HTMLElement | null>(null);
  const [fit, setFit] = useState<{ dx: number } | null>(null);
  const tip = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const show = (el: HTMLElement) => {
      const text = tipText(el);
      const root = el.closest<HTMLElement>('.nest');
      if (!text || !root) return;
      cur.current = el;
      const r = el.getBoundingClientRect();
      setFit(null);
      if (el.dataset.tipSide === 'right') setShown({ text, x: r.right + 10, y: r.top + r.height / 2, below: false, side: true, root });
      else setShown({ text, x: r.left + r.width / 2, y: r.top < 80 ? r.bottom : r.top, below: r.top < 80, side: false, root });
    };
    const hide = () => { cur.current = null; setShown(null); setFit(null); };
    const over = (e: PointerEvent) => {
      if (e.pointerType === 'touch') return;
      const el = (e.target as Element).closest?.<HTMLElement>('[data-tip], .us') ?? null;
      if (el === cur.current) return;
      if (el) show(el); else hide();
    };
    const focus = (e: FocusEvent) => { const el = (e.target as Element).closest?.<HTMLElement>('[data-tip], .us'); if (el) show(el); };
    const key = (e: KeyboardEvent) => { if (e.key === 'Escape') hide(); };
    document.addEventListener('pointerover', over);
    document.addEventListener('focusin', focus);
    document.addEventListener('focusout', hide);
    document.addEventListener('keydown', key);
    window.addEventListener('scroll', hide, true);
    return () => {
      document.removeEventListener('pointerover', over);
      document.removeEventListener('focusin', focus);
      document.removeEventListener('focusout', hide);
      document.removeEventListener('keydown', key);
      window.removeEventListener('scroll', hide, true);
    };
  }, []);

  // Keep the bubble inside the window: nudge it sideways when it would run off an edge.
  useEffect(() => {
    if (!shown || !tip.current) return;
    const r = tip.current.getBoundingClientRect();
    const dx = r.left < 8 ? 8 - r.left : r.right > window.innerWidth - 8 ? window.innerWidth - 8 - r.right : 0;
    if (dx) setFit({ dx });
  }, [shown]);

  if (!shown) return null;
  const [head, ...rest] = shown.text.split('\n');
  return createPortal(
    <div ref={tip} className={`tipx ${shown.side ? 'rt' : shown.below ? 'bl' : ''}`} role="tooltip" style={{ left: shown.x + (fit?.dx ?? 0), top: shown.y }}>
      <b>{head}</b>
      {rest.length > 0 && <span>{rest.join('\n')}</span>}
    </div>,
    shown.root,
  );
}
