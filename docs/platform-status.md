# Platform build status (2026-10-18)

Branch `feat/platform`. The plan is `docs/superpowers/specs/2026-10-14-edunest-platform-design.md`; this file says what of it exists.
Deploying the free test track: `docs/deploy-free-test.md`. The full hand-off (decisions, how to continue, what is left) is `docs/HANDOFF.md`; the design concept is `docs/DESIGN.md`. Live test deployment: `https://edunest-0c6x.onrender.com` (admin `/`, console `/console/`).

## What exists and is checked

| Part | Where | Checks |
| --- | --- | --- |
| Workspace (pnpm + Turborepo), CI, Render blueprint | root, `.github/workflows`, `render.yaml` | `pnpm build`, `typecheck`, `test` all green |
| Contracts, config engine, security, db (schemas, migrations, migrator, Greenfield seed), tenancy, api-client, web-ui | `packages/*` | 9 + 4 + 4 + 13 + 1 + 6 + 3 unit tests |
| School API (sign-in with code, lockout, refresh rotation, students, attendance, fees, approvals, timetable, dashboard, settings and plan usage, search, audit, support-session read-only tokens) | `apps/api` | 27 tests on a real PostgreSQL |
| Console API (blueprints, wizard, provisioning drivers, approvals, releases in waves, migrations, health, support, flags, billing, team, sandbox inbox, build callback, demo seed on first start) | `apps/console-api` | 19 tests; schools are really created and signed in to |
| One process: both APIs, the admin at `/`, the console at `/console/` | `apps/server` | production build run locally and audited |
| School admin: sign-in, dashboard, students, timetable, settings (general, modules, audit log), phone home and dock, design-system page | `apps/admin` | see below |
| Console: sign-in, fleet, school (overview, entitlements, versions, health, audit), onboarding wizard, releases, migrations, cells, builds, flags, blueprints and rules, health, approvals, support, test inbox, billing, team | `apps/console` | see below |
| App: reads its school's name and tagline from the API (`SCHOOL`, `API_BASE_URL` build profile); the rest is still demo content | `lib/` | `flutter test` 32 pass |

UI checks, all repeatable:

- `node tools/audit-ui.mjs`: every page of both apps at 360, 390, 768 and 1440 wide, light and dark. Fails on console errors, failed calls, sideways scroll and anything clipped or outside the window.
- `node tools/e2e-flows.mjs`: sign-in errors, add student, dashboard approval, timetable clash fix and publish, settings save, search and shortcuts, phone dock, console release, flags, team, support and erase guards, billing.
- `node tools/e2e-onboard.mjs`: onboards a new empty school through the console wizard, signs in to it with the code from the test inbox, and screenshots every admin page (the brand-new-school states).
- `node tools/shot.mjs <url> out.png [w] [h] [--dark] [--console] [--audit] [--do '[...]']`: one screenshot, signed in.

## Not done, on purpose or not yet

- **Admin pages without a canvas board** (attendance, homework, exams, staff, admissions, fees, invoices, reports, notices, messages, events) say "opens in a coming release". Settings tabs App layout, Roles and access, Notifications, Message templates, Privacy and consent say "coming soon". The backend modules for most of these are not written.
- **Mobile**: the app does not use the school's data yet (only its name and tagline). Moving `lib/` to `apps/mobile`, real repositories, the EduNest picker app, store pipelines and code push (plan section 19, phase 9) are not started.
- **Hosting**: only the free test track (one Render service plus Neon). The AWS cell blueprint exists as a driver that needs a database admin URL per cell; no cloud account was touched.
- **Not verified**: the deployed environment (needs the owner's Neon and Render accounts), a real phone, liquid glass on a device, iOS.
- Visual match with the canvas was checked by eye against the boards (dashboard, students, timetable, settings, fleet, school), not by pixel diff, because the pages show real data and the boards show sample data.

## Rules worth remembering

- Never regenerate migrations once a real database has applied them: add a new file (the migrator refuses changed files).
- `tools/dc-to-tsx.mjs` and `convert-all.sh` are for the first import of a board only. The generated views have been edited by hand since.
- Pages not in the canvas are composed only from approved components (`packages/web-ui`, `apps/console/src/console.css`).
