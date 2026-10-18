import { useEffect } from 'react';

/**
 * Keeps every segmented control's white knob exactly on the chosen tab. Some pages come from the design boards with the
 * knob's size worked out from guessed text widths; this measures the real tab after every change, resize and font load.
 */
export function SegFit() {
  useEffect(() => {
    const fit = () => {
      document.querySelectorAll<HTMLElement>('.seg').forEach((seg) => {
        const kn = seg.querySelector<HTMLElement>(':scope > .kn');
        const on = seg.querySelector<HTMLElement>('button.on, button[aria-selected=true]');
        if (!kn || !on || !on.offsetWidth) return;
        const w = `${on.offsetWidth}px`;
        const t = `translateX(${on.offsetLeft}px)`;
        if (kn.style.width !== w) kn.style.width = w;
        if (kn.style.transform !== t) kn.style.transform = t;
      });
    };
    const mo = new MutationObserver(fit);
    mo.observe(document.body, { subtree: true, childList: true, attributes: true, attributeFilter: ['class', 'aria-selected', 'style'] });
    window.addEventListener('resize', fit);
    void document.fonts?.ready.then(fit);
    fit();
    return () => { mo.disconnect(); window.removeEventListener('resize', fit); };
  }, []);
  return null;
}
