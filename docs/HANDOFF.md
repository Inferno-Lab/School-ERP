# Hand-off guide

Written 2026-10-18 for whoever continues this work (a person, or another Claude account with no memory of the earlier sessions). Read it top to bottom once, then use it as a reference. It says what was asked, what was built, **how and why it was built that way**, what is left, and **how to do each remaining part**.

Related files: [`README.md`](../README.md) (overview and run commands), [`AGENTS.md`](../AGENTS.md) (rules for the Flutter app and agent workflow), [`docs/platform-status.md`](platform-status.md) (short status table), [`docs/deploy-free-test.md`](deploy-free-test.md) (deploying), [`design/README.md`](../design/README.md) (the design boards), [`docs/superpowers/specs/2026-10-14-edunest-platform-design.md`](superpowers/specs/2026-10-14-edunest-platform-design.md) (the full plan, 1,150 lines; section numbers below refer to it).

---

## 1. The brief, as the owner gave it

The owner (Kaushal) runs EduNest. In order, over several sessions:

1. Built a Flutter school app (students, parents, teachers) on mock JSON, redesigned as "Chalk & Glass". Done on branch `redesign/chalk-glass`.
2. Asked for a plan for a platform around it: an **admin panel** (school staff), a **console** (EduNest developers/staff), a **backend**, all in **one repository**, role-based access, a configurable app so features can be shown/hidden without code changes. The result is the 1,150-line plan.
3. Designed the admin and console in a design canvas ("Nest" language), then said: the design is "crazy and impeccable" but **replace the childish parts** (pencil-shaped columns, the fee jars, the bird mascot "Nesti") — **in the build, not in the canvas**. Also: onboarding a school and deploying for it must be done **from the console and be configurable** (blueprints, deploy targets). The test deployment must be **hosted free** and all three (app, admin, console) must work together there.
4. Final instruction: "implement the entire plan end to end", design **byte-identical to the canvas** except the childish items, jars become filled bars, **no UI bugs** ("I do not want to go through the debugging arc, so test thoroughly"), **deploy on Render** (it is fine if it shuts down), keep it **free**, ask for step-by-step instructions when something needs the owner (accounts), and **bars must not be thin**.
5. After the first deploy the owner reported a black screen. That was two real bugs (section 8.4), fixed.

Standing rules from the owner: no Chalk & Glass in admin/console; admin and console are one consistent language; the login has an animation and **vibrating errors**; empty pages have artwork; smooth animation everywhere; no themed metaphors beyond the references the owner picked (see `design/README.md`).

What "the entire plan" means in practice: the plan's build order (section 24) has 11 steps and describes a production system for 500 schools on AWS. That cannot be finished in one go. What was built is the **free test track slice of steps 0–2, 8 and parts of 3–5**: a working multi-tenant backend, the school admin for the core jobs, a complete console, provisioning from the console, and a free hosted deployment. Section 9 lists precisely what is left.

## 2. What exists

### 2.1 Running system

- **Deployed test track:** `https://edunest-0c6x.onrender.com` (Render free web service `edunest`, Neon Postgres). Admin at `/`, console at `/console/`. Demo school at `/s/greenfield`. See section 8.
- **Local:** `bash tools/dev-reset.sh` plus the two Vite dev servers (README).

### 2.2 Code by area

| Area | Path | What it does |
| --- | --- | --- |
| Shared types | `packages/contracts` | zod schemas and TypeScript types for every request/response of both APIs, the 7 provisioning `STEP_KEYS`, permission keys, console roles/permissions, date helpers (IST). Everything that crosses the wire is defined here first. |
| Config engine | `packages/config-engine` | Module manifests (which modules exist, what each requires), plans, `closeModules` (add required, drop dependents), `resolveConfig` (layers: platform defaults, plan entitlements, school settings, platform locks, audience), `validateSettingsChanges` (schema + locks), `contrastRatio` (WCAG, used for brand colours). |
| Security | `packages/security` | scrypt password hashing, AES-256-GCM `seal/unseal` for connection strings, HS256 JWT sign/verify, constant-time compare. |
| Database | `packages/db` | Drizzle schemas for the school database and the registry; **hand-reviewed SQL migrations** with `-- kind: expand|backfill|contract` headers; migrator (advisory lock, checksums, refuses edited applied files); the Greenfield seed (1,498 students, 42 classes, 24 days of attendance, fees, timetable with one deliberate teacher clash, approvals); `dev.ts` starts a throwaway PostgreSQL with `pg_ctl`. |
| Tenancy | `packages/tenancy` | `Registry` (looks up a school by slug, unseals its URL, 15 s positive / 5 s negative cache) and `PoolManager` (LRU of connection pools per school). |
| Nest kit | `packages/nest-kit` | `ApiError` with machine codes and field errors, `ZodPipe`, `ApiExceptionFilter`. |
| API client | `packages/api-client` | `createHttp` (bearer token, `X-School` header, one refresh-and-retry on 401, sign-out when refresh fails, network-error message) plus `schoolApi` and `consoleApi` typed from contracts. Tested. |
| Web UI | `packages/web-ui` | The Nest design as React: `nest.css` (verbatim from the canvas), `shell.css` (menu stickiness, dock, sheet, account menu), `blocks.css` (grid, status pills, usage bars, key-value rows, tables, option cards, support banner), `Shell`, `Sidebar`, `Dock`, `Palette` (Ctrl K), `Dialog`, `Toast`, `Field`/`SelectField`/`useShake`, `EmptyCard`, 12 illustrations, `Roll` digits, `useTheme`, `useMedia`, and the sign-in page (`login/`). |
| School API | `apps/api` | NestJS 11 on Fastify. Sign-in (password then one-time code; 5 failed tries lock for 5 minutes; demo code only in demo schools), refresh-token rotation with replay detection, students (list/filter/sort/page, summary, views, detail, create, CSV import/export, message, assign fee), attendance (day view, roll call save, reminders), fees (summary, invoices, payments with receipts, reminders), approvals (decide with undo), notices (draft → pending → published, approval rule from settings), timetable (view, loads, teacher options, patch, cover, publish with clash detection), dashboard (+shell data), settings (versioned, locks, audit, plan usage), search, audit log, health, metrics. Permission guard (`@Require`) and module guard (`@RequireModule`). 27 tests on a real PostgreSQL. |
| Console API | `apps/console-api` | Auth (password + code, sessions), schools, plans, catalog, **wizard** (drafts, review, dry run, launch), **provisioning** (blueprints + drivers `local`, `free-test`, `aws-cell`; runs with per-step logs, retry, skip optional), **actions** (suspend, resume, erase, push entitlements, run migrations, set domain, build app, backup) with **second-person approval** and typed confirmation, **releases** in waves with auto-halt and rollback, migrations view, health prober and incidents, support sessions (read-only signed token for one school), flags, billing (monthly invoices, idempotent), team, audit (filterable per school), policy (approvals, waves, halt thresholds, freeze), sandbox message inbox, build callback, demo seed on first start. 19 tests. |
| Server | `apps/server` | One process: both APIs, and (if `apps/admin/dist` and `apps/console/dist` exist) serves the admin at `/` and the console at `/console/` with SPA fallback and long caching for hashed files. |
| School admin | `apps/admin` | Pages: sign-in, dashboard, students (+drawer, add, import, message, assign fee, collect fee), timetable (week/day/list, clash fix, publish), settings (General, Modules, Audit log), attendance roll call, notices, fees, phone home, design-system page, support banner. Others show "opens in a coming release". |
| Console | `apps/console` | Fleet, school (Overview/Entitlements/Versions/Health/Audit), onboarding (list + 7-step wizard with drafts), cells, releases, migrations, mobile builds, flags, blueprints and rules, health, approvals, support, test inbox, billing, team. |
| Mobile app | `lib/` | Original demo app, plus `SchoolProfileService`: with `--dart-define=SCHOOL` and `API_BASE_URL` it fetches `/v1/brand` at start and uses the school's name and tagline. Everything else is still mock data. |
| Tooling | `tools/` | `audit-ui.mjs`, `e2e-flows.mjs`, `e2e-onboard.mjs`, `shot.mjs`, `dev-reset.sh`, `provision-demo.mjs`, plus one-time conversion scripts (section 5). |
| Delivery | `render.yaml`, `.github/workflows/ci.yml`, `mobile-build.yml`, `.node-version` | Render blueprint; CI (platform build+types+tests, Flutter analyze+test; green on GitHub); Android build workflow started by the console. |

### 2.3 How the pieces behave (the parts that are not obvious)

- **Tenant selection.** School API calls carry `X-School: <slug>`. The admin gets the slug from the URL: `/s/<slug>/...` (router basepath), or `<slug>.<VITE_BASE_DOMAIN>` if that build variable is set, or `VITE_DEFAULT_SCHOOL`. A bare host name is **not** treated as a school (that was a deployed bug, section 8.4).
- **Sign-in.** `POST /v1/auth/login` returns either `{step:'otp', challenge}` or tokens (when the school turned two-step off). The code goes to the **sandbox inbox** (console → Test inbox). Demo schools (setting `demo.mode`) also return `demoCode` so the page can offer "Type the demo code". The console never returns the code in production (`NODE_ENV=production`), so on a hosted test track the code is the owner's `DEMO_CODE` environment value.
- **Settings.** Versioned: a save sends `expectedVersion`; a stale one gets a conflict. Locked keys (set by the platform per school) are read-only in the UI and refused by the API. The admin never writes `modules.enabled` outside the plan (`closeModules` + entitlement check).
- **Roles.** Permissions are strings (`students.read`, `settings.write`...). A role template bundles them; users get roles. The UI hides or disables what a permission does not allow and the API enforces it.
- **Support sessions.** The console issues a JWT with `support: true`, the school as audience, read permissions only and 30 minutes (display says one hour max). The admin reads it from `#support=<token>`, shows a red frame and "End session", and the API refuses non-GET requests from it.
- **Provisioning.** `Blueprints.pick(target, plan)` chooses the active blueprint; `Provisioner` runs enabled steps in order, saving a log after each; a restart marks interrupted runs failed so they can be retried from the failing step. Steps are idempotent (database step reuses an existing database).
- **Releases.** A release is a version name plus waves computed from policy (`internal`, `pilot`, `rest`). Starting it rolls schools wave by wave, recording the previous version; a wave whose health breaches policy thresholds halts the release; rollback restores previous versions. On the test track "updating a school" records the version (there is no separate artifact to deploy), so the machinery is real but the effect is bookkeeping.
- **Free test track database layout.** `free-test` schools get a database on the same Postgres server as the registry (`SHARED_PG_ADMIN_URL`): the driver creates a role `school_<slug>_app` and a database `school_<slug>` and stores the sealed connection string. If `NEON_API_KEY` is set it creates a Neon project per school instead.

## 3. Design decisions and why

| Decision | Why |
| --- | --- |
| **Database per school** (not `school_id` + row-level security) | One missed filter would leak children's data between schools; per-school backup, restore, erasure and moves become trivial. Cost: a registry and a pool manager. (Plan section 6 and section 25.) |
| **TypeScript monorepo (pnpm + Turborepo), NestJS on Fastify, Drizzle, zod contracts** | One language for admin, console, API; contracts shared so a changed field breaks the build everywhere. Drizzle over Prisma: many small databases, no heavy per-database client. |
| **Hand-reviewed SQL migrations with expand/backfill/contract kinds** | Schools migrate at different times (releases in waves), so every migration must be safe while old code still runs. The migrator verifies checksums; **never edit an applied migration, add a new file**. |
| **Config in data, layered** | The owner wants to show/hide features without code. Layers make "who may change what" explicit (platform locks beat school settings). |
| **Console-driven onboarding through editable blueprints** | The owner wants onboarding and deployment to be configurable. A blueprint is data; a target picks drivers. The same wizard works on a laptop, the free track and (later) AWS. |
| **Second-person approval for risky actions; typed confirmation for erase** | Erasing or suspending a school is irreversible or disruptive; one person must not be able to do it alone. |
| **Read-only support access with a short signed token and a visible banner** | Support must see what staff see without ever being able to change data; the banner prevents forgetting. |
| **Admin and console on the "Nest" language; mobile keeps Chalk & Glass** | Owner decision. They share one stylesheet (`nest.css`) so they cannot drift. |
| **Canvas → React by converter, then hand edits** | The boards were drawn in a design tool; converting preserves markup and class names exactly (the "byte-identical" requirement) instead of re-drawing. After the first import they are normal React files. |
| **Page CSS scoped by `.pg-<page>`; shared pieces in `blocks.css`** | Board CSS reuses short class names (`.sm`, `.err`, `.big`, `.roll`), which collided when pages shared one stylesheet. Scoping per page fixed that; new pages reuse only the shared blocks. **Beware new class names**: `.roll` already exists in `nest.css` (rolling digits); a page-level `.roll` collapsed a card (renamed `.rcall`). |
| **One free web service serves everything** | Render's free tier gives one always-on-ish service; serving the SPAs from the API process means no CORS, no URLs to wire, one cold start. In production they are separate (CDN for SPAs). The console is built with Vite `base: /console/` (`CONSOLE_BASE`). |
| **Phone: a different home screen plus a dock; other pages stack** | The canvas has a phone board with a dock. `useIsPhone()` swaps the dashboard for `PhoneDashboard`; the dock and a "More" sheet replace the side menu under 900 px on every page. |
| **Menu is sticky** (`.fr{overflow:clip}`, `.sb{position:sticky}`) | On a long page the menu used to scroll away. `overflow:hidden` would break sticky; `clip` keeps the rounded frame. |
| **Settings page saves only changed keys with the version** | Prevents clobbering, and gives a precise audit entry. |
| **Seed demo school on first start** (`SEED_DEMO=true`) | A hosted test track must have something to show without anyone running a script. |
| **Console never returns the sign-in code in production** | Otherwise the code would add no security on a public host. |
| **UI checks are scripts, not screenshots by eye** | The owner does not want a debugging arc. `audit-ui.mjs` finds overflow/clipping/errors across 4 widths × 2 themes; `e2e-flows.mjs` clicks the real flows. They found real bugs (stale memo hid the search box, clipped buttons, dead layout at 360 px). Keep them green. |

## 4. The design canvas

Saved in the repository at `design/canvas/` and described in [`design/README.md`](../design/README.md): the boards, how to view them (`preview.html`), how they became React, the **deliberate differences** (mascot, pencils, dots, jars replaced; fake features removed; password field on console sign-in; disabled SSO/Passkey; account menu; thicker bars) and the owner's design rules. Read it before touching any page.

## 5. How the code was produced (so you can reason about it)

1. `tools/dc-to-tsx.mjs <Board> <page> <dir>` turned a board into `<page>.view.tsx`, `<page>.css` (scoped), `<page>.logic.txt` (the board's own script, kept as reference) and `<page>.aside.txt` (the board's menu, replaced by the shared `Sidebar`). `tools/convert-all.sh` lists what was converted. **Do not re-run it over edited views.**
2. `tools/edit-*.py` are the one-time scripts that edited converted views (real values, working controls, extra states). They assert every replacement so they fail loudly if the view drifted. They are kept as a record; they are not part of any build.
3. Each page has a `<Page>Page.tsx` hook that owns data and state and passes a values object to the view. Pages without a board use `app/Page.tsx` (admin and console each have one) and the shared blocks.
4. Data comes from TanStack Query with query keys like `['students', ...]`; mutations invalidate by key prefix (`predicate`), so a payment refreshes the fees page, the student list and the dashboard together.
5. Every write that can fail on the server shows its message through `Field` errors (red, vibrating) or a toast; every list has an `EmptyCard` state; every page has loading and error states.

## 6. Running, checking, debugging

Commands are in the README. Practical notes learned the hard way:

- `bash tools/dev-reset.sh` **hangs in the foreground of some shells**: run it in the background and poll `/tmp/reset.log` for "Greenfield is live".
- The dev server (`tsx src/main.ts`) imports `@edunest/api` and `@edunest/console-api` **from their `dist/`**. After changing either, run `pnpm --filter @edunest/api build` (or `console-api`) and restart, or you are testing old code.
- Editing frontend files while `audit-ui.mjs` runs triggers Vite hot reload and produces false "hook order" errors. Finish edits, then audit.
- `e2e-flows.mjs` changes demo data (approves, publishes, adds a student). Re-run `dev-reset.sh` before the next full run; `ONLY="text"` runs matching flows.
- Git Bash rewrites values starting with `/` (`CONSOLE_BASE=/console/` becomes a Windows path): prefix `MSYS_NO_PATHCONV=1`. Large quote-heavy heredocs in some tool shells fail: write files with an editor tool.
- Running a second server against the **same dev PostgreSQL** with a new registry and `SEED_DEMO=true` re-creates the role `school_greenfield_app` with a new password and breaks the local demo school. Use `dev-reset.sh` afterwards.
- Vite dev: admin proxies `/v1` to port 4000; console proxies `/console` and `/v1`.
- The Flutter SDK on the owner's machine is `D:\dev\flutter` (`docs/dev-environment.md`).

## 7. Testing strategy

- Unit: contracts, config engine (layers, locks, contrast), security, db (migrator, seed invariants), api-client (refresh, sign-out), web-ui helpers, registry.
- API: `apps/api/test/api.test.ts` (27) and `apps/console-api/test` (19) run against a real PostgreSQL started by the tests; schools are really provisioned and signed in to.
- UI audit and flows as above; CI runs build, typecheck, tests and Flutter analyze/test on every push (`.github/workflows/ci.yml`; the browser scripts need running servers, so they are run by hand, ideally before every deploy).
- **Not covered:** pixel comparison against the canvas (pages show real data, boards show sample data), real devices, iOS, screen readers beyond labels and roles, load.

## 8. The deployment

### 8.1 What runs

One Render web service `edunest` (free, Singapore, auto-deploy from the branch it was created from) runs `node apps/server/dist/main.js`. Build command (in `render.yaml`): `corepack enable && pnpm install --frozen-lockfile --prod=false && CONSOLE_BASE=/console/ pnpm exec turbo run build --concurrency=2`. Neon (free) holds the registry and each school's database.

### 8.2 Environment variables (set in Render → Environment)

| Variable | Meaning |
| --- | --- |
| `REGISTRY_DATABASE_URL`, `SHARED_PG_ADMIN_URL` | The Neon **direct** (non-pooled) connection string, for both. |
| `SECRETS_KEY` | Seals school connection strings. **Never change it**: every school becomes unreadable. |
| `JWT_SECRET` | Signs tokens. Changing it signs everyone out. |
| `BOOTSTRAP_EMAIL`, `BOOTSTRAP_PASSWORD` | The first console super admin (created only when no console user exists). Changing the password later does nothing; use the console's Team page. |
| `DEMO_CODE` | The six-digit second step for console sign-in. |
| `SEED_DEMO=true` | Creates the Greenfield demo school if missing. |
| `BUILD_CALLBACK_TOKEN`, `GITHUB_TOKEN`, `GITHUB_REPO`, `GITHUB_BRANCH` | Android builds (optional). |
| `RENDER_EXTERNAL_URL` | Provided by Render; used as the admin/API base address. |

### 8.3 Free-tier behaviour

Sleeps after 15 minutes idle; the first request takes about a minute (the pages show skeletons meanwhile). Neon free: 0.5 GB. Anyone with the address can open the demo school (public demo credentials). A restart interrupts a school setup in progress; the console shows it failed and offers Retry.

### 8.4 The first-deploy black screen (fixed) and what it teaches

Two independent bugs: (1) `CONSOLE_BASE` never reached the console build because **Turborepo strips environment variables it is not told about**; the console's assets were requested from `/assets/` (admin's folder) and 404'd, leaving a blank page. `turbo.json` now lists `CONSOLE_BASE` and `VITE_*` in the build task's `env`. (2) The admin treated the first part of any host name with three parts (`edunest-0c6x.onrender.com`) as a school address, asked for school `edunest-0c6x`, got "not found", and showed that message in black on the dark page. Host-based schools now only count under `VITE_BASE_DOMAIN`, and the not-found screen is a styled card. Lesson: test the **production build served the way production serves it** (`node apps/server/dist/main.js`, assets under the real base) and with a host name that is not `localhost`/`127.0.0.1`. `tools/audit-ui.mjs` can target it with `API=… ADMIN=… CONSOLE=…`.

### 8.5 Redeploying and troubleshooting

Push to the branch Render tracks, or Render → service → Manual Deploy → Deploy latest commit. Logs: Render → Logs. A health check hits `/health`. If the console shows a blank page, check `index.html`'s asset paths start with `/console/`. If sign-in says the school was not found, check the address is `/s/<slug>`. If provisioning a school fails at the database step, check `SHARED_PG_ADMIN_URL` is the direct string and its role can `CREATE ROLE` and `CREATE DATABASE`.

## 9. What is left, why, and how to do it

Status against the plan's build order (section 24): **0** foundations — partial (monorepo, CI done; no Dart workspace/Melos, no `apps/mobile` move, no ADR folder, no per-surface `DESIGN.md`/`PRODUCT.md`, no OpenTofu/EKS/Argo). **1** platform core — mostly done for the test track (tenancy, identity with OTP+password, permissions, config engine, audit, provisioning with three drivers); missing passkeys/TOTP, files/jobs/realtime/renderer, the 500-school synthetic fleet and tenancy property tests. **2** vertical slice attendance — admin side done; app not on the real API; no push. **3** people and academics — partly (students, timetable; no admissions, staff, imports beyond students CSV, subjects/years UI, homework, exams, report cards, certificates, calendar). **4** finance — partly (invoices, payments, receipts, reminders; no Razorpay, autopay, concessions/refunds flow UI, late fees, reconciliation, Tally). **5** communication — partly (notices with approvals; no events, chat, push/SMS/WhatsApp/email providers, delivery log). **6** operations — not started. **7** admin experience complete — not started beyond the shell and a few pages. **8** console complete — mostly done (everything listed in 2.2); missing cells creation, move-school, blueprint/target *creation* UI beyond toggling steps, compliance desk, status pages, catalog update offers. **9** mobile distribution — workflow only. **10** production readiness — not started.

Why not done: the plan describes a production system for 500 schools over eleven steps; the owner asked for the whole plan, but a free, working, tested slice that all parts share had to come first, and each remaining item is a feature-sized project (a backend module, its admin screens and, for most, the app screens). Items that need the owner's accounts or paid services (AWS, Razorpay, SMS/WhatsApp providers, Apple/Google store accounts) cannot be done without them.

### 9.1 Add an admin page whose backend exists or is small (homework, exams, staff, admissions, invoices, reports, messages, events)

1. **Contracts first** (`packages/contracts/src/school.ts`): request/response types; permission keys in `permissions.ts`.
2. **Migration:** add a new SQL file under `packages/db/migrations/school/` (kind header; never edit applied files) and update `packages/db/src/school/schema.ts`. Extend the seed in `packages/db/src/seed/greenfield.ts` so the demo school has data for every weekday and the page is never empty-by-accident.
3. **Service + controller** in `apps/api/src/school/` following `approvals.service.ts`/`school.controllers.ts`: `@RequireModule('<module>')`, `@Require('<permission>')`, zod pipe, audit entries for writes. Register in `app.module.ts`. Add API tests in `apps/api/test/api.test.ts`.
4. **api-client** (`packages/api-client/src/school.ts`), then the page: copy `apps/admin/src/pages/fees/FeesPage.tsx` as the pattern (it uses `Page`, shared blocks, `EmptyCard`, toasts, query invalidation). Change the `to` in `apps/admin/src/app/nav.ts` from `/p/<name>` to the real route and register it in `router.tsx`. Add routes to `tools/audit-ui.mjs` and a flow to `tools/e2e-flows.mjs`.
5. There is no board for these pages: compose from approved pieces, then ask the owner to review the look (they have **not** reviewed attendance, fees, notices or any console page without a board).
6. Real-time "left to do" numbers (menu badges) come from `DashboardService.shell`; extend it when a module has a count.

### 9.2 Settings tabs (App layout, Roles and access, Notifications, Message templates, Privacy and consent)

Each needs data: layouts and templates are config documents (plan section 12.4/13); roles matrix needs `roles`/`user_roles` endpoints (tables exist). Pattern: add keys to `SchoolSettingsSchema` in `packages/contracts/src/config.ts` (defaults there are the platform defaults), expose them in the Settings page's tab switch (`SettingsPage.tsx`, `extra`), keep saving through `settings.patch`. Roles: new `roles` controller listing roles/permissions with a diff before save.

### 9.3 Make the mobile app use real data (the biggest gap)

Today only name/tagline are live. Steps:

1. **Backend family API.** The school API is staff-oriented. Add endpoints for guardians and students (child list, attendance, timetable, homework, fees with payment, notices, events, notifications) under `/v1/me/...`, scoped by the signed-in guardian's children (`student_guardians`) or the student's own record. Sign-in already supports `guardian` and `student` user kinds; the seed creates staff only, so seed guardian and student users for the demo school (password `demo123`-style demo accounts, OTP via sandbox).
2. **Flutter data layer.** `lib/data/repositories/*` already has `Remote*Repository` classes calling paths from `docs/API_CONTRACT.md`. Either make the new endpoints match that contract, or rewrite the remote repositories against the new endpoints. Implement `lib/core/network/api_client.dart` (token, `X-School`, refresh), keep `AppConfig.useMockData` as the switch, and set `useMockData=false` automatically when `AppConfig.live`.
3. **Config at start.** Extend `SchoolProfileService` to call `/v1/config` after sign-in (modules, vocabulary) and hide features whose module is off.
4. **Sign-in.** Replace the demo cards with real password + OTP when live; keep the demo cards for mock mode.
5. **Then the plan's section 19:** move `lib/` to `apps/mobile` with the TS workspaces (Melos for Dart packages), offline store, deep links, push categories, the EduNest picker app, build-profile injection from the console (the `build-profile` provisioning step currently only records), fastlane per school, Shorebird.
6. Verify with `tool/verify.sh`, `flutter test`, and an emulator/phone (liquid glass only renders on a device).

### 9.4 Hosting and production (plan sections 5–11, 18–22)

Everything here needs paid or owner-owned services: AWS accounts and OpenTofu for cells (EKS, RDS/Aurora or per-cell Postgres, Valkey, S3, KMS), Argo CD, Cloudflare for domains (the `domain` step currently records the address; implement the Cloudflare/Route53 driver and certificate validation in `drivers.ts`), the **GitHub App** for build-profile commits, Razorpay (billing and school fee payments), SMS (DLT), WhatsApp, email and push providers (replace the `Messenger` sandbox in `apps/api/src/school/support.ts` with providers behind the same interface), Sentry/Grafana. The `aws-cell` driver exists and needs `CELL_<KEY>_ADMIN_URL` per cell.

### 9.5 Security hardening before real schools

- Admin/console tokens live in `localStorage`. The plan (section 17) specifies httpOnly SameSite cookies with CSRF tokens, a strict CSP with nonces, Trusted Types, SRI and Permissions-Policy. Implement in `apps/server` (cookie issue and CSRF check) and the two `client.ts` files; add CSP headers in `static.ts`.
- Passkeys and TOTP; SSO (the sign-in buttons are disabled placeholders); password reset flow ("Forgot it?" currently tells the person to ask the principal/EduNest); rate limiting per IP (lockout exists per account); DPDP consent and data-export/erasure flows; penetration test.
- Remove the public demo credentials from any environment with real data; keep `DEMO_CODE`/`SEED_DEMO` off.

### 9.6 Console gaps

Create a cell (UI + API; today cells appear at first start), move a school between cells, add/clone blueprints and targets (today you can toggle optional steps and save a new version), edit waves in policy, flag evaluation inside the API/app (flags are stored and shown; nothing reads them yet), status pages, compliance desk (erasure requests, DPDP), catalog "update available" offers (plan 12.4), real backups (`backup.take` works only on Neon), release "deployment" that does something beyond recording versions (on AWS it would roll an image), invoices via Razorpay and GST documents.

### 9.7 Quality items

- Run the owner's review on every page that has no board; adjust spacing/wording on request.
- A pixel-diff harness against `design/canvas` with matching sample data (Playwright + `pixelmatch`, both installed).
- Screen-reader pass; keyboard-only pass of the wizard and dialogs; Hindi/Marathi strings for admin and console (the sign-in language switch only stores the choice; admin text is English).
- Per-surface `PRODUCT.md`/`DESIGN.md` (plan step 0).
- Small known items: the fleet table shows `0.0.0` as a school's version until a release has run (set `api_version` to the server's version at provisioning); the Greenfield seed's homework "handed in" times can be later than the latest school day; the console's `Alerts` bell only links to Approvals; "Cells → Manage" has nothing to manage yet; `package` unit tests for `apps/admin` and `apps/console` do not exist (the browser scripts cover them).

## 10. Things that went wrong (so they are not repeated)

- Environment variables vanished in Turborepo (8.4). Always declare build-time env in `turbo.json`.
- A hook-based page cached its values in `useMemo` without the menu/search state in its dependencies, so Ctrl K never opened on the dashboard. When a page builds a values object in `useMemo`, include every piece of shared chrome state.
- Class-name collisions between pages and `nest.css` (`.roll`, `.sm`, `.err`, `.big`, `.act`, `.sw`) collapsed layouts. Scope page CSS; check new class names with a search in `nest.css`.
- Case-insensitive file systems: `roll.ts` vs `Roll.tsx` collided on Windows (renamed `digits.ts`).
- Dev tooling: see section 6.
- A flaky assumption in tests: the demo code only exists for demo schools. A real new school's code is in the test inbox (`e2e-onboard.mjs` reads it from there).

## 11. If you only have an hour

1. `README.md` → run locally.
2. `node tools/audit-ui.mjs --quick` and `node tools/e2e-flows.mjs` to see the baseline is green.
3. Pick a section 9.1 page (Attendance shows the shape; Homework is the most valuable next, then Exams and Staff), follow the steps, keep the audit and flows green, push, and check the Render deploy.
