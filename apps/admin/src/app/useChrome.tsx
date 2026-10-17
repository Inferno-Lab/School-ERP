import { useEffect, useMemo, useRef, useState, type ReactNode } from 'react';
import { useQuery } from '@tanstack/react-query';
import { Palette, SchoolHeader, Sidebar, tintFor, useTheme, type PaletteHit } from '@edunest/web-ui';
import { adminNav, shortcutTargets } from './nav';
import { useApp } from './context';

const COLLAPSE_KEY = 'edunest.admin.menu.collapsed';

/** What every page shares: the theme, the menu, the shortcuts and the search box. Merge it into the page's values. */
export function useChrome(active: string) {
  const { api, base, user, go } = useApp();
  const theme = useTheme();
  const shell = useQuery({ queryKey: ['shell'], queryFn: api.shell, staleTime: 30_000 });
  const [collapsed, setCollapsed] = useState(() => { try { return localStorage.getItem(COLLAPSE_KEY) === '1'; } catch { return false; } });
  const [open, setOpen] = useState(false);
  const [q, setQ] = useState('');
  const [dq, setDq] = useState('');
  useEffect(() => { const t = setTimeout(() => setDq(q), 140); return () => clearTimeout(t); }, [q]);
  const hits = useQuery({ queryKey: ['search', dq], queryFn: () => api.search(dq), enabled: open, placeholderData: (p) => p });

  const data = shell.data;
  const groups = useMemo(() => adminNav(data?.modules ?? ['people', 'timetable'], base, data?.badges), [data, base]);
  const targets = useMemo(() => shortcutTargets(groups), [groups]);
  const goRef = useRef(go);
  goRef.current = go;

  useEffect(() => {
    let armed = 0;
    const onKey = (e: KeyboardEvent) => {
      const el = e.target as HTMLElement | null;
      const typing = !!el && (el.tagName === 'INPUT' || el.tagName === 'TEXTAREA' || el.isContentEditable);
      if ((e.ctrlKey || e.metaKey) && e.key.toLowerCase() === 'k') { e.preventDefault(); setOpen((o) => !o); return; }
      if (e.key === 'Escape') { setOpen(false); return; }
      if (typing || e.ctrlKey || e.metaKey || e.altKey) return;
      if (e.key === '/') { e.preventDefault(); setOpen(true); return; }
      if (Date.now() - armed < 1200) {
        const to = targets.get(e.key.toLowerCase());
        armed = 0;
        if (to) { e.preventDefault(); goRef.current(to.startsWith(base) && base ? to.slice(base.length) || '/' : to); }
      } else if (e.key.toLowerCase() === 'g') armed = Date.now();
    };
    window.addEventListener('keydown', onKey);
    return () => window.removeEventListener('keydown', onKey);
  }, [targets, base]);

  const close = () => { setOpen(false); setQ(''); };
  const pick = (h: PaletteHit) => {
    close();
    if (h.href.startsWith('action:')) { window.dispatchEvent(new CustomEvent('edunest:action', { detail: h.href.slice(7) })); return; }
    goRef.current(h.href);
  };

  const t = tintFor(user.name);
  const aside: ReactNode = (
    <Sidebar
      label="Main menu" collapsed={collapsed} groups={groups} active={active}
      onNavigate={(href) => goRef.current(base && href.startsWith(base) ? href.slice(base.length) || '/' : href)}
      header={<SchoolHeader logo={data?.school.logoText ?? ''} name={data?.school.shortName ?? ''} place={data?.school.place ?? ''} collapsed={collapsed} onToggle={() => setCollapsed((c) => { try { localStorage.setItem(COLLAPSE_KEY, c ? '0' : '1'); } catch { /* ignore */ } return !c; })} />}
      promo={data && (
        <div className="sbc">
          <div style={{ display: 'flex', alignItems: 'center', gap: 8, font: '700 12px var(--fb)', color: '#CFC9E6' }}><span className="chip a">{data.term.name}</span>{data.term.examsLabel}</div>
          <div className="fd" style={{ fontSize: 22, letterSpacing: '-.03em' }}>{data.term.daysToGo === 0 ? 'Exams start today' : `${data.term.daysToGo} ${data.term.daysToGo === 1 ? 'day' : 'days'} to go`}</div>
          <div style={{ height: 6, borderRadius: 3, background: 'rgba(255,255,255,.14)' }}><div style={{ width: `${data.term.progress}%`, height: '100%', borderRadius: 3, background: 'var(--a)', transition: 'width 1.2s var(--e)' }} /></div>
          <button className="btn wht sm" style={{ alignSelf: 'flex-start' }} onClick={() => goRef.current('/p/exams')}>Plan the rooms<svg viewBox="0 0 24 24" aria-hidden="true"><path className="i" d="M5 12h14M13 6l6 6-6 6"></path></svg></button>
        </div>
      )}
      me={{ initials: user.initials, name: user.name, role: user.roleNames[0] ?? 'Staff', bg: t.bg, fg: t.fg }}
    />
  );

  const palette: ReactNode = open && (
    <>
      <div className="scrim" onClick={close}></div>
      <div className="mod" style={{ top: '18%', transform: 'translate(-50%, 0)', width: 'min(560px, calc(100% - 32px))' }}>
        <Palette hits={hits.data ?? []} query={q} onQuery={setQ} onPick={pick} onClose={close} empty={`No matches for “${q}”. Try a name like Aarav or a class like 8 A.`} />
      </div>
    </>
  );

  return { themeCls: theme.cls, rmCls: '', aside, palette, openSearch: () => setOpen(true), shell: data };
}
