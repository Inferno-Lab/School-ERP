import { useQuery } from '@tanstack/react-query';
import { EmptyCard } from '@edunest/web-ui';
import { Card, Page } from '../../app/Page';
import { useApp } from '../../app/context';
import { url } from '../../app/base';
import { statusOf } from '../../app/format';

const TARGET: Record<string, string> = { local: 'This computer', 'free-test': 'Free test track', 'aws-cell': 'AWS cell' };

export function CellsPage() {
  const app = useApp();
  const cells = useQuery({ queryKey: ['cells'], queryFn: app.api.cells });
  const schools = useQuery({ queryKey: ['schools'], queryFn: () => app.api.schools() });
  const list = cells.data ?? [];
  return (
    <Page active="cells" title="Cells" sub="Where schools run. Each cell is one database server and one API, and every school gets its own database inside it." loading={cells.isLoading} error={cells.isError ? { message: (cells.error as Error).message, retry: () => void cells.refetch() } : null}>
      {list.length === 0 ? (
        <div style={{ maxWidth: 560 }}>
          <EmptyCard title="Cells" chip={{ text: '0 cells', tone: 'v' }} scene="map-pin" heading="No cells yet" body="The first cell is created when the platform starts. Schools are placed in a cell when they are onboarded." />
        </div>
      ) : (
        <section className="grid">
          {list.map((c) => {
            const here = (schools.data ?? []).filter((s) => s.cell === c.key);
            const full = c.maxSchools ? Math.round((c.schools / c.maxSchools) * 100) : 0;
            return (
              <Card key={c.key} title={`Cell ${c.key}`} chip={<span className="chip v">{TARGET[c.target] ?? c.target}</span>} span="s6">
                <div className="us">
                  <div className="r">Schools<b>{c.schools} of {c.maxSchools}</b></div>
                  <div className={`bar ${full > 80 ? 'warn' : ''}`}><i style={{ width: `${full}%` }}></i></div>
                </div>
                <div className="kv" style={{ marginTop: 14 }}>Region<b>{c.region}</b></div>
                <div className="lbl" style={{ margin: '12px 0 4px' }}>Schools here</div>
                {here.length === 0 && <div className="help">No schools in this cell yet.</div>}
                {here.map((s) => {
                  const st = statusOf(s);
                  return (
                    <a key={s.id} className="kv" href={url(`/schools/${s.id}`)} onClick={(e) => { e.preventDefault(); app.go(`/schools/${s.id}`); }} style={{ color: 'inherit', textDecoration: 'none' }}>
                      {s.name}<b><span className={`st ${st.tone}`}><i></i>{st.text}</span></b>
                    </a>
                  );
                })}
              </Card>
            );
          })}
        </section>
      )}
    </Page>
  );
}
