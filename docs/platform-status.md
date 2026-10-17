# Platform build status (checkpoint, 2026-10-18)

Branch `feat/platform`. This is where the build stands, so the next session can carry on without re-deriving it.
The plan is `docs/superpowers/specs/2026-10-14-edunest-platform-design.md`.

## Done and tested

| Part | Where | Tests |
| --- | --- | --- |
| Workspace (pnpm + Turborepo) | root | |
| Shared contracts, config engine (modules, plans, layered config), dates, security (scrypt, AES-GCM seal, JWT) | `packages/contracts`, `config-engine`, `security` | 9 + 4 + 4 |
| School and registry schemas, reviewed SQL migrations with `-- kind:` headers, per-database migrator, throwaway PostgreSQL for dev and tests (`pg_ctl`, no Docker) | `packages/db` | 13 |
| Greenfield demo seed: 1,498 students, 42 classes, 24 days of attendance, fees, timetable with one real clash, approvals | `packages/db/src/seed` | in the 13 |
| Tenancy (registry lookup, bounded pool manager) | `packages/tenancy` | |
| School API (NestJS 11 + Fastify): sign-in with password and code, lockout, refresh rotation, students, attendance, fees, approvals, timetable, dashboard, settings, search, audit, support-session read-only tokens | `apps/api` | 27 on a real PostgreSQL |
| Console API: blueprints (versioned, order-checked), new-school wizard, drafts, review, dry run, provisioning engine with drivers (local, shared server, Neon, aws-cell), actions with second-person approval and typed confirmation, releases in waves with auto-halt and rollback, migrations view, health prober and incidents, support sessions, flags, billing, team, audit, message sandbox | `apps/console-api` | 19, schools are really created and signed in to |
| One process for both (test track) | `apps/server` | smoke-tested locally |
| Demo school script | `tools/provision-demo.mjs` | ran against the local server |

Run locally: `pnpm install`, start a database with `pnpm dev:db`, copy `.env.example` to `.env`, run `apps/server` (`tsx src/main.ts`), then `node tools/provision-demo.mjs`.
Console sign-in `kaushal@edunest.app` / `nest2026` / code `424242` (demo code only when `DEMO_CODE` is set).

## Started, not finished: the web apps

- `design/canvas/` holds the approved canvas boards and `nest.css` (the source of truth for how it must look).
- `tools/dc-to-tsx.mjs` + `tools/convert-all.sh` convert a board into a React view, scoped CSS and a copy of its script. Already run for every board; the generated views live under `apps/admin/src/pages`, `apps/admin/src/design`, `apps/console/src/pages` and `packages/web-ui/src/login`.
- `packages/web-ui`: nest.css, shell, sidebar, palette, empty states, `Roll`, theme, and the 12 object illustrations that replace the mascot. The login page is finished (`LoginPage`, `useLogin`).
- `packages/api-client`: typed calls for both APIs.
- `apps/admin`: router, auth, chrome hook, status pages written. The dashboard view has been edited for real data and the new charts (slim columns, segmented roll bars, filled fee bars; `tools/edit-dashboard-*.py` ran once).

**Not written yet (the app does not build until these exist):**
1. `apps/admin/src/pages/dashboard/DashboardPage.tsx` (the data hook; the plan for it is in the conversation: chart tabs from `charts`, range menu = `days` 1/6/24, Needs you with optimistic decide and Undo, rolling numbers from a 20 s refetch).
2. Students, Timetable and Settings pages (views converted, hooks not written), the phone layout (`phone.view.tsx` + dock), the design-system pages (`apps/admin/src/design`, plus a `DesignPage`), mascot text removed from the Language board.
3. `apps/console` app (skeleton, router, fleet and school pages, wizard, and the unbuilt pages: releases, blueprints, team, billing, inbox).
4. Visual diff against the canvas (Playwright, `design/canvas/preview.html` renders a board), UI bug sweep in light and dark at 360, 390 and 1440 widths.
5. Deployment: `render.yaml` (one free web service running `apps/server`, two static sites), Neon database, `.github/workflows/mobile-build.yml`. Needs the user's Render, Neon and GitHub accounts.
6. Plan document update: 12.2 should list the seven steps now in `STEP_KEYS`.
7. Flutter: moving the app to `apps/mobile` and real repositories were not started.

## Calls to check
- Pages not in the canvas (wizard, releases, blueprints, team, billing, inbox, "coming soon") are to be composed only from approved components.
- The console sign-in shows a password field (the canvas had email only), because the console needs a password.
- The theme follows the device; the canvas has no theme control.
- Never regenerate migrations once a real database has applied them: add a new file instead (the migrator refuses changed files).
