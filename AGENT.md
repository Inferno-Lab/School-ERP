# Agent guide

The full guide for agents and developers is [`AGENTS.md`](AGENTS.md). Read that file; this one exists so tools that look for `AGENT.md` find it.

Short version: Flutter + GetX app. `View → Controller → Repository → DataSource`, mock data in `assets/mock/`, run `tool/verify.sh` before committing, never run repo-wide `dart fix`/`dart format`, use `.trp()` not `.trParams()`, and no screen may ship without a friendly empty state.
