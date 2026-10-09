# API contract

Each repository method maps to one REST call. `Remote*Repository` already calls these paths through `RemoteDataSource` and `ApiClient`. With `AppConfig.useMockData` left at `true`, the app never hits the network. Set it to `false` and the same calls throw `errors.remote_unconfigured` until `ApiClient` is implemented.

JSON bodies and responses use the shapes in [MOCK_SCHEMA.md](MOCK_SCHEMA.md). Dates on the wire are ISO-8601. Enum fields use the JSON values listed there (`late`, not the Dart name `lateArrival`; `class`, not `klass`).

## Errors

Failures are a JSON object:

```json
{ "message": "errors.bad_login" }
```

`message` is a translation key. The client surfaces it with `.tr`. HTTP status is 400 for validation, 401 for auth, 404 for a missing id, and 500 for anything else. `ApiClient` should turn a non-2xx body into `AppException(message)`.

## Auth

`POST /auth/login`, `/auth/otp`, and `/auth/demo` return the user object. The real client should also return `accessToken` and `refreshToken`. After that, every request sends `Authorization: Bearer <accessToken>`. Refresh with `POST /auth/refresh` and `{ "refreshToken": "..." }`. The demo does not mint tokens; the session is the user JSON kept by `AuthService`.

## Pagination

Collection GETs accept `page` (default 1) and `pageSize` (default 50). The response is either the raw array the repositories parse today, or:

```json
{ "items": [], "page": 1, "pageSize": 50, "total": 0 }
```

Remote parsers currently expect the raw array (or a single object). When a backend starts paginating, unwrap `items` in that repository only.

## Auth repository

| Method | Call |
| --- | --- |
| `login` | `POST /auth/login` `{ "email", "password" }` → user |
| `loginWithOtp` | `POST /auth/otp` `{ "email", "otp" }` → user |
| `loginAs` | `POST /auth/demo` `{ "role" }` → user |

## Directory

| Method | Call |
| --- | --- |
| `student` | `GET /students/:id` → student |
| `studentsIn` | `GET /classes/:classId/students` → student[] |
| `schoolClass` | `GET /classes/:id` → class |
| `classesForTeacher` | `GET /teachers/:teacherId/classes` → class[] |
| `teacher` / `teacherOrNull` | `GET /teachers/:id` → teacher |
| `teachers` | `GET /teachers` → teacher[] |
| `school` | `GET /school` → school info |

## Academics

| Method | Call |
| --- | --- |
| `AttendanceRepository.forStudent` | `GET /students/:studentId/attendance` → attendance[] |
| `summary` | Derived on the client from `forStudent`. No extra route. |
| `todayForClass` | `GET /attendance/today?students=id,id` → `{ "stu_aarav": "present" }` |
| `markToday` | `POST /attendance` `{ "<studentId>": "present" }` |
| `TimetableRepository.forClass` | `GET /classes/:classId/timetable` → timetable[] |
| `HomeworkRepository.forClass` | `GET /classes/:classId/homework` → homework[] |
| `byId` | `GET /homework/:id` → homework |
| `submit` | `POST /homework/:id/submissions` `{ "studentId", "fileName" }` |
| `grade` | `POST /homework/:id/grades` `{ "studentId", "marks", "grade", "feedback" }` |
| `assign` | `POST /homework` → homework object |
| `ExamRepository.forClass` | `GET /classes/:classId/exams` → exam[] |
| `result` | `GET /results/:examId/:studentId` → result |
| `resultsFor` | `GET /students/:studentId/results` → result[] |
| `marksDraft` | `GET /classes/:classId/marks?subject=maths` → `{ "<studentId>": 91 }` |
| `saveMarks` | `POST /classes/:classId/marks` `{ "subject", "values" }` |

## Campus

| Method | Call |
| --- | --- |
| `FeeRepository.forStudent` | `GET /students/:studentId/fees` → fee account |
| `pay` | `POST /fees/:installmentId/pay` `{ "studentId", "method" }` |
| `NoticeRepository.all` | `GET /notices` → notice[] |
| `post` | `POST /notices` → notice object |
| `EventRepository.all` | `GET /events` → event[] |
| `rsvp` | `POST /events/:eventId/rsvp` `{ "userId", "status" }` |
| `ChatRepository.threadsFor` | `GET /users/:userId/threads` → thread[] |
| `messages` | `GET /threads/:threadId/messages` → message[] |
| `inbox` | `GET /users/:userId/threads` plus `GET /users/:userId/messages` → message[] |
| `send` | `POST /threads/:threadId/messages` `{ "senderId", "text" }` |
| `LibraryRepository.all` | `GET /library/books` → book[] |
| `reserve` | `POST /library/books/:bookId/reserve` `{ "studentId" }` |
| `TransportRepository.forStudent` | `GET /students/:studentId/transport` → transport |
| `LeaveRepository.forStudent` | `GET /students/:studentId/leave` → leave[] |
| `apply` | `POST /leave` → leave object |
| `GalleryRepository.all` | `GET /gallery` → album[] |
| `NotificationRepository.forUser` | `GET /users/:userId/notifications` → notification[] |
| `dismiss` | `POST /notifications/:id/dismiss` `{}` |
| `markAllRead` | `POST /users/:userId/notifications/read` `{}` |

## Plug-ins (not built)

These stay behind their own interfaces so the demo does not pretend to talk to a vendor.

**Push.** `PushGateway.register(token)` and `PushGateway.revoke()`. The server stores the device token on `POST /devices`. Tapping a push opens the `route` already stored on a notification. The in-app list remains `NotificationRepository`.

**Payments.** `PaymentGateway.checkout({ installmentId, method, amount })` returns `{ status, reference }`. `FeeRepository.pay` calls it, then `POST /fees/:installmentId/pay` with that reference. UPI, card, and net banking in the sheet are labels only until a gateway is chosen.

**Live GPS.** `BusTracker.watch(busNo)` is a stream of `{ lat, lng, heading, etaMinutes }`. `TransportRepository.forStudent` stays the snapshot (route, stops, driver). The painted map would subscribe to the stream instead of the mock `progress` animation.
