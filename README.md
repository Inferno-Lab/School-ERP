# EduNest

EduNest is a Flutter demo of a school app for students, parents, and teachers. Every screen reads local JSON. The repositories are abstract, so a real backend is a single switch in `AppConfig` plus an `ApiClient` implementation.

The product name is **EduNest**. Change it in one place: `AppConfig.appName` in `lib/core/config/app_config.dart`. The logo mark is `NestMark` (`lib/core/widgets/misc.dart`); the asset path is `AppConfig.logoAsset`.

## Requirements

- Flutter 3.41 or newer (Dart `^3.11.5`)
- Xcode for the iOS simulator, or Android Studio for an Android emulator

## Run

```bash
flutter pub get
dart run build_runner build
flutter run
```

`flutter analyze` should report no issues. `flutter test` covers the mock data source, repositories, theme persistence, login, home, fees, settings, teacher attendance, marks entry, and the remote binding switch.

## Demo accounts

Password `demo123` for every account. OTP `123456`.

| Role | Name | Email |
| --- | --- | --- |
| Student | Aarav Sharma | aarav.sharma@edunest.app |
| Parent | Priya Sharma | priya.sharma@edunest.app |
| Teacher | Kavita Iyer | kavita.iyer@edunest.app |

The three cards on the login screen sign in as those users. Priya can switch between Aarav (Class 8 A) and Ananya (Class 5 B).

## Client demo script

**Student (Aarav).** Open the app, skip or finish onboarding, and tap the Student card. Home shows a greeting, an attendance ring, today's timetable, homework that is due, the next exam, a fee banner, and a notice carousel. Open Academics, then Attendance (the calendar marks absent and late days), Homework (submit a sample scan), Timetable, and Results (bars, a trend line, and a radar chart). Open Fees, pay the overdue lab fee with UPI, and show the receipt. The home banner updates after you go back. Then Notices, Events (RSVP), Chat (send a message and wait for the office reply), Transport, Library, Gallery, and Leave.

**Parent (Priya).** Sign out from Settings and tap the Parent card. Home is Aarav's. Open the child switcher and pick Ananya. Her fee banner disappears because she has nothing due in the next 21 days. Notifications are grouped into Today and Earlier; swipe one away.

**Teacher (Kavita).** Sign in with the Teacher card. Home shows the next class and today's schedule. Open Classes, then Attendance for 8 A. Tap avatars to cycle Present, Absent, and Late, mark everyone present, and submit. Assign homework, grade a submission, enter marks, and post a notice. Sign back in as Aarav and show the new notice, the graded homework, and today's attendance.

**Polish.** In Settings, switch Light, Dark, AMOLED, and System, pick another accent, turn on dynamic color on Android 12+, change text size and language (English, Hindi, Marathi), and toggle Reduce motion. The developer section can simulate errors. Long-press the version row to open the design system.

## What is included

- Splash, onboarding, and login (password or OTP, plus demo cards)
- Role shell: floating bar on phones, navigation rail from 840px
- Student and parent home, academics, attendance, homework, timetable, results, fees
- Notices, events, chat, transport, library, gallery, leave, notifications, profile
- Teacher home, classes, attendance, homework, grading, marks, notices
- Settings: theme, six accents, Material You, text scale, locale, notification toggles, reduce motion
- Light, dark, and AMOLED themes. Strings go through GetX translations (`en`, with partial `hi` and `mr`)

## Architecture

```
View  →  GetxController  →  Repository  →  DataSource
```

`InitialBinding` registers a `Mock*` or `Remote*` repository from `AppConfig.useMockData`. Controllers expose a `ViewState` of loading, success, empty, or error. `SessionBus` bumps after a mock write so open screens reload. `ThemeService`, `AuthService`, and `StorageService` are `GetxService`s.

```
lib/
  core/        config, theme, widgets, routes, services, translations
  data/        models, mock JSON source, remote stub, repositories
  features/    one folder per screen group
assets/mock/   the demo school
```

## Swap in a real API

1. Implement `ApiClient.get`, `post`, and `patch` in `lib/core/network/api_client.dart`. Send `Authorization` once login returns a token. Map error JSON `{ "message": "errors.*" }` to `AppException`.
2. Keep the paths in `Remote*Repository`. They already match [docs/API_CONTRACT.md](docs/API_CONTRACT.md).
3. Set `AppConfig.useMockData` to `false`.

The views and controllers do not change. Push, card payments, and live bus GPS are described as plug-in interfaces in the contract. They are not implemented.

## Theming

`AppTheme` builds light, dark, and AMOLED `ThemeData` from an `AccentPalette` (Ocean, Emerald, Royal Purple, Sunset, Rose, Teal). Status and subject colors live on the `AppColors` theme extension (`context.app`). Headings use bundled Poppins. Body text uses bundled Plus Jakarta Sans. `GoogleFonts.config.allowRuntimeFetching` is false, so the first frame does not download fonts.

Text scale is Small (0.9), Default (1.0), or Large (1.15), applied with `MediaQuery.textScaler`. Reduce motion skips staggered entrances.
