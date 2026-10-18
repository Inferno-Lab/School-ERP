---
description: Add a page to the school admin or the console
argument-hint: "<admin|console> <page name and what it shows>"
---
Read `docs/HANDOFF.md` section 9.1 and `docs/DESIGN.md`, then add the page in $ARGUMENTS the way `docs/adding-a-feature.md` → "An admin or console page" describes: contracts, migration and seed if data is new, API service and controller with tests, api-client method, the page from the shared `Page` and blocks with loading/empty/error/read-only states, route and menu entry. Then run `pnpm typecheck && pnpm test`, add the page to `tools/audit-ui.mjs` and a flow to `tools/e2e-flows.mjs`, run both against `tools/dev-reset.sh` data, and say what you did not check (real device, owner's design review).
