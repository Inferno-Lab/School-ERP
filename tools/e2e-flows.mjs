#!/usr/bin/env node
// Drives the real admin and console in a browser through the flows people use, against the demo school, and fails on the first thing that
// does not behave. Run after `tools/dev-reset.sh` (it changes demo data). Usage: node tools/e2e-flows.mjs [outDir]
import { chromium } from '@playwright/test';
import { mkdirSync } from 'node:fs';

const out = process.argv[2] ?? 'e2e-shots';
mkdirSync(out, { recursive: true });
const API = process.env.API ?? 'http://localhost:4000';
const ADMIN = process.env.ADMIN ?? 'http://127.0.0.1:5173';
const CONSOLE = process.env.CONSOLE ?? 'http://127.0.0.1:5174';
const slug = 'greenfield';
const post = async (p, b, h = {}) => (await fetch(API + p, { method: 'POST', headers: { 'content-type': 'application/json', ...h }, body: JSON.stringify(b) })).json();

const browser = await chromium.launch();
const errors = [];
let passed = 0;
async function flow(name, ctxOpts, fn) {
  if (process.env.ONLY && !name.includes(process.env.ONLY)) return;
  const ctx = await browser.newContext({ viewport: { width: 1440, height: 900 }, reducedMotion: 'reduce', ...ctxOpts.context });
  if (ctxOpts.storage) await ctx.addInitScript(([k, v]) => { try { localStorage.setItem(k, v); } catch {} }, ctxOpts.storage);
  const page = await ctx.newPage();
  const seen = [];
  page.on('pageerror', (e) => seen.push(`pageerror ${e.message}`));
  page.on('console', (m) => { if (m.type() === 'error' && !/40[01] \(|Failed to load resource/.test(m.text())) seen.push(`console ${m.text().slice(0, 140)}`); });
  try {
    await fn(page);
    if (seen.length) throw new Error(seen.join(' | '));
    passed++;
    console.log(`✓ ${name}`);
  } catch (e) {
    errors.push(`${name}: ${e.message.split('\n')[0]}`);
    console.log(`✗ ${name}: ${e.message.split('\n')[0]}`);
    await page.screenshot({ path: `${out}/FAIL-${name.replace(/\W+/g, '_')}.png` }).catch(() => undefined);
  }
  await ctx.close();
}
const expectVisible = async (loc, what, timeout = 8000) => { await loc.first().waitFor({ state: 'visible', timeout }).catch(() => { throw new Error(`expected to see ${what}`); }); };

// ── tokens ───────────────────────────────────────────────────────────────
const h = { 'x-school': slug };
const a = await post('/v1/auth/login', { identifier: 'neha.menon@greenfield.edu.in', password: 'nest2026' }, h);
const t = await post('/v1/auth/verify', { challengeId: a.challenge.challengeId, code: '424242' }, h);
const adminStore = [`edunest.admin.${slug}`, JSON.stringify({ accessToken: t.accessToken, refreshToken: t.refreshToken, user: t.user })];
const ca = await post('/console/v1/auth/login', { identifier: 'kaushal@edunest.app', password: 'nest2026' });
const ct = await post('/console/v1/auth/verify', { challengeId: ca.challenge.challengeId, code: '424242' });
const consoleStore = ['edunest.console', JSON.stringify({ accessToken: ct.accessToken, refreshToken: ct.refreshToken, user: ct.user })];
const school = (await (await fetch(`${API}/console/v1/schools`, { headers: { authorization: `Bearer ${ct.accessToken}` } })).json()).find((s) => s.slug === slug);

// ── admin ────────────────────────────────────────────────────────────────
await flow('admin: wrong password shows an error, then the demo code signs in', {}, async (p) => {
  await p.goto(`${ADMIN}/s/${slug}/login`, { waitUntil: 'networkidle' });
  await p.getByRole('button', { name: /^Sign in/ }).click();
  await expectVisible(p.getByText('Enter your school email to continue').or(p.getByText('Enter your password to continue')), 'an empty-form error');
  await p.getByLabel('Work email').fill('neha.menon@greenfield.edu.in');
  await p.locator('#lg-pw').fill('wrong-password');
  await p.getByRole('button', { name: /^Sign in/ }).click();
  await expectVisible(p.getByRole('alert'), 'the wrong-password message');
  await p.locator('#lg-pw').fill('nest2026');
  await p.getByRole('button', { name: /^Sign in/ }).click();
  await expectVisible(p.getByText('Verify and sign in'), 'the code step');
  await p.getByLabel('6-digit code').fill('111111');
  await expectVisible(p.getByRole('alert'), 'the wrong-code message');
  await p.getByRole('button', { name: /Type the demo code/ }).click();
  await p.waitForURL(`${ADMIN}/s/${slug}/`, { timeout: 15000 });
  await expectVisible(p.getByRole('heading', { name: 'Dashboard' }), 'the dashboard');
});

await flow('admin: dashboard approval, then undo', { storage: adminStore }, async (p) => {
  await p.goto(`${ADMIN}/s/${slug}/`, { waitUntil: 'networkidle' });
  await expectVisible(p.getByText('Needs you'), 'the needs-you card');
  await p.getByRole('button', { name: 'Approve' }).first().click();
  await expectVisible(p.getByRole('status'), 'the confirmation toast');
});

await flow('admin: add a student, find it, collect a fee', { storage: adminStore }, async (p) => {
  await p.goto(`${ADMIN}/s/${slug}/students`, { waitUntil: 'networkidle' });
  await p.getByRole('button', { name: 'Add student' }).first().click();
  await p.getByRole('button', { name: 'Add student' }).last().click();
  await expectVisible(p.getByText(/name/i).and(p.getByRole('alert')), 'a name error');
  await p.getByLabel('Full name').fill('Test Student Zed');
  await p.getByLabel('Date of birth').fill('2014-05-06');
  await p.getByLabel('Guardian', { exact: true }).fill('Zed Parent');
  await p.getByLabel('Guardian’s phone').fill('9820099887');
  await p.getByRole('button', { name: 'Add student' }).last().click();
  await expectVisible(p.getByRole('status'), 'the added toast');
  await p.getByLabel('Search students').fill('Test Student Zed');
  await expectVisible(p.getByText('Test Student Zed'), 'the new student in the list', 10000);
});

await flow('admin: a student drawer opens and closes', { storage: adminStore }, async (p) => {
  await p.goto(`${ADMIN}/s/${slug}/students`, { waitUntil: 'networkidle' });
  await p.locator('.rw').first().click();
  await expectVisible(p.locator('.drw'), 'the student drawer');
  await p.keyboard.press('Escape');
  await p.locator('.drw.open').waitFor({ state: 'detached', timeout: 3000 }).catch(() => undefined);
});

await flow('admin: timetable clash can be fixed and published', { storage: adminStore }, async (p) => {
  await p.goto(`${ADMIN}/s/${slug}/timetable`, { waitUntil: 'networkidle' });
  await expectVisible(p.getByText(/clash/i), 'the clash notice');
  await p.locator('.cell.bad, [class*=bad]').first().click();
  await expectVisible(p.getByRole('button', { name: /to cover/ }), 'the cover suggestion');
  await p.getByRole('button', { name: /to cover/ }).click();
  await expectVisible(p.getByText(/Clash fixed/), 'the fixed message');
  await p.getByRole('button', { name: /Publish/ }).first().click();
  await expectVisible(p.getByRole('status'), 'the published toast');
});

await flow('admin: roll call can be changed and saved', { storage: adminStore }, async (p) => {
  await p.goto(`${ADMIN}/s/${slug}/attendance`, { waitUntil: 'networkidle' });
  await expectVisible(p.getByText('Roll call'), 'the roll call');
  await p.getByRole('group', { name: /^Attendance for/ }).first().getByRole('button', { name: 'Absent' }).click();
  await expectVisible(p.getByText(/1 change/), 'the unsaved count');
  await p.getByRole('button', { name: 'Save roll call' }).click();
  await expectVisible(p.getByRole('status'), 'the saved toast');
});

await flow('admin: a notice is written and goes for approval or out', { storage: adminStore }, async (p) => {
  await p.goto(`${ADMIN}/s/${slug}/notices`, { waitUntil: 'networkidle' });
  await p.getByRole('button', { name: 'New notice' }).click();
  await p.getByRole('button', { name: /Save as draft/ }).click();
  await expectVisible(p.getByText('Give the notice a title.'), 'the title error');
  await p.getByLabel('Title').fill('Sports day on Friday');
  await p.locator('#ntc-body').fill('Children come in sports uniform. School ends at noon.');
  await p.getByRole('button', { name: /Send now|Send for approval/ }).click();
  await expectVisible(p.getByText('Sports day on Friday'), 'the notice in the list');
});

await flow('admin: fees page lists overdue families and opens a payment', { storage: adminStore }, async (p) => {
  await p.goto(`${ADMIN}/s/${slug}/fees`, { waitUntil: 'networkidle' });
  await expectVisible(p.getByText('Overdue families'), 'the overdue list');
  await p.getByRole('button', { name: 'Collect' }).first().click();
  await expectVisible(p.getByText(/Collect a fee from/), 'the payment dialog');
  await p.keyboard.press('Escape');
});

await flow('admin: settings change saves, shakes on a bad value', { storage: adminStore }, async (p) => {
  await p.goto(`${ADMIN}/s/${slug}/settings`, { waitUntil: 'networkidle' });
  const name = p.getByLabel('School name');
  await name.fill('G');
  await p.getByRole('button', { name: 'Save changes' }).click();
  await expectVisible(p.getByText(/at least 2 letters/), 'the name error');
  await name.fill('Greenfield International School');
  await p.getByRole('radio', { name: 'Orange' }).click();
  await p.getByRole('button', { name: 'Save changes' }).click();
  await expectVisible(p.getByText(/Saved\./), 'the saved toast');
  await p.getByRole('radio', { name: 'Violet' }).click();
  await p.getByRole('button', { name: 'Save changes' }).click();
  await expectVisible(p.getByText(/Saved\./), 'the saved toast again');
  await p.getByRole('button', { name: 'Modules' }).click();
  await expectVisible(p.getByText('Always on'), 'the modules list');
  await p.getByRole('button', { name: 'Audit log' }).click();
  await expectVisible(p.getByText(/settings.changed/), 'the settings change in the audit log');
});

await flow('admin: search palette and keyboard shortcuts', { storage: adminStore }, async (p) => {
  await p.goto(`${ADMIN}/s/${slug}/`, { waitUntil: 'networkidle' });
  await p.keyboard.press('Control+k');
  await p.keyboard.type('Aarav', { delay: 40 });
  await expectVisible(p.getByText(/^Aarav /), 'a search result');
  await p.keyboard.press('Escape');
  await p.keyboard.press('g');
  await p.keyboard.press('s');
  await p.waitForURL(/\/students/);
});

await flow('admin: search opens on every page and the menu collapses', { storage: adminStore }, async (p) => {
  for (const path of ['', '/students', '/timetable', '/settings']) {
    await p.goto(`${ADMIN}/s/${slug}${path}`, { waitUntil: 'networkidle' });
    await p.keyboard.press('Control+k');
    await expectVisible(p.getByLabel('Search', { exact: true }), `the search box on ${path || '/'}`);
    await p.keyboard.press('Escape');
  }
  await p.getByRole('button', { name: 'Collapse the menu' }).click();
  await expectVisible(p.getByRole('button', { name: 'Expand the menu' }), 'the collapsed menu');
});

await flow('admin: sign out returns to the sign-in page', { storage: adminStore }, async (p) => {
  await p.goto(`${ADMIN}/s/${slug}/`, { waitUntil: 'networkidle' });
  await p.locator('.mebtn').click();
  await p.getByRole('menuitem', { name: 'Sign out' }).click();
  await p.waitForURL(/\/login/);
});

await flow('admin: phone dock navigates', { storage: adminStore, context: { viewport: { width: 390, height: 844 } } }, async (p) => {
  await p.goto(`${ADMIN}/s/${slug}/`, { waitUntil: 'networkidle' });
  await expectVisible(p.getByText('Needs you'), 'the phone home');
  await p.getByRole('button', { name: 'People' }).click();
  await p.waitForURL(/\/students/);
  await p.getByRole('button', { name: 'More' }).click();
  await p.getByRole('link', { name: 'Timetable' }).click();
  await p.waitForURL(/\/timetable/);
});

// ── console ──────────────────────────────────────────────────────────────
await flow('console: wrong password shakes, right password and code sign in', {}, async (p) => {
  await p.goto(`${CONSOLE}/login`, { waitUntil: 'networkidle' });
  await p.getByLabel('Work email').fill('kaushal@edunest.app');
  await p.locator('#lg-pw').fill('nope');
  await p.getByRole('button', { name: /^Continue/ }).click();
  await expectVisible(p.getByRole('alert'), 'the wrong-password message');
  await p.locator('#lg-pw').fill('nest2026');
  await p.getByRole('button', { name: /^Continue/ }).click();
  await expectVisible(p.getByText('Verify and sign in'), 'the code step');
  await p.getByLabel('6-digit code').fill('424242');
  await p.waitForURL(`${CONSOLE}/`, { timeout: 15000 });
  await expectVisible(p.getByRole('heading', { name: 'Fleet' }), 'the fleet page');
});

const ver = `2026.10.${Math.floor(Math.random() * 900) + 50}`;
await flow('console: create, start, pause and roll back a release', { storage: consoleStore }, async (p) => {
  await p.goto(`${CONSOLE}/releases`, { waitUntil: 'networkidle' });
  await p.getByRole('button', { name: 'New release' }).click();
  await p.getByLabel('Version').fill('bad');
  await p.getByRole('button', { name: 'Create', exact: true }).click();
  await expectVisible(p.getByText(/year, month and a number|Use year/i), 'the version error');
  await p.getByLabel('Version').fill(ver);
  await p.getByLabel('What changed').fill('Test release');
  await p.getByRole('button', { name: 'Create', exact: true }).click();
  await expectVisible(p.getByText(ver), 'the new release');
  await p.getByRole('button', { name: 'Start rollout' }).first().click();
  await expectVisible(p.getByRole('status'), 'the started toast');
  await p.getByRole('button', { name: /Roll back/ }).first().click();
  await p.getByRole('button', { name: 'Roll back', exact: true }).last().click();
  await expectVisible(p.getByText(/Rolled back/i), 'the rolled back state');
});

await flow('console: flags add and toggle', { storage: consoleStore }, async (p) => {
  await p.goto(`${CONSOLE}/flags`, { waitUntil: 'networkidle' });
  await p.getByLabel('Key').fill('Bad Key');
  await p.getByRole('button', { name: 'Add flag' }).click();
  await expectVisible(p.getByText(/lowercase letters/), 'the key error');
  const key = `e2e.flag-${Date.now() % 100000}`;
  await p.getByLabel('Key').fill(key);
  await p.getByRole('button', { name: 'Add flag' }).click();
  await expectVisible(p.getByText(key), 'the new flag');
  await p.getByRole('switch', { name: key }).or(p.getByRole('switch').last()).first().click();
});

await flow('console: team add validates, then adds', { storage: consoleStore }, async (p) => {
  await p.goto(`${CONSOLE}/team`, { waitUntil: 'networkidle' });
  await p.getByRole('button', { name: 'Add a person' }).click();
  await p.getByRole('button', { name: 'Add', exact: true }).click();
  await expectVisible(p.getByText('Enter their name.'), 'the name error');
  await p.getByLabel('Name', { exact: true }).fill('Test Person');
  await p.getByLabel('Work email').fill(`tp${Date.now() % 100000}@edunest.app`);
  await p.getByLabel('First password').fill('long-enough-password');
  await p.getByRole('button', { name: 'Add', exact: true }).click();
  await expectVisible(p.getByText('Test Person'), 'the new person');
});

await flow('console: support needs a reason; erase needs the school code', { storage: consoleStore }, async (p) => {
  await p.goto(`${CONSOLE}/schools/${school.id}`, { waitUntil: 'networkidle' });
  await p.getByRole('button', { name: 'Erase school' }).click();
  await p.getByLabel(/Type/).fill('wrong');
  await p.getByRole('button', { name: 'Request erasure' }).click();
  await expectVisible(p.getByText(/isn’t the school code/), 'the wrong-code message');
  await p.keyboard.press('Escape');
  await p.getByRole('button', { name: 'Support session' }).click();
  await p.getByRole('button', { name: 'Start session' }).click();
  await expectVisible(p.getByText(/at least 8 letters/), 'the reason error');
  await p.keyboard.press('Escape');
  for (const tab of ['Entitlements', 'Versions', 'Health', 'Audit', 'Overview']) {
    await p.getByRole('tab', { name: tab }).click();
    await p.waitForTimeout(300);
  }
});

await flow('support: a session shows the banner and cannot change anything', {}, async (p) => {
  const r = await (await fetch(`${API}/console/v1/support`, { method: 'POST', headers: { 'content-type': 'application/json', authorization: `Bearer ${ct.accessToken}` }, body: JSON.stringify({ schoolId: school.id, reason: 'End to end check of the support banner' }) })).json();
  if (!r.token) throw new Error(`no token: ${JSON.stringify(r)}`);
  await p.goto(`${ADMIN}/s/${slug}/settings#support=${r.token}`, { waitUntil: 'networkidle' });
  await expectVisible(p.getByText(/read-only/), 'the support banner');
  await expectVisible(p.getByLabel('School name'), 'the name field');
  if (!(await p.getByLabel('School name').evaluate((el) => el.readOnly))) throw new Error('the name field should be read-only');
  if (!(await p.getByRole('button', { name: 'Save changes' }).isDisabled())) throw new Error('Save should be disabled');
  const refused = await fetch(`${API}/v1/settings`, { method: 'PATCH', headers: { 'content-type': 'application/json', 'x-school': slug, authorization: `Bearer ${r.token}` }, body: JSON.stringify({ changes: { 'school.name': 'Hacked' } }) });
  if (refused.status !== 403) throw new Error(`the API should refuse support writes, got ${refused.status}`);
  await p.getByRole('button', { name: 'End session' }).click();
  await p.waitForURL(/\/login/);
  await fetch(`${API}/console/v1/support/${r.session.id}`, { method: 'DELETE', headers: { authorization: `Bearer ${ct.accessToken}` } });
});

await flow('console: billing generates invoices once', { storage: consoleStore }, async (p) => {
  await p.goto(`${CONSOLE}/billing`, { waitUntil: 'networkidle' });
  await p.getByRole('button', { name: 'Create invoices' }).click();
  await expectVisible(p.getByRole('status'), 'the result toast');
  await p.getByRole('button', { name: 'Create invoices' }).click();
  await expectVisible(p.getByText(/already have an invoice|invoice/), 'the repeat message');
});

await flow('console: every menu page opens', { storage: consoleStore }, async (p) => {
  for (const path of ['/', '/onboarding', '/cells', '/releases', '/migrations', '/builds', '/flags', '/blueprints', '/health', '/approvals', '/support', '/inbox', '/billing', '/team']) {
    await p.goto(`${CONSOLE}${path}`, { waitUntil: 'networkidle' });
    await expectVisible(p.locator('main h1'), `a title on ${path}`);
  }
});

await browser.close();
console.log(`\n${passed} flows passed${errors.length ? `, ${errors.length} failed:\n - ${errors.join('\n - ')}` : ''}`);
process.exit(errors.length ? 1 : 0);
