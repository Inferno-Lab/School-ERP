import { useState } from 'react';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { EmptyCard, Field, useShake } from '@edunest/web-ui';
import { Card, Page, useToast } from '../../app/Page';
import { useApp } from '../../app/context';
import { ago } from '../../app/format';

export function FlagsPage() {
  const app = useApp();
  const qc = useQueryClient();
  const { toast, say } = useToast();
  const [key, setKey] = useState('');
  const [label, setLabel] = useState('');
  const [err, setErr] = useState('');
  const shake = useShake();
  const flags = useQuery({ queryKey: ['flags'], queryFn: app.api.flags.list });
  const schools = useQuery({ queryKey: ['schools'], queryFn: () => app.api.schools() });
  const set = useMutation({
    mutationFn: (b: { key: string; enabled: boolean; schoolId?: string | null; label?: string }) => app.api.flags.set(b.key, { enabled: b.enabled, schoolId: b.schoolId, label: b.label }),
    onSuccess: () => { void qc.invalidateQueries({ queryKey: ['flags'] }); },
    onError: (e) => say((e as Error).message, 'bad'),
  });
  const rows = flags.data ?? [];
  const fleet = rows.filter((f) => f.scope === 'fleet');
  const per = rows.filter((f) => f.scope === 'school');
  const canWrite = app.can('flags.write');
  const school = (id: string | null) => schools.data?.find((s) => s.id === id)?.name ?? 'one school';
  const add = () => {
    if (!/^[a-z][a-z0-9._-]{2,40}$/.test(key)) { setErr('Use lowercase letters, numbers, dots or dashes, 3 to 41 long. Example: new.report-cards'); shake.hit(); return; }
    set.mutate({ key, enabled: false, label: label.trim() || key }, { onSuccess: () => { setKey(''); setLabel(''); say('Flag added, switched off.'); } });
  };
  return (
    <Page active="flag" title="Flags" sub="Switch a feature on for everyone, or for one school, without shipping anything" toast={toast} loading={flags.isLoading} error={flags.isError ? { message: (flags.error as Error).message, retry: () => void flags.refetch() } : null}>
      <section className="grid">
        <Card title="Everyone" chip={<span className="chip">{fleet.length}</span>} span="s7">
          {fleet.length === 0 && <EmptyCard title="Flags" chip={{ text: '0 flags', tone: 'v' }} scene="checklist" heading="No flags yet" body="Add a flag to ship a feature switched off, then turn it on for one school before the rest." />}
          {fleet.map((f) => (
            <div className="tgl" key={f.key} style={{ display: 'flex', alignItems: 'center', gap: 20, padding: '14px 0', borderTop: '1px solid var(--line)' }}>
              <div style={{ flex: 1, minWidth: 0 }}><b style={{ font: '700 14.5px var(--fb)', display: 'block' }}>{f.label}</b><small style={{ font: '500 13px var(--fb)', color: 'var(--ink3)' }}>{f.key} · changed {ago(f.updatedAt)} by {f.updatedBy}</small></div>
              <button className={`sw ${f.enabled ? 'on' : ''}`} role="switch" aria-checked={f.enabled} aria-label={f.label} disabled={!canWrite || set.isPending} onClick={() => set.mutate({ key: f.key, enabled: !f.enabled })}></button>
            </div>
          ))}
        </Card>
        <div className="s5" style={{ display: 'flex', flexDirection: 'column', gap: 18 }}>
          {canWrite && (
            <Card title="New flag">
              <div className={shake.cls}>
                <Field label="Key" value={key} onChange={(v) => { setKey(v); setErr(''); }} error={err} placeholder="new.report-cards" />
                <Field label="What it does" value={label} onChange={setLabel} placeholder="Report cards with the new layout" />
              </div>
              <button className="btn pri" style={{ marginTop: 14 }} onClick={add} disabled={set.isPending}>Add flag</button>
            </Card>
          )}
          <Card title="Only some schools" chip={<span className="chip">{per.length}</span>}>
            {per.length === 0 && <div className="help">A flag you switch on for a single school shows up here.</div>}
            {per.map((f) => (
              <div className="kv" key={`${f.key}-${f.schoolId}`}><span>{f.label}<br /><small style={{ color: 'var(--ink3)' }}>{school(f.schoolId)}</small></span><b><span className={`st ${f.enabled ? 'g' : 'n'}`}><i></i>{f.enabled ? 'On' : 'Off'}</span></b></div>
            ))}
          </Card>
        </div>
      </section>
    </Page>
  );
}
