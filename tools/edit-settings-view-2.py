"""Second pass over the settings view (after edit-settings-view.py): errors, locks, contrast chip, fee-waiver select."""
p = 'apps/admin/src/pages/settings/settings.view.tsx'
s = open(p, encoding='utf-8').read()


def rep(a, b, count=1):
    global s
    assert s.count(a) == count, (a[:80], s.count(a))
    s = s.replace(a, b)


rep('<main className="mn">', '<main className={`mn ${v.shk}`}>')
rep('        <div className="cols">', """        {v.err._ && (
          <div className="emsg" role="alert" style={{ marginBottom: "16px" } as CSSProperties}>
            {v.err._}
          </div>
        )}
        <div className="cols">""")
rep('<input value={v.name} onChange={v.onName} aria-label="School name"', '<input value={v.name} onChange={v.onName} readOnly={v.roName} aria-label="School name"')
rep('<input value={v.logoText} onChange={v.onLogo} maxLength={2}', '<input value={v.logoText} onChange={v.onLogo} readOnly={v.roLogo} maxLength={2}')
rep('''<span className="chip g">
                          <svg viewBox="0 0 24 24" aria-hidden="true">
                            <path className="i" d="M5 12.5l4.5 4.5L19 7.5" style={{ strokeWidth: "2.6" } as CSSProperties}></path>
                          </svg>
                          Passes AA · {v.ratio}:1''', '''<span className={`chip ${v.aa ? "g" : "r"}`}>
                          <svg viewBox="0 0 24 24" aria-hidden="true">
                            <path className="i" d={v.aa ? "M5 12.5l4.5 4.5L19 7.5" : "M6 6l12 12M18 6L6 18"} style={{ strokeWidth: "2.6" } as CSSProperties}></path>
                          </svg>
                          {v.aa ? "Passes AA" : "Too light for white text"} · {v.ratio}:1''')
rep('aria-label={w.n}\n                              style', 'aria-label={w.n}\n                              disabled={w.locked}\n                              style')
rep('maxLength={240}></textarea>', 'maxLength={v.aboutMax} readOnly={v.roAbout}></textarea>')
rep('{v.aboutLen} / 240', '{v.aboutLen} / {v.aboutMax}')
rep('<b>Who approves notices</b>\n                    <small>Notices to whole classes wait for this approval before they send.</small>', '<b>Who approves fee waivers</b>\n                    <small>Waiving or reducing a fee needs this person to say yes.</small>')
rep('aria-label={t.n} onClick={t.flip}', 'aria-label={t.n} disabled={t.locked} onClick={t.flip}')
open(p, 'w', encoding='utf-8').write(s)
