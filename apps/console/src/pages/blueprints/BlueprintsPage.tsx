import { useEffect, useState } from 'react';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { HttpError } from '@edunest/api-client';
import { STEP_LABELS, type BlueprintRow, type PolicyDoc } from '@edunest/contracts';
import { EmptyCard } from '@edunest/web-ui';
import { Card, Page, useToast } from '../../app/Page';
import { useApp } from '../../app/context';
import { ago } from '../../app/format';

const REQUIRED = ['database', 'migrate-seed', 'admin'];
const TARGET: Record<string, string> = { local: 'This computer', 'free-test': 'Free test track', 'aws-cell': 'AWS cell' };
const ACTION: Record<string, string> = {
  'school.suspend': 'Suspend a school', 'school.resume': 'Bring a school back', 'school.erase': 'Erase a school', 'entitlements.push': 'Send plan changes',
  'migration.run': 'Run database changes', 'domain.set': 'Change an address', 'build.app': 'Build the app', 'backup.take': 'Take a backup',
};

export function BlueprintsPage() {
  const app = useApp();
  const qc = useQueryClient();
  const { toast, say } = useToast();
  const bps = useQuery({ queryKey: ['blueprints'], queryFn: app.api.blueprints.list });
  const policy = useQuery({ queryKey: ['policy'], queryFn: app.api.policy.get });
  const [open, setOpen] = useState('');
  const [draft, setDraft] = useState<Record<string, BlueprintRow['steps']>>({});
  const [pol, setPol] = useState<PolicyDoc | null>(null);
  useEffect(() => { if (policy.data) setPol(policy.data); }, [policy.data]);

  const save = useMutation({
    mutationFn: async (bp: BlueprintRow) => { const row = await app.api.blueprints.save({ key: bp.key, name: bp.name, target: bp.target, plan: bp.plan, steps: draft[bp.id] ?? bp.steps }); await app.api.blueprints.activate(row.id); return row; },
    onSuccess: (r) => { void qc.invalidateQueries({ queryKey: ['blueprints'] }); setDraft({}); say(`Saved as version ${r.version} and switched on. New schools use it from now.`); },
    onError: (e) => say(e instanceof HttpError ? e.message : (e as Error).message, 'bad'),
  });
  const savePolicy = useMutation({
    mutationFn: (p: PolicyDoc) => app.api.policy.set(p),
    onSuccess: () => { void qc.invalidateQueries({ queryKey: ['policy'] }); say('Rules saved.'); },
    onError: (e) => say((e as Error).message, 'bad'),
  });
  const canBp = app.can('blueprints.write');
  const canPol = app.can('policy.write');
  const rows = (bps.data ?? []).filter((b) => b.active);
  const dirtyPol = pol && policy.data && JSON.stringify(pol) !== JSON.stringify(policy.data);

  return (
    <Page active="bp" title="Blueprints and rules" sub="The recipe every new school is set up with, and the rules for risky changes" toast={toast} loading={bps.isLoading || policy.isLoading} error={bps.isError || policy.isError ? { message: ((bps.error ?? policy.error) as Error).message, retry: () => { void bps.refetch(); void policy.refetch(); } } : null}>
      <section className="grid">
        <div className="s7" style={{ display: 'flex', flexDirection: 'column', gap: 18, minWidth: 0 }}>
          {rows.length === 0 && <EmptyCard title="Blueprints" chip={{ text: 'None', tone: 'v' }} scene="checklist" heading="No blueprint is active" body="The platform creates one for each place schools can run when it first starts." />}
          {rows.map((bp) => {
            const steps = draft[bp.id] ?? bp.steps;
            const isOpen = open === bp.id;
            return (
              <Card key={bp.id} title={bp.name} chip={<span className="chip v">{TARGET[bp.target] ?? bp.target} · v{bp.version}</span>}>
                <div className="help">By {bp.createdBy} · {ago(bp.createdAt)}. {steps.filter((s) => s.enabled).length} of {steps.length} steps on.</div>
                <button className="btn sm" style={{ marginTop: 10 }} onClick={() => setOpen(isOpen ? '' : bp.id)} aria-expanded={isOpen}>{isOpen ? 'Hide steps' : 'Show steps'}</button>
                {isOpen && (
                  <div style={{ marginTop: 10 }}>
                    {steps.map((s, i) => {
                      const must = REQUIRED.includes(s.key);
                      return (
                        <div key={s.key} style={{ display: 'flex', alignItems: 'center', gap: 16, padding: '12px 0', borderTop: '1px solid var(--line)' }}>
                          <span className="av" style={{ width: 28, height: 28, fontSize: 12, background: 'var(--sunk)', color: 'var(--ink3)', boxShadow: 'none' }}>{i + 1}</span>
                          <span style={{ flex: 1, minWidth: 0 }}><b style={{ font: '700 14px var(--fb)', display: 'block' }}>{STEP_LABELS[s.key]}</b><small style={{ color: 'var(--ink3)', font: '500 12.5px var(--fb)' }}>{must ? 'Always runs' : s.optional ? 'Optional' : 'Runs unless switched off'}{Object.keys(s.params).length ? ` · ${Object.entries(s.params).map(([k, v]) => `${k}: ${String(v)}`).join(', ')}` : ''}</small></span>
                          <button className={`sw ${s.enabled ? 'on' : ''}`} role="switch" aria-checked={s.enabled} aria-label={STEP_LABELS[s.key]} disabled={must || !canBp} onClick={() => setDraft({ ...draft, [bp.id]: steps.map((x) => (x.key === s.key ? { ...x, enabled: !x.enabled } : x)) })}></button>
                        </div>
                      );
                    })}
                    {canBp && draft[bp.id] && <div className="tgrow" style={{ marginTop: 14 }}><button className="btn pri" disabled={save.isPending} onClick={() => save.mutate(bp)}>Save as a new version</button><button className="btn" onClick={() => setDraft({})}>Discard</button></div>}
                  </div>
                )}
              </Card>
            );
          })}
        </div>
        <Card title="Rules for risky changes" span="s5">
          {pol && (
            <>
              <div className="lbl" style={{ marginBottom: 4 }}>Needs a second person</div>
              {Object.keys(ACTION).map((a) => (
                <div key={a} style={{ display: 'flex', alignItems: 'center', gap: 16, padding: '10px 0', borderTop: '1px solid var(--line)' }}>
                  <span style={{ flex: 1, font: '600 14px var(--fb)' }}>{ACTION[a]}</span>
                  <button className={`sw ${pol.approvals[a]?.needed ? 'on' : ''}`} role="switch" aria-checked={!!pol.approvals[a]?.needed} aria-label={ACTION[a]} disabled={!canPol} onClick={() => setPol({ ...pol, approvals: { ...pol.approvals, [a]: { roles: pol.approvals[a]?.roles ?? ['super_admin'], needed: !pol.approvals[a]?.needed } } })}></button>
                </div>
              ))}
              <div style={{ display: 'flex', alignItems: 'center', gap: 16, padding: '12px 0', borderTop: '1px solid var(--line)' }}>
                <span style={{ flex: 1 }}><b style={{ font: '700 14px var(--fb)', display: 'block' }}>Freeze changes</b><small style={{ color: 'var(--ink3)', font: '500 12.5px var(--fb)' }}>Blocks everything except suspending a school</small></span>
                <button className={`sw ${pol.freeze ? 'on' : ''}`} role="switch" aria-checked={pol.freeze} aria-label="Freeze changes" disabled={!canPol} onClick={() => setPol({ ...pol, freeze: !pol.freeze })}></button>
              </div>
              <div className="two" style={{ marginTop: 6 }}>
                <label className="fld"><span className="lbl">Stop a rollout above (error %)</span><span className="inp"><input type="number" min={0} max={100} value={pol.halt.errorRatePct} disabled={!canPol} onChange={(e) => setPol({ ...pol, halt: { ...pol.halt, errorRatePct: Number(e.target.value) } })} /></span></label>
                <label className="fld"><span className="lbl">…or when p95 passes (ms)</span><span className="inp"><input type="number" min={0} value={pol.halt.p95Ms} disabled={!canPol} onChange={(e) => setPol({ ...pol, halt: { ...pol.halt, p95Ms: Number(e.target.value) } })} /></span></label>
              </div>
              {canPol && <button className="btn pri" style={{ marginTop: 16 }} disabled={!dirtyPol || savePolicy.isPending} onClick={() => savePolicy.mutate(pol)}>Save rules</button>}
            </>
          )}
        </Card>
      </section>
    </Page>
  );
}
