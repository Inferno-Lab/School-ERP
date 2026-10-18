// Finds things that run past the window, or past a parent that clips them, so they cannot be reached or read.
export const auditPage = (page) => page.evaluate(() => {
    const out = [];
    const scrolls = (el) => { for (let p = el.parentElement; p; p = p.parentElement) { const o = getComputedStyle(p).overflowX; if (o === 'auto' || o === 'scroll') return true; } return false; };
    const name = (el) => `${el.tagName.toLowerCase()}${el.className && typeof el.className === 'string' ? '.' + el.className.trim().split(/\s+/).slice(0, 2).join('.') : ''}`;
    const hidden = (el) => { for (let p = el; p && p !== document.body; p = p.parentElement) { if (p.getAttribute('aria-hidden') === 'true' || p.classList.contains('orb') || getComputedStyle(p).opacity === '0') return true; } return false; };
    for (const el of document.querySelectorAll('body *')) {
      if (hidden(el)) continue;
      const cs = getComputedStyle(el);
      if (cs.display === 'none' || cs.visibility === 'hidden' || el.closest('svg') && el.tagName !== 'svg') continue;
      const r = el.getBoundingClientRect();
      if (!r.width || !r.height) continue;
      if (scrolls(el)) continue;
      const clipper = (() => { for (let q = el.parentElement; q && q !== document.body; q = q.parentElement) { const o = getComputedStyle(q).overflowX; if (o === 'hidden' || o === 'clip') { const qr = q.getBoundingClientRect(); if (qr.left >= -1 && qr.right <= innerWidth + 1) return q; } } return null; })();
      if (clipper) { if (getComputedStyle(clipper).textOverflow !== 'ellipsis' && getComputedStyle(el.parentElement).textOverflow !== 'ellipsis') { const pr = clipper.getBoundingClientRect(); if ((r.right > pr.right + 1 || r.left < pr.left - 1) && (el.textContent || '').trim() && el.children.length === 0) out.push(`clipped by ${name(clipper)}: ${name(el)} "${(el.textContent || '').trim().slice(0, 30)}"`); } continue; }
      if (r.right > innerWidth + 1 || r.left < -1) { out.push(`outside window: ${name(el)} ${Math.round(r.left)}..${Math.round(r.right)} "${(el.textContent || '').trim().slice(0, 30)}"`); continue; }
    }
    return out.slice(0, 12);
  });
