import { useEffect, useState } from 'react';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { HttpError } from '@edunest/api-client';
import { dayLabel, type AttendanceStatus } from '@edunest/contracts';
import { EmptyCard, tintFor } from '@edunest/web-ui';
import { useApp } from '../../app/context';
import { Page, useToast } from '../../app/Page';

const OPTIONS: { value: AttendanceStatus; label: string; cls: string }[] = [
  { value: 'present', label: 'Present', cls: 'p' },
  { value: 'late', label: 'Late', cls: 'l' },
  { value: 'absent', label: 'Absent', cls: 'a' },
];

export function AttendancePage() {
  const app = useApp();
  const qc = useQueryClient();
  const { toast, say } = useToast();
  const [classId, setClassId] = useState('');
  const [draft, setDraft] = useState<Record<string, AttendanceStatus>>({});
  const classes = useQuery({ queryKey: ['classes'], queryFn: app.api.classes, staleTime: 5 * 60_000 });
  // The roll call is for the latest school day, which the dashboard already works out.
  const today = useQuery({ queryKey: ['dashboard', 1], queryFn: () => app.api.dashboard(1), staleTime: 60_000 });
  const date = today.data?.day.date ?? '';
  useEffect(() => { if (!classId && classes.data?.length) setClassId(classes.data[0]!.id); }, [classes.data, classId]);
  const day = useQuery({ queryKey: ['attendance-day', classId, date], queryFn: () => app.api.attendance.day(classId, date), enabled: !!classId && !!date });
  useEffect(() => { setDraft({}); }, [classId, date]);

  const save = useMutation({
    mutationFn: () => app.api.attendance.save({ classId, date, marks: Object.entries(draft).map(([studentId, status]) => ({ studentId, status })) }),
    onSuccess: () => {
      setDraft({});
      void qc.invalidateQueries({ predicate: (q) => ['attendance-day', 'dashboard', 'shell', 'students'].includes(String(q.queryKey[0])) });
      say('Roll call saved. Parents of absent children are told.');
    },
    onError: (e) => say(e instanceof HttpError ? e.message : 'Could not save. Try again.', 'bad'),
  });

  const canMark = app.user.permissions.includes('attendance.mark');
  const marks = day.data?.marks ?? [];
  const statusOf = (id: string, saved: AttendanceStatus | null) => draft[id] ?? saved;
  const counts = { present: 0, late: 0, absent: 0, none: 0 };
  for (const m of marks) { const s = statusOf(m.studentId, m.status); if (s === 'present') counts.present++; else if (s === 'late') counts.late++; else if (s === 'absent') counts.absent++; else counts.none++; }
  const changed = Object.keys(draft).length;
  const cls = classes.data?.find((c) => c.id === classId);
  const loading = classes.isLoading || today.isLoading;
  const err = [classes, today, day].find((q) => q.isError && !q.data);

  return (
    <Page active="att" title="Attendance" sub={date ? `${dayLabel(date)} · ${cls ? `Class ${cls.name}` : ''}` : 'Roll call'} toast={toast} loading={loading}
      error={err ? { message: (err.error as Error).message, retry: () => void err.refetch() } : null}
      actions={classes.data?.length ? (
        <select className="sel" aria-label="Class" value={classId} onChange={(e) => setClassId(e.target.value)}>
          {classes.data.map((c) => <option key={c.id} value={c.id}>Class {c.name}</option>)}
        </select>
      ) : undefined}>
      {classes.data?.length === 0 ? (
        <div style={{ maxWidth: 560 }}><EmptyCard title="Attendance" chip={{ text: '0 classes', tone: 'v' }} scene="calendar" heading="No classes to mark yet" body="Add students to a class first. The roll call for each class appears here every school day." actions={<button className="btn pri" onClick={() => app.go('/students')}>Add students</button>} /></div>
      ) : (
        <section className="grid">
          <div className="card tbl rcall s8 rise" style={{ padding: 0 }}>
            <div className="ch" style={{ padding: '22px 22px 14px' }}>
              <h2>Roll call</h2>
              <span className={`chip ${day.data?.submitted ? 'g' : 'a'}`}>{day.data?.submitted ? 'Submitted' : 'Not submitted yet'}</span>
              {canMark && marks.length > 0 && <button className="btn sm" onClick={() => setDraft(Object.fromEntries(marks.filter((m) => statusOf(m.studentId, m.status) !== 'present').map((m) => [m.studentId, 'present' as const])))}>Mark everyone present</button>}
            </div>
            {day.isLoading && <div className="skc" style={{ height: 320, margin: '0 22px 22px', borderRadius: 20 }} />}
            {!day.isLoading && marks.length === 0 && <div style={{ padding: '0 22px 22px' }}><EmptyCard title={`Class ${cls?.name ?? ''}`} chip={{ text: '0 students', tone: 'v' }} scene="register" heading="No students in this class" body="Students appear here once they are added to the class." /></div>}
            {marks.length > 0 && (
              <div className="scroll-x">
                {marks.map((m) => {
                  const t = tintFor(m.name);
                  const s = statusOf(m.studentId, m.status);
                  return (
                    <div className="grd rw" key={m.studentId} style={{ '--cols': '36px minmax(0,1fr) auto' } as React.CSSProperties}>
                      <span className="rn num">{m.rollNo || '–'}</span>
                      <span style={{ display: 'flex', alignItems: 'center', gap: 12, minWidth: 0 }}>
                        <span className="av" style={{ width: 34, height: 34, fontSize: 11, background: t.bg, color: t.fg, boxShadow: 'none', flex: 'none' }}>{m.name.split(' ').map((w) => w[0]).slice(0, 2).join('')}</span>
                        <b style={{ font: '700 14.5px var(--fb)', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{m.name}</b>
                      </span>
                      <span className="mk" role="group" aria-label={`Attendance for ${m.name}`}>
                        {OPTIONS.map((o) => (
                          <button key={o.value} className={o.cls} aria-pressed={s === o.value} disabled={!canMark} onClick={() => setDraft({ ...draft, [m.studentId]: o.value })}>{o.label}</button>
                        ))}
                      </span>
                    </div>
                  );
                })}
              </div>
            )}
          </div>
          <div className="s4" style={{ display: 'flex', flexDirection: 'column', gap: 18, minWidth: 0 }}>
            <div className="tile t-v rise" style={{ '--d': '.08s' } as React.CSSProperties}>
              <span className="lbl" style={{ color: 'rgba(255,255,255,.7)' }}>Present or late</span>
              <div className="big" style={{ marginTop: 8 }}>{counts.present + counts.late}<small style={{ fontSize: 18, opacity: .6 }}> / {marks.length}</small></div>
              <div className="meter" aria-hidden="true">
                <i style={{ flex: counts.present || 0.001, background: 'var(--g)' }}></i>
                <i style={{ flex: counts.late || 0.001, background: 'var(--a)' }}></i>
                <i style={{ flex: counts.absent || 0.001, background: 'var(--r)' }}></i>
                <i style={{ flex: counts.none || 0.001, background: 'rgba(255,255,255,.25)' }}></i>
              </div>
              <div className="tgrow" style={{ marginTop: 14, font: '700 13px var(--fb)' }}>
                <span>{counts.present} present</span><span>{counts.late} late</span><span>{counts.absent} absent</span>{counts.none > 0 && <span>{counts.none} not marked</span>}
              </div>
            </div>
            {canMark ? (
              <div className="card rise" style={{ '--d': '.14s' } as React.CSSProperties}>
                <div className="help" style={{ marginBottom: 12 }}>{changed ? `${changed} ${changed === 1 ? 'change' : 'changes'} not saved yet.` : 'Tap a name’s status to change it, then save.'}</div>
                <button className="btn pri" style={{ width: '100%' }} disabled={!changed || save.isPending} onClick={() => save.mutate()}>{save.isPending ? 'Saving…' : 'Save roll call'}</button>
                {changed > 0 && <button className="btn ghost" style={{ width: '100%', marginTop: 8 }} onClick={() => setDraft({})}>Discard changes</button>}
              </div>
            ) : (
              <div className="card rise"><div className="help">You can look at attendance but not change it. Ask the school office for the roll-call permission.</div></div>
            )}
          </div>
        </section>
      )}
    </Page>
  );
}
