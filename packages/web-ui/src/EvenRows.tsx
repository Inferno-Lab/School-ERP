import { useEffect } from 'react';

const FLOOR = 96;

interface Col { h: number; area: number | null; content?: number }

/**
 * The new total height for each column's lists, or -1 to leave them alone. Columns without lists keep their size and set
 * the line; a column with lists gives up list height (the lists then scroll inside) or, when its lists hide rows, shows
 * more of them, to reach it. When every column has lists, all of them come to the shortest column. A list never grows
 * past its own rows, so nothing is stretched to fill.
 */
export function evenTarget(cols: Col[], minArea = FLOOR, room = 0): number[] {
  const rigid = cols.filter((c) => c.area == null).map((c) => c.h);
  // With room left under the row (it is the last thing on a short page), every column may grow into it as far as the
  // column that runs out of rows first allows.
  const reach = Math.min(...cols.map((c) => c.h + Math.max(0, (c.content ?? c.area ?? 0) - (c.area ?? 0))));
  const hs = cols.map((c) => c.h);
  // The room is measured under the row's tallest column, so the row may reach that column's bottom plus the room.
  const target = rigid.length ? Math.max(...rigid) : room > 0 ? Math.min(Math.max(...hs) + room, reach) : Math.min(...hs);
  return cols.map((c) => {
    if (c.area == null || Math.abs(c.h - target) < 1) return -1;
    const want = c.area - (c.h - target);
    const next = Math.min(Math.max(minArea, want), Math.max(c.area, c.content ?? c.area));
    return Math.abs(next - c.area) < 1 ? -1 : next;
  });
}

/** Changes the lists' heights by `delta` (negative takes, positive gives): takes from the tallest first and never below the
 * floor, gives to the lists with the most hidden rows first and never past their rows. */
export function share(heights: number[], delta: number, contents: number[] = heights, floor = FLOOR): number[] {
  const out = [...heights];
  const order = heights.map((_, j) => j);
  if (delta < 0) {
    let cut = -delta;
    for (const i of order.sort((a, b) => heights[b]! - heights[a]!)) { const t = Math.max(0, Math.min(cut, out[i]! - floor)); out[i]! -= t; cut -= t; }
  } else {
    let add = delta;
    for (const i of order.sort((a, b) => (contents[b]! - heights[b]!) - (contents[a]! - heights[a]!))) { const g = Math.max(0, Math.min(add, contents[i]! - out[i]!)); out[i]! += g; add -= g; }
  }
  return out;
}

/**
 * Makes columns that sit side by side end on the same line without stretching anything. A row marked `data-even` has
 * columns; the lists inside a column that may scroll are marked `data-even-scroll`. Stacked columns (a narrow window) are
 * left alone.
 */
export function EvenRows() {
  useEffect(() => {
    let frame = 0;
    const even = () => {
      frame = 0;
      for (const row of document.querySelectorAll<HTMLElement>('[data-even]')) {
        const kids = [...row.children].filter((k): k is HTMLElement => k instanceof HTMLElement && k.offsetHeight > 0);
        for (const k of kids) if (!watched.has(k)) { watched.add(k); ro.observe(k); }
        const areas = kids.map((k) => (k.matches('[data-even-scroll]') ? [k] : [...k.querySelectorAll<HTMLElement>('[data-even-scroll]')]));
        // Put every list back to its own cap before measuring.
        for (const a of areas.flat()) { a.dataset.evenCap ??= a.style.maxHeight; a.style.maxHeight = a.dataset.evenCap; }
        // Offset sizes ignore transforms, so a card still sliding in on its entry animation is measured where it will rest.
        const tops = new Set(kids.map((k) => Math.round(k.offsetTop / 8)));
        if (kids.length < 2 || tops.size > 1) continue;
        const sum = (xs: number[]) => xs.reduce((n, x) => n + x, 0);
        const cols = kids.map((k, i) => ({ h: k.offsetHeight, area: areas[i]!.length ? sum(areas[i]!.map((a) => a.offsetHeight)) : null, content: sum(areas[i]!.map((a) => a.scrollHeight)) }));
        const room = row.dataset.even === 'fill' ? roomUnder(row) : 0;
        evenTarget(cols, FLOOR, room).forEach((total, i) => {
          if (total < 0) return;
          const list = areas[i]!;
          share(list.map((a) => a.offsetHeight), total - cols[i]!.area!, list.map((a) => a.scrollHeight)).forEach((h, j) => {
            list[j]!.style.maxHeight = `${Math.floor(h)}px`;
            list[j]!.style.overflowY = 'auto';
          });
        });
      }
    };
    // How far the page's last block is from the bottom of the frame, when the page is shorter than the window.
    const roomUnder = (el: HTMLElement) => {
      const main = el.closest<HTMLElement>('.mn');
      const last = main?.lastElementChild;
      if (!main || !last) return 0;
      return main.getBoundingClientRect().bottom - parseFloat(getComputedStyle(main).paddingBottom) - last.getBoundingClientRect().bottom;
    };
    const fill = () => {
      for (const a of document.querySelectorAll<HTMLElement>('[data-fill]')) {
        a.dataset.evenCap ??= a.style.maxHeight;
        a.style.maxHeight = a.dataset.evenCap;
        const room = roomUnder(a);
        if (room > 1 && a.scrollHeight > a.offsetHeight) { a.style.maxHeight = `${Math.floor(Math.min(a.scrollHeight, a.offsetHeight + room))}px`; a.style.overflowY = 'auto'; }
      }
    };
    const soon = () => { if (!frame) frame = requestAnimationFrame(() => { even(); fill(); }); };
    // Columns change size when their data arrives or their text changes; watching the columns themselves catches both.
    const watched = new WeakSet<Element>();
    const ro = new ResizeObserver(soon);
    const mo = new MutationObserver(soon);
    mo.observe(document.body, { subtree: true, childList: true, characterData: true });
    window.addEventListener('resize', soon);
    document.addEventListener('animationend', soon, true);
    void document.fonts?.ready.then(soon);
    soon();
    return () => { mo.disconnect(); ro.disconnect(); window.removeEventListener('resize', soon); document.removeEventListener('animationend', soon, true); cancelAnimationFrame(frame); };
  }, []);
  return null;
}
