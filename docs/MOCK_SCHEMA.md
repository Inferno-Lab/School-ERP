# Mock data schema

All demo data lives in `assets/mock/`. `MockJsonDataSource` loads each file once, resolves relative dates, and keeps the result in memory for the session. Writes (pay a fee, submit homework, mark attendance, send a chat, RSVP, post a notice, apply for leave, reserve a book, dismiss a notification) mutate that memory and bump `SessionBus`. Nothing is written back to disk.

## Relative dates

Any string matching `today`, `today+N`, `today-N`, or the same forms with `Thh:mm` is rewritten to an ISO date (or `YYYY-MM-DDThh:mm:00`) before JSON models are parsed. `today` is the local calendar day when the file is loaded, so the demo stays current.

## Computed fee status

`Installment.paid` is stored. The badge is not. `moneyStatus` returns:

- `paid` when `paid` is true
- `overdue` when unpaid and the due date is before today
- `due` when unpaid and the due date is today or within 21 days
- `upcoming` otherwise

Aarav (`stu_aarav`) has an overdue lab fee and a Term 2 fee inside the due window, so the home banner shows. Ananya (`stu_ananya`) is paid up except a costume fee far in the future, so the banner hides when a parent switches child. Receipts for a payment are created in memory at pay time; they are not a separate JSON file.

## Files

| File | Root | What it is |
| --- | --- | --- |
| `users.json` | array | Login accounts |
| `students.json` | array | Student profiles |
| `classes.json` | array | Class sections |
| `teachers.json` | array | Staff |
| `attendance.json` | array | One row per student per day |
| `timetable.json` | array | One row per class per weekday |
| `homework.json` | array | Assignments plus per-student submissions |
| `exams.json` | array | Exam papers |
| `results.json` | array | Published marks |
| `fees.json` | array | One account per student |
| `notices.json` | array | School notices |
| `events.json` | array | Events plus RSVP |
| `chat_threads.json` | array | Conversations |
| `messages.json` | array | Messages |
| `library_books.json` | array | Catalogue |
| `transport.json` | array | One route per student |
| `leave_requests.json` | array | Leave applications |
| `gallery.json` | array | Albums with photos |
| `notifications.json` | array | In-app notifications |
| `school_info.json` | object | Greenfield International School, Pune |
| `demo_accounts.json` | array | The three cards on the login screen |

## Enums (JSON values)

- Role: `student`, `parent`, `teacher`
- Attendance: `present`, `absent`, `late`, `holiday` (today is left unmarked so a teacher can mark it; Sundays and `today-16` are holidays)
- Period kind: `class`, `break`, `recess`
- Homework status: `pending`, `submitted`, `graded`
- Exam status: `upcoming`, `completed`
- Leave: `pending`, `approved`, `rejected`
- RSVP: `going`, `maybe`, `cant`

## Relationships

- `users.studentId` → `students.id` (`stu_aarav`, `stu_ananya`)
- `users.teacherId` → `teachers.id` (`tch_kavita`)
- `users.childIds[]` → `students.id` (Priya: Aarav and Ananya)
- `students.classId` → `classes.id` (`cls_8a` is Class 8 A, `cls_5b` is Class 5 B)
- `classes.classTeacherId` → class teacher
- `attendance.studentId` → `students.id`
- `timetable.classId` → `classes.id`; each period's `teacherId` → `teachers.id`
- `homework.classId` → `classes.id`; `submissions[].studentId` → `students.id`
- `exams.classId` → `classes.id`
- `results.examId` + `results.studentId`
- `fees.studentId` → `students.id`; `installments[].id` is the payment key
- `events.rsvps[].userId` → `users.id`
- `chat_threads.participantIds[]` → `users.id`; `messages.threadId` → `chat_threads.id`
- `library_books.borrowedBy` → `students.id` when borrowed
- `transport.studentId` → `students.id`
- `leave_requests.studentId` → `students.id`
- `notifications.userId` → `users.id`; `route` is an in-app path

## Field notes

**User:** `id`, `role`, `name`, `email`, `phone`, `avatarUrl`, `password`, `childIds`, optional `studentId`, optional `teacherId`.

**Student:** `id`, `userId`, `name`, `classId`, `rollNo`, `dob`, `bloodGroup`, `house`, `avatarUrl`, `guardianName`, `guardianPhone`, `address`.

**Class:** `id`, `name`, `section`, `classTeacherId`, `room`, `studentIds`.

**Teacher:** `id`, optional `userId`, `name`, `subject`, `email`, `phone`, `avatarUrl`, `classIds`.

**Attendance day:** `studentId`, `date`, `status`.

**Timetable day:** `classId`, `day` (`mon`…`sat`), `periods[]` of `id`, `subject`, optional `teacherId`, `start`, `end`, `room`, `kind`.

**Homework:** `id`, `classId`, `subject`, `title`, `description`, `assignedOn`, `dueOn`, `teacherId`, `maxMarks`, `attachments[]`, `submissions[]` (`studentId`, `status`, optional `submittedAt`, `fileName`, `marks`, `grade`, `feedback`).

**Exam:** `id`, `name`, `classId`, `startDate`, `endDate`, `status`, `subjects[]`.

**Result:** `id`, `examId`, `studentId`, `overallPercent`, `grade`, `rank`, `totalStudents`, `subjects[]` (`subject`, `marks`, `maxMarks`, `grade`), `trend[]` (`label`, `percent`).

**Fee account:** `studentId`, `academicYear`, `installments[]` (`id`, `title`, `amount`, `dueDate`, `paid`, optional `paidOn`, `method`, `reference`).

**Notice:** `id`, `title`, `body`, `category` (`academic`, `exams`, `sports`, `fees`, `holiday`, `general`), `audience`, `pinned`, `date`, `author`, `attachments[]`.

**Event:** `id`, `title`, `description`, `date`, `time`, `venue`, `category`, `imageUrl`, `rsvps[]` (`userId`, `status`).

**Chat thread:** `id`, `title`, `subtitle`, `avatarUrl`, `participantIds[]`, `online`.

**Message:** `id`, `threadId`, `senderId`, `text`, `sentAt`, `read`.

**Library book:** `id`, `title`, `author`, `category`, `isbn`, `available`, `coverUrl`, optional `borrowedBy`, `dueDate`.

**Transport:** `studentId`, `routeName`, `busNumber`, `etaMinutes`, `progress`, `driver` (`name`, `phone`, `avatarUrl`), `stops[]` (`name`, `time`, `reached`).

**Leave:** `id`, `studentId`, `from`, `to`, `reason`, `status`, `appliedOn`, optional `reviewedBy`, `reviewNote`.

**Gallery album:** `id`, `title`, `date`, `blurb`, `photos[]` (`id`, `url`, `caption`).

**Notification:** `id`, `userId`, `title`, `body`, `type`, `date`, `read`, `route`.

**School:** `name`, `tagline`, `address`, `phone`, `email`, `website`, `principal`, `founded`, `officeHours`, `about`.

Avatars and gallery photos are network URLs (`pravatar.cc`, `picsum.photos`). The UI falls back to initials if the device is offline.
