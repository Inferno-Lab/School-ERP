# EduNest — guide for coding agents and new developers

EduNest is a Flutter school app (students, parents, teachers) in the **Chalk & Glass** design. It runs today on local JSON mock data; a real backend is a swap of adapters, not a rewrite. Read this file first. It is the single source of truth: `CLAUDE.md` and `AGENT.md` only point here.

Branch work happens on feature branches off `main`. The redesign lives on `redesign/chalk-glass`.

## Commands

```bash
flutter pub get
tool/verify.sh                     # analyze + all tests. Run before every commit.
flutter test test/some_test.dart   # one file
flutter run                        # mock data, no backend needed
flutter run --dart-define=EMPTY_DATA=true   # brand-new school with no content: check every empty state
flutter run --dart-define=ASSISTANT=true    # turns on the (future) assistant feature flag
flutter build apk --release --target-platform android-arm64,android-arm
```

Headless screenshots (no emulator, glass uses its blur fallback there):

```bash
flutter test test/tool/shoot_test.dart --dart-define=SHOOT_DIR=D:/out --dart-define=SHOOT_ROLE=student
#   SHOOT_ROLE=student|parent|teacher   SHOOT_DARK=true   EMPTY_DATA=true   SHOOT_W=390 SHOOT_H=844
```

The real glass shader only runs on a device or emulator (Impeller). Check glass changes there. See `docs/dev-environment.md` for machine setup and build pitfalls.

## Architecture in one screen

```
View (GetView/StatelessWidget)  →  Controller (GetxController + Loadable)  →  Repository (abstract)  →  DataSource
                                                                              ├─ Mock*  (assets/mock/*.json, MockJsonDataSource)
                                                                              └─ Remote* (RemoteDataSource → ApiClient)
```

- `lib/core/` shared infrastructure: `bindings/` (DI), `config/app_config.dart` (flags), `routes/`, `services/` (auth, storage, theme, session bus), `theme/`, `translations/`, `utils/`, `widgets/` (design system).
- `lib/data/` `models/`, `repositories/` (interface + Mock + Remote in one file per area), `datasources/`.
- `lib/features/<feature>/` `views/` and `controllers/` (and `widgets/` when a feature has reusable pieces). A view never talks to a repository; a controller never builds widgets.
- `InitialBinding` registers every repository: Mock when `AppConfig.useMockData`, Remote otherwise. Add a repository in **both** branches.
- `Loadable` gives a controller `state` (loading/success/empty/error), `run(...)`, and auto-reload when the `SessionBus` bumps (after any mock write) or the active child changes.
- Barrels: `core/widgets/ui.dart` re-exports `ui/*`; `teacher_tools_view.dart` re-exports the teacher screens. Import the barrel, put code in the part.

Details: `docs/architecture.md`. How to add a screen, a repository, or an AI feature: `docs/adding-a-feature.md`. Design rules and tokens: `docs/design-system.md`. HTTP shapes: `docs/API_CONTRACT.md`. Mock data shapes: `docs/MOCK_SCHEMA.md`.

## Rules that have bitten us (follow them)

1. **Translations.** All user-visible text goes through keys in `lib/core/translations/` (`'area.key'.tr`). Parameters use **`.trp({'name': value})`**, never `.trParams` (GetX replaces key prefixes, so `@n` eats `@name`). Hindi and Marathi fall back to English; add `en` first. `test/translation_keys_test.dart` fails on any literal key that is missing. Keys passed as widget parameters (`emptyTitle: 'x.y'`) are translated inside the widget, so they are not checked: double-check them.
2. **Never run repo-wide `dart fix --apply` or `dart format .`.** They rewrote unrelated files and broke types once. Format and fix only the files you touched (`dart format path/to/file.dart`). A hook in `.claude/` does the single-file format for you.
3. **No empty screens.** Every list or collection screen must handle the "brand-new school" case with `ViewStateView(emptyArt:, emptyTitle:, emptyBody:, emptyHint:, emptyActions:)` and an `EmptyArt` illustration, in friendly copy that says what will appear and what the user can do. Check with `--dart-define=EMPTY_DATA=true` (also a switch on the design-system screen).
4. **Glass is for floating controls only** (dock, top icon buttons, pills, sheets, toast, bottom action bars). Never put a glass block behind page content such as a header, a card, or a greeting. Use `Glass`, `GlassIconButton`, `GlassSegmented`, `GlassSwitch`, `GlassSlider` from `core/widgets/`; do not re-implement the filter. On colourful art use `onPigment: true`.
5. **Layout traps we hit**: `Container(alignment:)` expands to fill its parent. A `Row` without `crossAxisAlignment: stretch` gives a 0-height `ColoredBox`. A `Column` in a loose-height parent needs `mainAxisSize: min`. A `Column` with default centre alignment will float a shrink-wrapped child to the middle (use `stretch`). `Obx` with no observable read inside throws. Labels next to chips need `Expanded`/`Flexible` plus a gap and `ellipsis`.
6. **Dummy data lives in `assets/mock/*.json`.** Dates use relative tokens (`today-1`, `today+2T09:00`) resolved by `date_seed.dart`; keep them valid (`today-0T010:12` crashed headless runs). Mock calls answer in 30–90 ms by default; do not add artificial delays. `AppConfig.slowNetwork` (Developer switch) is how you test loading states.
7. **Do not add dependencies for a few lines of code.** `phosphor_flutter` is vendored under `packages/` on purpose.
8. **Sign-out** goes through `AuthService.signOut()` (clears the session, navigates to login first, then clears state). Do not clear state before navigating.
9. **Performance**: tabs are lazy (`LazyIndexedStack`); keep per-screen glass to the few floating controls; avoid animating layout; `Rise` stagger is capped. Release builds are what you judge speed on, not debug.

## Conventions

- Dart: `very_good_analysis` (see `analysis_options.yaml`). `dart analyze lib test` must show no errors or warnings. Prefer small, focused files; a view file over ~500 lines should be split by screen or sheet.
- Controllers live in `controllers/`, never inside a view file. Shared helpers that two files need become public and move next to the controller or into `core/utils`.
- Comments say *why*, one line. Mark a deliberate limit with `// shortcut: <the limit>, <when to upgrade>`.
- Commits are atomic and use Conventional Commits (`fix(glass): …`, `refactor(fees): …`). Keep refactors separate from behaviour changes.
- Visual changes: look at them (headless shot at minimum; emulator for glass). Light, dark, AMOLED; small phone (360×640), phone (390×844), tablet (≥ 840 wide).
- Demo accounts: password `demo123`, OTP `123456`. Student Aarav, parent Priya, teacher Kavita (see `README.md`).

## Where things are

| I want to… | Look at |
| --- | --- |
| change colours, type, spacing | `core/theme/` (`tokens.dart`, `app_colors.dart`, `app_typography.dart`) |
| add or edit copy | `core/translations/en_redesign.dart` (redesign copy), `app_translations.dart` |
| add a route | `core/routes/app_routes.dart` + `app_pages.dart` (and a `Binding` if the controller is not on the shell) |
| add mock content | `assets/mock/*.json` + `docs/MOCK_SCHEMA.md` |
| toggle a feature or demo mode | `core/config/app_config.dart` |
| change glass | `core/widgets/glass.dart`, `shaders/liquid_glass.frag` |
| make an empty state | `core/widgets/states.dart`, `empty_art.dart` |
| see all the building blocks | design-system screen (Settings → About → long-press the version row) |

## Working with agents on this repo

- Start from this file; open `docs/` only for the area you touch.
- Slash commands in `.claude/commands/`: `/verify`, `/shoot`, `/new-screen`, `/new-repository`, `/new-ai-feature`.
- Parallel sessions: one writer per set of files; use a worktree per session. Never edit `assets/mock/*.json` and `en_redesign.dart` from two sessions at once (merge hot-spots).
- After a change, tell the user what you did **not** check (device glass, other roles, other themes).
