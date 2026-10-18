---
description: Run the browser audit and flows for admin and console
---
With the server (4000), admin (5173) and console (5174) running on fresh demo data (`bash tools/dev-reset.sh` in the background), run `node tools/audit-ui.mjs` (add `--quick` for two widths) and `node tools/e2e-flows.mjs` (use `ONLY="text"` for one flow). Fix the cause of every failure (a flow that only fails because data was already changed by an earlier run is not a bug: reset and re-run). Report what is green and what the scripts cannot judge (real devices, the owner's taste).
