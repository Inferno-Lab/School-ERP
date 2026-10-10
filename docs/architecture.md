# Architecture

## Layers and what each may know

| Layer | Lives in | May use | Must not |
| --- | --- | --- | --- |
| View | `features/*/views`, `core/widgets` | its controller, design-system widgets, `.tr` | call a repository, hold business logic |
| Controller | `features/*/controllers` | repositories, services, `Loadable` | build widgets, read `BuildContext` (toasts and routes go through helpers) |
| Repository | `data/repositories` | a data source | know about GetX state or widgets |
| Data source | `data/datasources` | JSON assets, `ApiClient` | be called from a controller |

Each repository file holds the **interface**, the **Mock** adapter and the **Remote** adapter for one area (`academic`, `campus`, `directory`, `auth`, `assistant`). One adapter would be a guess; two (mock + remote) is the real seam, so keep both honest.

## Data flow of a screen

1. A route in `app_pages.dart` creates the controller (a `Binding`, or the shell binding for tab screens).
2. `Loadable.onInit` calls `load()`; `run(...)` flips `state` between loading, success, empty and error. `isEmpty:` decides when the empty design shows.
3. The view reads `controller.state` in an `Obx` and hands it to `ViewStateView`.
4. A write (pay, send, submit) goes through the repository; the mock bumps `SessionBus.revision`, and every open `Loadable` controller reloads itself.
5. Changing the active child (`AuthService.activeStudentId`) reloads them as well.

## Dependency injection

`lib/core/bindings/initial_binding.dart` registers repositories lazily (`fenix: true`, so they rebuild after a `Get.delete`). Mock when `AppConfig.useMockData`, Remote otherwise. Tests build their own graph in `test/support/harness.dart` (`bootMock`).

## Feature switches and demo modes

`AppConfig` is the only place for them: `useMockData`, `emptyData` (new-school demo), `slowNetwork`, `simulateErrors`, `assistantEnabled` (compile-time, `--dart-define=ASSISTANT=true`). A school build profile can change per-school values (name, tagline, logo). Anything user-facing that is unfinished sits behind a flag until its screen and backend exist.

## Roles

`UserRole` is student, parent or teacher. The shell (`features/shell`) picks tabs by role: families get Home / Academics / Fees / Chat / Profile; teachers get Home / Classes / Notices / Chat / Profile. Chat threads are stored from the family's side; `threadForMe` swaps the title for the person it names.

## Navigation

GetX named routes (`AppRoutes`). Tab switching from inside a screen: `ShellController.showTab(ShellController.chatTab)`. Sign-out: `AuthService.signOut()`.

## Platform pieces

- `shaders/liquid_glass.frag` is the backdrop filter behind `Glass`. See `docs/design-system.md` → Glass.
- Android: adaptive icon, Android 12 splash styles in `values-v31`, `kotlin.incremental=false` in `gradle.properties` (cross-drive builds).

## Where the platform is going

The long-term plan (admin console, backend, per-school builds, configurable modules) is in `docs/superpowers/specs/2026-10-10-edunest-platform-monorepo-design.md`. The app side already follows it: repositories are interfaces, flags are central, copy is keyed, and per-school values are constants in `AppConfig`.
