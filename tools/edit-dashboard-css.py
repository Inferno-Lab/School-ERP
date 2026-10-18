"""One-time edit of the dashboard CSS: the slim columns, the segmented roll bars and the filled fee bars replace the
pencils, the dot rows and the jars. Everything else stays exactly as designed."""
import re

p = 'apps/admin/src/pages/dashboard/dashboard.css'
s = open(p, encoding='utf-8').read()
drop = re.compile(r'^\.pg-dashboard (\.pen\b|\.dots\b|\.rr:hover \.dots|\.jars\b|\.jar\b|\.wv1|\.wv2|\.coin)|^@keyframes (jw|jd)\b')
lines = [l for l in s.split('\n') if not drop.match(l)]
s = '\n'.join(lines)
s = s.replace('.pg-dashboard .pen:hover .bub,.pg-dashboard .pen.today .bub', '.pg-dashboard .col2:hover .bub,.pg-dashboard .col2:focus-visible .bub,.pg-dashboard .col2.today .bub')
s += '''
/* Slim columns: the day's value in a thin column, the same day a week earlier as a pale one behind it. */
.pg-dashboard .col2{position:relative;flex:1 1 0;max-width:46px;min-width:8px;height:236px;display:flex;align-items:flex-end;justify-content:center;cursor:pointer;outline:0}
.pg-dashboard .col2 .fl{position:absolute;bottom:0;width:46%;max-width:16px;border-radius:8px 8px 3px 3px;background:var(--pc);transition:height 1.2s var(--e),filter .3s,width .3s var(--e)}
.pg-dashboard .col2 .gh{position:absolute;bottom:0;width:78%;max-width:30px;border-radius:10px 10px 4px 4px;background:var(--vS);transition:height 1.2s var(--e)}
.pg-dashboard .col2:hover .fl,.pg-dashboard .col2:focus-visible .fl{filter:brightness(1.06);width:56%}
.pg-dashboard .col2.today .fl{background:var(--a)}
.pg-dashboard .pcols{justify-content:space-around;gap:2px}
/* Class rolls as one segmented bar per class. */
.pg-dashboard .sg{display:flex;gap:2px;height:12px;border-radius:6px;overflow:hidden;background:var(--sunk)}
.pg-dashboard .sg i{display:block;min-width:0;transition:flex .9s var(--e);border-radius:2px}
.pg-dashboard .sg i.p{background:var(--v)}
.pg-dashboard .sg i.l{background:var(--a)}
.pg-dashboard .sg i.a{background:var(--c)}
.pg-dashboard .sg i.u{background:transparent}
.pg-dashboard .rr:hover .sg{height:16px}
.pg-dashboard .sg{transition:height .25s var(--e)}
/* Fees by type as four filled bars. */
.pg-dashboard .fbars{display:grid;grid-template-columns:repeat(4,minmax(0,1fr));gap:12px;margin-top:6px}
.pg-dashboard .fbar{display:flex;flex-direction:column;align-items:center;gap:6px;text-align:center}
.pg-dashboard .fbar .trk{position:relative;width:100%;max-width:96px;height:164px;border-radius:24px;background:var(--sunk);overflow:hidden}
.pg-dashboard .fbar .fill{position:absolute;left:0;right:0;bottom:0;border-radius:18px 18px 24px 24px;transition:height 1.4s var(--e);display:block;min-height:6px}
.pg-dashboard .fbar .fill em,.pg-dashboard .fbar .out{position:absolute;left:0;right:0;top:10px;text-align:center;font:800 13px var(--fb);font-style:normal;color:#fff}
.pg-dashboard .fbar .out{top:auto;color:var(--ink2)}
.pg-dashboard .fbar:hover .trk{box-shadow:0 0 0 2px var(--v2)}
.pg-dashboard .fbar b{font:700 14px var(--fb)}
.pg-dashboard .fbar span{font:600 12px var(--fb);color:var(--ink3)}
@media (max-width:640px){.pg-dashboard .fbars{gap:8px}.pg-dashboard .fbar .trk{height:132px}}
'''
open(p, 'w', encoding='utf-8').write(s)
