import 'package:edunest/core/services/auth_service.dart';
import 'package:edunest/core/utils/loadable.dart';
import 'package:edunest/core/utils/status.dart';
import 'package:edunest/data/models/academics.dart';
import 'package:edunest/data/models/campus.dart';
import 'package:edunest/data/models/student.dart';
import 'package:edunest/data/repositories/academic_repository.dart';
import 'package:edunest/data/repositories/campus_repository.dart';
import 'package:edunest/data/repositories/directory_repository.dart';
import 'package:get/get.dart';

class HomeSnapshot {
  HomeSnapshot({
    required this.student,
    required this.schoolClass,
    required this.summary,
    required this.today,
    required this.pending,
    required this.nextExam,
    required this.due,
    required this.notices,
  });

  final Student student;
  final SchoolClass schoolClass;
  final AttendanceSummary summary;
  final TimetableDay? today;
  final List<Homework> pending;
  final Exam? nextExam;
  final Installment? due;
  final List<Notice> notices;
}

class DashboardController extends GetxController with Loadable {
  HomeSnapshot? snapshot;

  @override
  Future<void> load() async {
    final studentId = Get.find<AuthService>().activeStudentId.value;
    if (studentId == null) {
      await run(() async {}, isEmpty: () => true);
      return;
    }
    await run(() async {
      final directory = Get.find<DirectoryRepository>();
      final student = await directory.student(studentId);
      final schoolClass = await directory.schoolClass(student.classId);
      final now = DateTime.now();
      final results = await Future.wait<Object?>([
        Get.find<AttendanceRepository>().summary(studentId, month: now),
        Get.find<TimetableRepository>().forClass(student.classId),
        Get.find<HomeworkRepository>().forClass(student.classId),
        Get.find<ExamRepository>().forClass(student.classId),
        Get.find<FeeRepository>().forStudent(studentId),
        Get.find<NoticeRepository>().all(),
      ]);
      final summary = results[0]! as AttendanceSummary;
      final days = results[1]! as List<TimetableDay>;
      final work = results[2]! as List<Homework>;
      final exams = results[3]! as List<Exam>;
      final fees = results[4] as FeeAccount?;
      final notices = results[5]! as List<Notice>;
      final key = weekdayKey(now);
      TimetableDay? today;
      for (final day in days) {
        if (day.day == key) today = day;
      }
      final pending = work.where((item) {
        final mine = item.forStudent(studentId);
        return mine == null || mine.status == HomeworkStatus.pending;
      }).toList();
      Exam? next;
      for (final exam in exams) {
        if (exam.status == ExamStatus.upcoming) next = exam;
      }
      Installment? due;
      if (fees != null) {
        for (final item in fees.installments) {
          final tone = moneyStatus(item);
          if (tone == MoneyStatus.due || tone == MoneyStatus.overdue) {
            due = item;
            break;
          }
        }
      }
      snapshot = HomeSnapshot(
        student: student,
        schoolClass: schoolClass,
        summary: summary,
        today: today,
        pending: pending,
        nextExam: next,
        due: due,
        notices: notices.take(5).toList(),
      );
    }, isEmpty: () => snapshot == null);
  }
}
