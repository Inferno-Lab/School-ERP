# EduNest platform: monorepo, admin panel, console and configuration — design

Status: draft for review · 2026-10-10
Scope: planning only. Nothing in this document has been built yet.

---

## 1. Intent

EduNest today is one Flutter app that reads mock JSON. It is becoming a product that many schools buy. Each school gets:

- its **own mobile app**, published in the stores under the school's name, from the school's own Apple and Google developer accounts;
- its **own admin panel**, where its staff run the school;
- its **own backend and data**, completely separate from every other school.

We (the EduNest developers) need one **console** to create schools, set what each one can use, push updates, and watch that every school is healthy.

The goal is that day-to-day change happens through **configuration rather than code**. Adding a school, hiding a module, renaming a tab, changing grading rules or turning on a feature should be a setting change, not a release. And everything (apps, admin, console, backend, infra) lives in **this one repo**.

## 2. Goals, non-goals, anti-goals

**Goals**
1. One repo, one source of truth for data shapes, permissions and configuration, shared by the app, admin, console and backend.
2. Hard isolation: no school's data, credentials, users or files are ever reachable from another school's stack.
3. Onboarding a new school is a guided flow in the console, not an engineering project (target: under a day of human time, most of it store paperwork).
4. Most of the app is configurable per school: modules, navigation, home layout, terminology, branding, academic rules, fees rules, notifications, custom fields.
5. Role-based access with roles the school can define, plus a locked super-admin tier for us.
6. Ship one version of the code to all schools, with staged rollouts and rollback.

**Non-goals (for the first release)**
- Fully server-driven UI, where the server describes whole screens. Configuration chooses and arranges *built* blocks; it does not invent new screens.
- A marketplace or plugin system that lets third parties add code.
- Running schools on customer-owned clouds.
- Billing and invoicing schools inside the console (a hook is left for it).

**Anti-goals (this would be failure even if it "works")**
- Per-school forks or `if (school == 'greenfield')` branches anywhere in the code.
- A config system so loose that a typo in the console can crash every school's app (all config must be schema-validated, versioned and reversible).
- A shared database or shared login across schools "just for convenience".
- An admin panel that only developers can operate.
- Glass, design or feature work that only looks right in Chromium. The Flutter app is the product. The canvas demos were only previews.

## 3. Decisions so far

| Decision | Made by |
| --- | --- |
| Many schools, each with its own app and admin panel | You |
| Nothing shared between schools at runtime; deployments may share a server | You |
| Each school publishes under its own Apple and Google developer accounts | You |
| A developer console to manage everything | You |
| Stack choice delegated to me | You |
| Stack (below) | My call |
| "Instance per school" (separate stack and database), not one shared multi-tenant database | Follows from your "nothing shared" rule |

### Stack (my call)

| Part | Choice | Why |
| --- | --- | --- |
| Mobile app | **Flutter** (existing) | Already built. One codebase for Android and iOS, white-labelled per school at build time. |
| Backend | **TypeScript, NestJS on Node 22 LTS (Fastify adapter)** | Its module, guard and dependency-injection structure suits pluggable modules and RBAC. It has the largest ecosystem and hiring pool, and is mature for auth, queues and file handling. |
| Database | **PostgreSQL 16+**, one database per school | Relational school data (classes, fees, marks), strong constraints, row history, JSONB for configuration. |
| ORM / migrations | **Prisma** | Typed client and reviewed SQL migrations. `@casl/prisma` turns permission rules into query filters. |
| Cache / jobs | **Redis + BullMQ**, one Redis per school | Reminders, notifications, report generation, imports. |
| Files | **S3-compatible storage**, one bucket per school | Homework scans, gallery, receipts. MinIO when self-hosted, or any S3 provider. |
| Admin panel + console | **React + TypeScript, Vite, TanStack Router/Query/Table, shadcn/ui (Radix)** | Data-heavy screens (tables, filters, bulk edits, forms) are much stronger on web React than on Flutter web. Both apps share one UI package. |
| Authorization | **CASL** abilities built from roles stored in the database | Roles become data, rules can carry conditions ("own classes only"), and the same rules filter database queries. |
| Contracts | **Zod schemas → OpenAPI 3.1 + JSON Schema → generated TS and Dart clients** | One definition; the app, admin and backend can't drift apart. |
| Monorepo | **pnpm workspaces + Turborepo** (TS), **Dart pub workspaces + Melos** (Dart), one root entry point | Each language keeps its native tooling. Turborepo can't manage Dart and Melos can't manage TS, so thin wrappers let Turborepo run Dart tasks too (section 5). |
| Delivery | Docker images, built once per commit; per-school deploys of the same image | One version, many configurations. |
| Mobile CI | GitHub Actions matrix + fastlane, uploading with each school's store API keys | Each school stays the account holder (store policy). |

Considered and rejected:
- **All-Dart (Serverpod + Flutter web admin).** It shares models for free, but Serverpod's ecosystem is far smaller and Flutter web is weak for admin tables and forms. The generated-contract approach gives us most of the sharing anyway.
- **One shared multi-tenant database with row-level security.** It's cheaper to run, but it breaks your "nothing shared" rule.
- **Nx as the only tool.** It has no first-class Dart support, and is heavier than we need at this size.

## 4. System overview

```
                          ┌──────────────────────────────────────────┐
                          │  CONTROL PLANE (ours)                    │
                          │  apps/console  ──►  apps/console-api     │
                          │  registry · plans · config defaults ·    │
                          │  releases · builds · health · support    │
                          │  own Postgres: metadata only, no PII     │
                          └───────────────┬──────────────────────────┘
                     signed management API│ (per-school keys, outbound only)
        ┌─────────────────────────────────┼─────────────────────────────────┐
        ▼                                 ▼                                 ▼
┌──────────────────┐            ┌──────────────────┐             ┌──────────────────┐
│ SCHOOL STACK: GIS│            │ SCHOOL STACK: SRA│             │ SCHOOL STACK: …  │
│ api (NestJS)     │            │ api (NestJS)     │             │                  │
│ admin (static)   │            │ admin (static)   │             │                  │
│ Postgres db_gis  │            │ Postgres db_sra  │             │                  │
│ Redis · bucket   │            │ Redis · bucket   │             │                  │
└───────▲──────────┘            └───────▲──────────┘             └──────────────────┘
        │ HTTPS gis.edunest.app         │ HTTPS sra.edunest.app
 ┌──────┴───────┐                ┌──────┴───────┐
 │ "Greenfield" │                │ "Sunrise"    │   ← separate store apps,
 │  app (iOS/   │                │  app         │     separate developer accounts
 │  Android)    │                │              │
 └──────────────┘                └──────────────┘
```

- **School stack (data plane).** One per school: the API, the admin panel (static files served by the same reverse proxy), its own database, Redis, bucket, secrets and domain. It has no knowledge of other schools.
- **Control plane.** Our console and its API. It stores *about* schools (name, domain, plan, versions, health, build status), never *their* data (students, marks, fees). It talks to each school stack only through a small signed management API.
- Several school stacks can share one server as separate containers. Separate databases, users, Redis instances, buckets and secrets keep them isolated. A large school can move to its own server by changing where its stack is deployed, not the code.

## 5. Monorepo

### 5.1 Layout

```
edunest/
├─ apps/
│  ├─ mobile/                 Flutter app (today's lib/ moves here)
│  ├─ api/                    NestJS school backend (one image, deployed per school)
│  ├─ admin/                  React admin panel (per school, static build)
│  ├─ console/                React console (ours)
│  └─ console-api/            NestJS control-plane API
├─ packages/
│  ├─ contracts/              Zod schemas: API DTOs, app-config schema, permission catalog, events
│  ├─ module-manifests/       One manifest per product module (fees, homework, …), see §6.2
│  ├─ api-client-ts/          generated TS client (admin, console)
│  ├─ ui-web/                 shared React components, tokens, data table, form builder
│  ├─ config-tools-ts/        merge, resolve and validate config layers (used by api, admin, console)
│  ├─ authz/                  CASL ability builder shared by api, admin and console-api
│  ├─ eslint-config/, tsconfig/  shared lint and TS settings
│  └─ dart/
│     ├─ edunest_api/         generated Dart client + models (freezed/json_serializable)
│     ├─ edunest_core/        config runtime, module registry, auth, networking, storage
│     ├─ edunest_ui/          Chalk & Glass design system + liquid-glass shader
│     └─ features/            one package per module: fees/, homework/, attendance/, …
├─ schools/                   per-school *public* build profiles (no secrets), see §11
│  └─ greenfield/school.yaml, icon.png, splash.png, store/ (listing text, screenshots)
├─ infra/
│  ├─ docker/                 Dockerfiles, compose for local dev
│  ├─ deploy/                 per-host stack templates (Compose + Caddy) → Helm chart later
│  └─ terraform/              servers, DNS, buckets (OpenTofu)
├─ tools/                     codegen scripts, school scaffolder, mock-data generator (existing tool/)
├─ docs/                      specs, ADRs (docs/adr/NNNN-*.md), runbooks
├─ .github/workflows/         CI, release, mobile build matrix
├─ package.json  pnpm-workspace.yaml  turbo.json
├─ pubspec.yaml               Dart pub workspace root (lists every Dart package)
└─ melos.yaml                 Dart scripts (analyze, test, format, codegen)
```

### 5.2 Tooling rules

- **Root entry point.** `pnpm turbo run <task>` runs lint, test, build and codegen across the whole repo. Each Dart package has a tiny `package.json` whose scripts call `dart`/`flutter`/`melos`, so Turborepo caches and orders Dart tasks as well. Developers who only touch Flutter can still use `melos run …` directly.
- **Affected-only CI.** Turborepo's dependency graph plus path filters mean a change to `apps/admin` doesn't rebuild the Flutter app, while a change to `packages/contracts` rebuilds everything that depends on it.
- **Remote cache.** Turborepo remote cache (self-hosted or Vercel) so CI and laptops reuse build outputs.
- **One version policy.** One version of each third-party dependency across the repo: pnpm catalogs for TS, and the pub workspace's single resolution for Dart. Renovate keeps them current in grouped PRs.
- **Boundaries enforced, not hoped for.**
  - Apps may import packages; packages never import apps; apps never import each other.
  - TS: `eslint-plugin-boundaries` and package `exports` fields, with no deep imports.
  - Dart: `import_lint` / `custom_lint` rules so `features/*` can't import each other, only `edunest_core` and `edunest_ui`.
- **Generated code** goes in `generated/` folders, is marked as generated, is never hand-edited, and is regenerated and checked for diffs in CI.
- **Conventional commits + Changesets** for versioning the deployable apps. **CODEOWNERS** per folder. **ADRs** for every decision that changes this document.
- Node 22 LTS, pnpm 9+, Dart ≥ 3.6 / Flutter ≥ 3.27 (pub workspaces), pinned via `.nvmrc`, `packageManager` and `.fvmrc`.

### 5.3 Contracts and code generation

```
packages/contracts (Zod, TS)
   ├─► OpenAPI 3.1 (api.yaml)       ──► api-client-ts       (admin, console)
   │                                └─► edunest_api (Dart)  (mobile)
   ├─► JSON Schema: app-config.json ──► Dart config models + validation in mobile
   └─► permission catalog (JSON)    ──► authz (TS) + permission keys (Dart)
```

- NestJS controllers take and return the Zod schemas (`nestjs-zod`), so validation, the OpenAPI document and the clients all come from the same source.
- A CI job fails the build if the generated clients are stale or the OpenAPI diff is a breaking change without a version bump.
- The existing `docs/API_CONTRACT.md` and `MOCK_SCHEMA.md` become the starting point for these schemas, then are replaced by the generated reference.

## 6. The configuration system

This is the heart of the plan.

### 6.1 Layers and how they combine

Configuration is resolved in layers, lowest to highest priority. A higher layer can override a lower one only where the lower layer allows it.

| # | Layer | Who sets it | Where it lives | Examples |
| --- | --- | --- | --- | --- |
| 0 | **Build profile** | Us, per school | `schools/<slug>/school.yaml` + CI secrets | bundle ID, app name, icon, splash, API URL, Firebase project. Needs a new build to change. |
| 1 | **Platform defaults** | Code | `packages/module-manifests` | Every module, its default settings, permissions, nav entries |
| 2 | **Plan / entitlements** | Super admins (console) | Console, pushed to the school as a signed document | Which modules this school has paid for, limits (students, storage), allowed features |
| 3 | **Platform overrides + locks** | Super admins (console) | Same signed document | Forced values and *locks*: "school may change X", "X is fixed" |
| 4 | **School settings** | School admins (admin panel) | School DB | Turn allowed modules on/off, terminology, home layout, grading scale, fee rules, branding colours |
| 5 | **Audience rules** | School admins | School DB | Show a module or section only to some roles, classes or app versions; percentage rollout |
| 6 | **User preferences** | Each user (app) | Device + school DB | Theme, text size, language, notification choices |

- The school API resolves layers 1–5 into one **effective config document** per audience (role + app version).
- The app downloads it from `GET /v1/app-config` (ETag + version, cached on device so the app starts offline). Admin uses the same resolver to preview what a parent or teacher will see.
- The schema in `packages/contracts` validates every layer on write and the result on read. An invalid document is never published.

### 6.2 Module manifests (the unit of "turn things on and off")

Every product area is a **module**: attendance, homework, timetable, results, fees, notices, events, chat, transport, library, gallery, leave, notifications, search, scan-and-submit, and so on. Each one has a manifest in code:

```ts
defineModule({
  key: 'fees',
  name: 'Fees',
  dependsOn: ['people'],
  permissions: ['fees.structure.manage', 'fees.invoice.read', 'fees.invoice.create',
                'fees.payment.record', 'fees.concession.approve', 'fees.report.read'],
  settings: z.object({            // what a school can configure, with defaults
    reminderDaysBefore: z.number().int().min(0).max(30).default(3),
    allowPartialPayment: z.boolean().default(false),
    paymentMethods: z.array(z.enum(['upi','card','netbanking','cash','cheque'])).default(['upi','card','netbanking']),
    receiptPrefix: z.string().max(12).default('RCPT'),
  }),
  app: { routes: ['/fees', '/fees/pay', '/fees/receipt/:id'], navEntry: { icon: 'wallet', label: 'nav.fees' },
         homeSections: ['fees.dueBanner'] },
  admin: { menu: { group: 'Finance', icon: 'wallet' } },
  locks: { paymentMethods: 'platform' },    // only super admins may change
});
```

From these manifests:

- The **backend** registers each module's routes behind a module guard. A disabled module returns `404 module_disabled`, and its background jobs don't run.
- The **admin panel** builds its menu, settings forms (auto-generated from the Zod schema, with custom widgets where needed) and permission matrix.
- The **app** registers each feature package with a `ModuleRegistry`. At start-up, and whenever config changes, the shell builds the dock tabs, routes, home sections and search sources only from enabled modules. A deep link to a disabled module shows a friendly "not available at your school" page instead of crashing.
- The **console** shows the full catalog with toggles and locks.

Adding a new module is a code change (it's new functionality). Turning it on for a school, ordering it, renaming it or restricting it is configuration.

### 6.3 What schools and super admins can configure (first release)

- **Modules:** on/off (within the plan), order, and visible-to (roles, classes).
- **Navigation:** which 4–5 modules sit in the dock per role, labels and icons from an approved set, and what sits under "More".
- **Home screen:** which sections appear (Day Ribbon, Due stack, attendance tile, next exam, notices, both-children strip, bus ETA) and in what order, per role.
- **Terminology:** "Class/Grade/Standard", "Section/Division", "Term/Semester", "Roll number/Admission number", in each enabled language.
- **Branding (runtime):** primary and accent colours checked for contrast, logo, school name, subject pigments, holiday calendar colours. (Icon, app name and bundle ID are build-time.)
- **Academic structure:** academic years, terms, classes, sections, subjects, periods and bell timings, grading scales (marks → grade), pass rules, exam types.
- **Attendance:** late cut-off time, half-day rules, who can mark, whether parents see arrival time.
- **Fees:** structures, instalments, late fees, concessions, payment methods (platform-locked), reminders.
- **Communication:** who can message whom, office hours, quick replies, notice categories, broadcast approval workflow.
- **Notifications:** templates per event, channels (push / SMS / email / WhatsApp later), quiet hours.
- **Custom fields:** extra fields on students, guardians and staff (text, number, date, choice), rendered by a schema-driven form in the admin and the app profile.
- **Languages:** which languages are enabled, the default language, and overrides for specific strings.
- **Legal and contact:** privacy policy, terms, support contacts and links.
- **Feature flags:** on/off, by role, by class, by app version, or by percentage, for gradual rollouts and kill switches.

### 6.4 Making changes safe

- **Draft → preview → publish.** Every change to config starts as a draft. The admin shows a live device preview for a chosen role ("see as a parent of 8 A"). Publishing creates an immutable version.
- **Version history and one-click rollback**, with a diff view, author and reason.
- **Validation:** schema checks, dependency checks (you can't disable `people` while `fees` is on), contrast checks for colours, and limits from the plan.
- **Min app version gates:** a config can require a minimum app version. Older apps get the last compatible config plus a gentle "please update" prompt. A hard force-update is a separate, super-admin-only switch.
- **Kill switches:** super admins can disable a module or flag instantly in one school or all schools, from the console.
- **Audit log** of every config change, role change and sensitive action, viewable in the admin (for the school) and the console (for us, metadata only).

### 6.5 Flags: build vs buy

We start **in-house**: flags are just another config layer with audience rules, served in the same document. That keeps "nothing shared" intact and avoids running a flag server per school. The rule format follows OpenFeature's evaluation model, so we can later plug in self-hosted Unleash or Flagsmith, which both have Flutter SDKs, if experiments become important. The OpenFeature Dart SDKs are still beta, so we don't depend on them now.

## 7. Roles and access (RBAC with conditions)

### 7.1 Who

| Tier | Where they work | Examples |
| --- | --- | --- |
| **Platform** (us) | Console; break-glass access to a school's admin | Super admin, support engineer, release manager, read-only auditor |
| **School staff** | Admin panel (+ teacher tools in the app) | Principal, office admin, accountant, class teacher, subject teacher, transport manager, librarian, receptionist |
| **Families and students** | Mobile app | Parent/guardian, student |

### 7.2 Model

- **Permissions** are defined in code by module manifests (`fees.invoice.create`, `attendance.mark`, `config.home.edit`, `roles.manage`). They form a catalog generated into TS and Dart.
- **Roles** are data in each school's database: a name plus a set of permissions, each with optional **conditions** from an approved list: `scope: own_classes | own_subjects | own_children | self | all`, `class in […]`, `amount <= …`. Conditions are stored as structured fields, never as free-form code.
- **System role templates** ship with every school: Principal, Office admin, Accountant, Class teacher, Subject teacher, Transport manager, Librarian, Parent, Student. Schools copy them or create their own. Templates are versioned, so new permissions can be added to templates without overwriting a school's edits.
- **Assignments:** a user can hold several roles. A teacher can be "Class teacher of 8 A" and "Subject teacher, Maths for 6 A, 7 B, 9 C" at once.
- **Super-admin-only permissions** (module entitlements, platform locks, integrations, data export of the whole school) can never be granted from the school admin, whatever role a school builds.
- **Enforcement:**
  - **API:** a NestJS guard checks the permission declared on each route. CASL conditions also become Prisma `where` filters through `@casl/prisma`, so list endpoints only return what the user may see.
  - **UI:** the admin and app get the user's resolved abilities from `/v1/me` and hide what the user can't use, but the API is always the authority.
- **Sensitive actions** (refunds, deleting students, publishing config, role changes) need **2FA** for staff accounts and can be put behind a two-person approval workflow per school.
- **Break-glass support access:** our support engineers can enter a school's admin only after the console grants a time-boxed, reason-logged session. The school's audit log shows it, and the school can opt to require approval.

## 8. School backend (`apps/api`)

- **Shape:** a modular monolith. One NestJS module per product module, matching the manifests, plus core modules: auth, people, config, authz, files, notifications, jobs, audit, search, imports/exports, platform-management.
- **Auth:**
  - Email + password, phone OTP (SMS provider pluggable), and optional Google sign-in for staff.
  - Short-lived access JWT and a rotating refresh token, with device sessions listed and revocable.
  - Parents can be linked to several children.
- **Data:** Prisma schema per module, one migration history. Soft-delete with retention rules. Timestamps in UTC. Money as integer paise.
- **Files:** pre-signed uploads straight to the school's bucket, virus scan in a job, image variants for the gallery, and PDF receipts and report cards generated in jobs.
- **Jobs (BullMQ):** reminders, scheduled notices, report generation, bulk imports, push fan-out, nightly backups check.
- **Push notifications:** Firebase Cloud Messaging with the school's own Firebase project (credentials in that school's secrets).
- **Search:** Postgres full-text search (with `pg_trgm`) across homework, notices, people and events, filtered by permission.
- **Platform management endpoints** (`/_platform/v1/*`) accept only requests signed with the console's key for this school. They cover: receive entitlements and locks, report health and version, run migrations, create the first admin, and start or stop break-glass sessions. Nothing here can read student data in bulk.
- **Observability:** OpenTelemetry traces, metrics and logs, labelled with the school slug, sent to a central Grafana stack and Sentry. Personal data is scrubbed before anything leaves the school stack.

## 9. Admin panel (`apps/admin`)

Built from the module manifests, so its menu shows only enabled modules and permitted screens.

**Core areas**
- **Dashboard:** today's attendance, fees collected vs due, pending approvals, homework waiting for grades, and system notices from us.
- **People:** students, guardians, staff; admissions; ID cards; bulk import from CSV/Excel with a preview that flags errors before anything is saved; merge duplicates.
- **Academics:** years, terms, classes and sections, subjects, a timetable builder with clash detection (teacher double-booked, room clash), exams, mark sheets, grading scales, report cards.
- **Attendance:** daily register, corrections with reason, absence reports, explain-absence requests from parents.
- **Homework and grading:** what's assigned, submissions, grading queue.
- **Fees:** structures, instalments, invoices, payments (online and counter), receipts, concessions, defaulters, reminders, reconciliation export.
- **Communication:** notices (draft → approve → publish, with a phone-frame preview), events and RSVPs, chat moderation and office inbox, broadcast notifications.
- **Transport, library, gallery, leave approvals.**
- **Reports:** saved reports and exports, scheduled email of reports.
- **Settings:** school profile, roles and users, app configuration (only what locks allow), languages, notification templates, integrations allowed by the plan, audit log.

**Ideas worth adding** (each one cuts real staff time)
- **Academic-year rollover wizard:** promote students, archive the old year, carry fee dues forward. This is one of the most painful days of the year in most schools.
- **"See as" preview:** show the app exactly as a chosen parent, student or teacher would see it, without logging in as them.
- **Onboarding checklist** for a new school: classes, subjects, timetable, fee structure, import students, invite staff, publish app config. Progress shows in our console too.
- **Bulk actions everywhere,** with undo for 10 seconds.
- **Saved filters and column layouts** per user on every table.

## 10. Console (`apps/console` + `apps/console-api`)

Ours only. It holds metadata, never school data.

- **School registry:** slug, legal name, domain, region, contacts, plan, status (onboarding, live, suspended, archived), current versions (API, admin, app per store), health.
- **Provisioning wizard:**
  1. Create the database and its user.
  2. Create the bucket, Redis and secrets.
  3. Deploy the stack, set up DNS and TLS.
  4. Run migrations and seed defaults.
  5. Push entitlements and create the first school admin.
  6. Generate `schools/<slug>/school.yaml` as a pull request for the app build.

  Each step is idempotent and retryable, with a visible log.
- **Plans and entitlements:** module bundles, limits, add-ons; per-school overrides; locks. Pushed as signed documents. The school API also pulls them on start.
- **Global config defaults:** default values and templates (role templates, notification templates, home layouts) that new schools start from. Changes can be offered to existing schools as an "update available" instead of being forced.
- **Release management:**
  - Which API/admin version each school runs.
  - Staged rollouts: internal demo school → pilot schools → everyone.
  - Pause and rollback, and migration status per school.
- **Mobile builds:**
  - Trigger builds per school or for all schools.
  - See build and store status per school.
  - Store-credential health: expiring certificates, missing API keys.
  - Store listing text and screenshots per school.
- **Health:** uptime, error rates, queue backlogs, backup freshness, disk and DB size per school, and alerts.
- **Support:** break-glass session requests, school contacts, notes.
- **Console access** is limited to our team, with SSO + 2FA mandatory, its own roles (super admin, support, release manager, read-only), and a full audit log.

## 11. Mobile app: one codebase, many store apps

### 11.1 Build profiles

`schools/<slug>/school.yaml` (committed, no secrets):

```yaml
slug: greenfield
appName: Greenfield
bundleId: in.edu.greenfield.app        # school-owned identifiers
apiBaseUrl: https://gis.edunest.app
defaultLocale: en
locales: [en, hi, mr]
brand: { primary: '#23784A', accent: '#F2A007' }
assets: { icon: icon.png, splash: splash.png }
stores: { ios: { teamId: ABCDE12345 }, android: { package: in.edu.greenfield.app } }
```

- Secrets (App Store Connect API key, Play service-account JSON, signing keys, Firebase config) live in our secrets vault under that school, never in the repo.
- With many schools, per-school native flavors don't scale (each one edits Gradle and Xcode). Instead, a build script injects the bundle ID, app name, icons and splash for the target school at build time into a single template project. It uses `--dart-define-from-file` for Dart values and generated icons and splash screens.

### 11.2 Store compliance (school-owned accounts)

- Each school is the **account holder and content provider** on Apple and Google, as Apple's guideline 4.2.6 requires for template-built apps. Google Play has a similar rule against operators submitting generated apps for others.
- The school invites EduNest as a team member with limited roles (App Manager / Release Manager) and creates API keys for our CI. Onboarding includes a step-by-step guide for this.
- To reduce "repetitive content" risk:
  - Each listing uses the school's own name, screenshots and description.
  - The app shows the school's own content.
  - We avoid identical store text across schools.
- **Fallback if a store rejects a school:** a single "EduNest" container app where families pick their school at sign-in, built from the same code with one extra build profile. We keep this path possible but don't build it unless needed.
- These policies change. Re-check the current guideline text before the first submission, and record the outcome in an ADR.

### 11.3 Release train

- One app version for all schools. A CI matrix builds every live school, uploads to each school's TestFlight and Play internal track, then promotes with phased release.
- Shorebird code push is an optional add-on for urgent Dart-only fixes across all schools. Decide after a cost check (it's priced on patch installs).
- The app's config is fetched at runtime, so most changes never need a store release.

### 11.4 App restructure

- `lib/` moves to `apps/mobile`. Shared code splits into `edunest_core`, `edunest_ui` and one package per feature module, registered through `ModuleRegistry`.
- The mock JSON data source stays as a **demo school** backend profile (useful for sales demos and tests). It's no longer a flag inside the app.
- Bugs from the earlier code review are fixed during the move:
  - load races and leaked listeners in `Loadable`
  - the receipt mismatch
  - leave end-date validation
  - marks entry subject
  - the plaintext password in storage
  - stub remote repositories
- The Chalk & Glass redesign lands as `edunest_ui`. Liquid glass is a Flutter fragment shader with a solid-fill fallback ("Reduce transparency" and low-end devices).

## 12. Infrastructure and operations

- **Phase 1 (up to ~30 schools):**
  - A few VMs managed by OpenTofu + Ansible.
  - Each host runs school stacks as Docker Compose projects behind Caddy (automatic TLS per school domain).
  - One Postgres server per host, or a managed Postgres per region, with one database and one user per school, and PgBouncer.
  - Separate Redis containers, separate buckets.
  - The console triggers deployments through a small, authenticated deploy agent on each host, which runs the template for that school.
- **Phase 2 (beyond ~30 schools or when needed):** Kubernetes with one namespace per school, a Helm chart for the school stack, and Argo CD (GitOps). This avoids configuration drift, the main risk of running many single-tenant installs. The same images and config work in both phases.
- **Migrations:**
  - Expand → migrate → contract. Never a breaking schema change in one release.
  - Migrations run per school during rollout, pilot schools first.
  - The console shows per-school migration state.
- **Backups:** continuous WAL archiving + nightly base backups per school database (pgBackRest/WAL-G) to a separate storage account, point-in-time recovery, and a monthly automated restore test per host. Buckets are versioned.
- **Secrets:** a managed vault (Infisical or 1Password Connect, my suggestion), scoped per school, rotated on schedule.
- **Environments:** local (Compose with a demo school), preview (per pull request: the demo school stack plus admin), staging (internal schools), production.

## 13. Security and privacy

- **India's Digital Personal Data Protection Act 2023:**
  - Children's data needs verifiable parental consent and special care.
  - Each school is the data fiduciary; we are its processor.
  - Plan for consent records, purpose limits, retention, data-subject requests (access, correction, erasure) and breach notification.
  - **Have a lawyer confirm the current rules before launch.**
- **Encryption:** in transit everywhere. At rest for databases and buckets. Field-level encryption for the most sensitive fields (health notes, government IDs, bank details).
- **Hardening:**
  - OWASP ASVS Level 2 as the checklist.
  - Rate limits and lockouts on auth; 2FA for staff.
  - Signed URLs for files.
  - No PII in logs or analytics.
  - Dependency and container scanning in CI.
  - An annual penetration test.
- **Payments:** use a payment gateway (Razorpay or similar) with hosted checkout, so card data never touches our servers.

## 14. Testing and quality

- **Contract tests:** the generated clients are compiled and tested against the OpenAPI document. A breaking change fails CI.
- **API tests:** unit tests per module, plus integration tests against a real Postgres (Testcontainers). Authorization tests for every role template and condition: "teacher can't see another class", "school A key can't call school B".
- **Config tests:** property tests that random valid configs always resolve and render. Every module tested both enabled and disabled.
- **Admin and console:** component tests plus Playwright end-to-end flows (onboarding, fee payment, publish config).
- **Flutter:** unit and widget tests. Golden tests for key screens in light, dark, AMOLED, large text and reduce-transparency. Integration tests against the demo school.
- **Performance budgets:** app cold start, API p95 per endpoint, admin bundle size, glass frame time.

## 15. Phased roadmap

| Phase | Outcome | Main work |
| --- | --- | --- |
| **0. Repo foundation** | Monorepo builds and tests from one command | Move the app to `apps/mobile`, set up pnpm/Turborepo, pub workspaces/Melos, CI with affected builds, lint boundaries, ADR folder |
| **1. Contracts + core backend** | One school stack runs locally | `contracts`, codegen, `apps/api` core (auth, people, academics basics, files, audit), config resolver, RBAC with templates, demo-school seed from today's mock JSON |
| **2. App on the real API** | The app works end to end against a school stack | Generated Dart client, `edunest_core` config runtime and module registry, features migrated module by module, review bugs fixed |
| **3. Admin panel v1** | A school can run daily operations | People, academics, attendance, homework, fees, notices, roles, settings, app configuration with preview and rollback |
| **4. Console + provisioning** | We can onboard a school without engineers | Registry, provisioning wizard, entitlements and locks, release management, health |
| **5. Per-school mobile builds** | School-branded apps in both stores | Build profiles, injection script, CI matrix, fastlane, store-credential vault, onboarding guide for schools |
| **6. Redesign + polish** | Chalk & Glass in production | `edunest_ui`, liquid-glass shader with fallbacks, motion system |
| **7. Pilot** | 1–3 real schools live | Data import, training, monitoring, backup drills, legal review |
| **Later** | Scale | Kubernetes/Argo CD, SMS/WhatsApp channels, payments reconciliation, analytics, container-app fallback if needed |

The order is a suggestion. Phases 3 and 4 can overlap, and 6 can start any time after 2.

## 16. Left to the builder

- Exact library versions; Prisma vs Drizzle if Prisma's multi-database tooling proves awkward (CASL integration is the reason for Prisma).
- UI details of the admin and console (they should follow Chalk & Glass tokens, but with light or no glass: they are tools, not showpieces).
- Which SMS, email and payment providers, behind interfaces so each school can choose.
- Hosting provider and region (keep data in India unless a school asks otherwise).

## 17. Calls I made (please check)

1. TypeScript/NestJS backend and React admin/console, not all-Dart.
2. Instance per school with a separate console, matching your "nothing shared" rule. The console never stores student data.
3. In-house config and feature flags (one document per school), not a hosted flag service.
4. Roles as data with conditions, plus a super-admin tier that school roles can never reach.
5. One template mobile project with build-time injection per school, not per-school native flavors.
6. Docker Compose on VMs first, Kubernetes later, with the same images for both.
7. Mock data kept as a "demo school" for sales demos and tests.
8. Admin and console get a calmer version of the design (no heavy glass).

## Sources

- Dart pub workspaces: https://dart.dev/blog/announcing-dart-3-6 · Melos: https://pub.dev/packages/melos
- TypeScript monorepo practice: https://hsb.horse/en/blog/typescript-monorepo-best-practice-2026/ · Nx/Turborepo/Moon comparison: https://www.pkgpulse.com/guides/turborepo-vs-nx-vs-moon-build-tools-2026
- White-label Flutter at scale: https://dev.to/kamero/taming-70-flutter-flavors-flavorizr-batch-ci-for-white-label-releases-54fl · https://themobileagent.substack.com/p/the-white-label-architecture-guide
- Apple 4.2.6 history: https://goodbarber.com/blog/apple-app-store-guideline-4-2-6-a862 · Apple forum: https://developer.apple.com/forums/thread/743316
- Google Play repetitive content: https://www.monetizemore.com/blog/avoid-repetitive-content-violation/
- Single-tenant + control plane: https://docs.decube.io/security-and-infrastructure/deployment-methods/saas-single-tenant · https://dzone.com/articles/designing-and-operating-single-tenant-architecture · https://aws.amazon.com/blogs/devops/cross-account-ci-cd-pipeline-single-tenant-saas/
- CASL + NestJS RBAC: https://blog.devgenius.io/mastering-complex-rbac-in-nestjs-integrating-casl-with-prisma-orm-for-granular-authorization-767941a05ef1
- Feature flags for Flutter: https://openfeature.dev/docs/reference/sdks/server/dart · https://docs.flagsmith.com/clients/flutter/ · https://docs.getunleash.io/sdks/flutter.md
- Serverpod: https://docs.serverpod.dev/overview · Shorebird: https://pro.codewithandrea.com/flutter-in-production/13-shorebird/01-intro
