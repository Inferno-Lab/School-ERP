---
description: Add a screen the way this codebase does it
argument-hint: "<feature> <screen name>"
---
Add the screen in $ARGUMENTS following `docs/adding-a-feature.md` → "A screen":
1. Controller in `lib/features/<feature>/controllers/` (`GetxController` with `Loadable`).
2. View in `views/` using `PageFrame` and `ViewStateView` with a designed empty state (`emptyArt`, copy, hint, actions).
3. Route in `app_routes.dart` + `app_pages.dart`.
4. Copy in `en_redesign.dart` using `.tr` / `.trp`. Mock data in `assets/mock/` if needed.
5. Extend `test/screens_smoke_test.dart`, then run `tool/verify.sh` and shoot the screen light, dark and with `EMPTY_DATA=true`.
