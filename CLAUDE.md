@AGENTS.md

## Claude Code specifics

- Slash commands live in `.claude/commands/`; project permissions in `.claude/settings.json`. Personal overrides go in `.claude/settings.local.json` (git-ignored).
- Run `tool/verify.sh` before saying work is done. Report what you did not check (device glass, other roles, dark mode).
- Do not run `dart fix`/`dart format` over the repo (or over files you barely touched): the code is hand-formatted at ~120 columns and the formatter rewraps at 80.
- Prefer the dedicated Read/Edit/Grep tools; shell is for `flutter`, `dart`, `git`, `adb`.
- Ponytail style (smallest complete change, no speculative abstractions) is the house style here.
