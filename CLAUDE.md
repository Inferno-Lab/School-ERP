@AGENTS.md

## Claude Code specifics

- Slash commands live in `.claude/commands/`; project permissions and the format hook in `.claude/settings.json`. Personal overrides go in `.claude/settings.local.json` (git-ignored).
- Run `tool/verify.sh` before saying work is done. Report what you did not check (device glass, other roles, dark mode).
- Do not run repo-wide `dart fix`/`dart format`. The format hook only touches the file you edited.
- Prefer the dedicated Read/Edit/Grep tools; shell is for `flutter`, `dart`, `git`, `adb`.
- Ponytail style (smallest complete change, no speculative abstractions) is the house style here.
