import 'package:edunest/core/services/auth_service.dart';
import 'package:edunest/core/utils/app_exception.dart';
import 'package:edunest/core/utils/haptics.dart';
import 'package:edunest/core/utils/loadable.dart';
import 'package:edunest/core/utils/status.dart';
import 'package:edunest/core/widgets/toast.dart';
import 'package:edunest/data/models/academics.dart';
import 'package:edunest/data/models/campus.dart';
import 'package:edunest/data/models/student.dart';
import 'package:edunest/data/repositories/academic_repository.dart';
import 'package:edunest/data/repositories/campus_repository.dart';
import 'package:edunest/data/repositories/directory_repository.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TeacherHomeController extends GetxController with Loadable {
  SchoolClass? schoolClass;
  TimetableDay? today;
  int pendingGrades = 0;

  @override
  bool get watchRevision => true;

  @override
  Future<void> load() async {
    final teacherId = Get.find<AuthService>().user.value?.teacherId;
    if (teacherId == null) {
      await run(() async {}, isEmpty: () => true);
      return;
    }
    await run(() async {
      final classes = await Get.find<DirectoryRepository>().classesForTeacher(teacherId);
      schoolClass = classes.isEmpty ? null : classes.first;
      if (schoolClass == null) return;
      final days = await Get.find<TimetableRepository>().forClass(schoolClass!.id);
      final key = weekdayKey(DateTime.now());
      for (final day in days) {
        if (day.day == key) today = day;
      }
      final work = await Get.find<HomeworkRepository>().forClass(schoolClass!.id);
      pendingGrades = 0;
      for (final item in work) {
        pendingGrades += item.submissions
            .where((submission) => submission.status == HomeworkStatus.submitted)
            .length;
      }
    }, isEmpty: () => schoolClass == null);
  }

  PeriodSlot? get nextPeriod {
    final periods = today?.periods.where((period) => period.kind == PeriodKind.klass) ?? [];
    final now = DateTime.now().hour * 60 + DateTime.now().minute;
    for (final period in periods) {
      final parts = period.start.split(':');
      final start = int.parse(parts[0]) * 60 + int.parse(parts[1]);
      if (start >= now) return period;
    }
    return null;
  }
}

class TeacherClassesController extends GetxController with Loadable {
  List<SchoolClass> classes = [];

  @override
  Future<void> load() async {
    final teacherId = Get.find<AuthService>().user.value?.teacherId;
    if (teacherId == null) {
      await run(() async {}, isEmpty: () => true);
      return;
    }
    await run(() async {
      classes = await Get.find<DirectoryRepository>().classesForTeacher(teacherId);
    }, isEmpty: () => classes.isEmpty);
  }
}

class MarkAttendanceController extends GetxController with Loadable {
  MarkAttendanceController({this.classId});

  final String? classId;

  @override
  bool get watchRevision => false;

  List<Student> students = [];
  final marks = <String, AttendanceStatus>{}.obs;
  final saving = false.obs;

  @override
  Future<void> load() async {
    final id = classId ?? Get.parameters['classId'];
    if (id == null) {
      await run(() async {}, isEmpty: () => true);
      return;
    }
    await run(() async {
      students = await Get.find<DirectoryRepository>().studentsIn(id);
      final existing = await Get.find<AttendanceRepository>().todayForClass(
        students.map((student) => student.id).toList(),
      );
      marks
        ..clear()
        ..addAll(existing);
    }, isEmpty: () => students.isEmpty);
  }

  void cycle(String id) {
    Haptics.selection();
    final current = marks[id];
    marks[id] = switch (current) {
      null || AttendanceStatus.holiday => AttendanceStatus.present,
      AttendanceStatus.present => AttendanceStatus.absent,
      AttendanceStatus.absent => AttendanceStatus.lateArrival,
      AttendanceStatus.lateArrival => AttendanceStatus.present,
    };
  }

  void allPresent() {
    Haptics.medium();
    for (final student in students) {
      marks[student.id] = AttendanceStatus.present;
    }
  }

  Future<void> submit() async {
    saving.value = true;
    try {
      final payload = {
        for (final student in students)
          student.id: marks[student.id] ?? AttendanceStatus.present,
      };
      await Get.find<AttendanceRepository>().markToday(payload);
      ToastHelper.show('teacher.attendance_saved', kind: ToastKind.success);
      Get.back<void>();
    } on AppException catch (error) {
      ToastHelper.show(error.message, kind: ToastKind.error);
    } finally {
      saving.value = false;
    }
  }
}

class AssignHomeworkController extends GetxController {
  final title = TextEditingController();
  final body = TextEditingController();
  final formKey = GlobalKey<FormState>();
  final subject = 'maths'.obs;
  final due = DateTime.now().add(const Duration(days: 2)).obs;
  final saving = false.obs;

  Future<void> submit(String classId) async {
    if (formKey.currentState?.validate() != true) return;
    final teacherId = Get.find<AuthService>().user.value?.teacherId;
    if (teacherId == null) return;
    saving.value = true;
    try {
      final students = await Get.find<DirectoryRepository>().studentsIn(classId);
      await Get.find<HomeworkRepository>().assign(
        Homework(
          id: 'hw_${DateTime.now().microsecondsSinceEpoch}',
          classId: classId,
          subject: subject.value,
          title: title.text.trim(),
          description: body.text.trim(),
          assignedOn: DateTime.now(),
          dueOn: due.value,
          teacherId: teacherId,
          maxMarks: 20,
          attachments: const [],
          submissions: [
            for (final student in students)
              HomeworkSubmission(studentId: student.id, status: HomeworkStatus.pending),
          ],
        ),
      );
      ToastHelper.show('teacher.homework_sent', kind: ToastKind.success);
      Get.back<void>();
    } on AppException catch (error) {
      ToastHelper.show(error.message, kind: ToastKind.error);
    } finally {
      saving.value = false;
    }
  }

  @override
  void onClose() {
    title.dispose();
    body.dispose();
    super.onClose();
  }
}

class GradingController extends GetxController with Loadable {
  List<Homework> items = [];

  @override
  Future<void> load() async {
    final teacherId = Get.find<AuthService>().user.value?.teacherId;
    if (teacherId == null) {
      await run(() async {}, isEmpty: () => true);
      return;
    }
    await run(() async {
      final classes = await Get.find<DirectoryRepository>().classesForTeacher(teacherId);
      items = [];
      for (final schoolClass in classes) {
        items.addAll(await Get.find<HomeworkRepository>().forClass(schoolClass.id));
      }
    }, isEmpty: () => items.isEmpty);
  }

  Future<void> grade({
    required Homework homework,
    required String studentId,
    required int marks,
    required String feedback,
  }) async {
    final ratio = marks / homework.maxMarks;
    final grade = ratio >= 0.9 ? 'A+' : ratio >= 0.8 ? 'A' : ratio >= 0.7 ? 'B+' : 'B';
    try {
      await Get.find<HomeworkRepository>().grade(
        homeworkId: homework.id,
        studentId: studentId,
        marks: marks,
        grade: grade,
        feedback: feedback,
      );
      ToastHelper.show('teacher.graded', kind: ToastKind.success);
    } on AppException catch (error) {
      ToastHelper.show(error.message, kind: ToastKind.error);
    }
  }
}

class MarksEntryController extends GetxController with Loadable {
  MarksEntryController({this.classId});

  final String? classId;
  List<Student> students = [];
  final subject = 'maths'.obs;
  final values = <String, int>{}.obs;

  @override
  bool get watchRevision => false;

  @override
  Future<void> load() async {
    final id = classId ?? Get.parameters['classId'];
    if (id == null) {
      await run(() async {}, isEmpty: () => true);
      return;
    }
    await run(() async {
      students = await Get.find<DirectoryRepository>().studentsIn(id);
      final draft = await Get.find<ExamRepository>().marksDraft(id, subject.value);
      values
        ..clear()
        ..addAll(draft);
    }, isEmpty: () => students.isEmpty);
  }

  Future<void> save() async {
    final id = classId ?? Get.parameters['classId'];
    if (id == null) return;
    try {
      await Get.find<ExamRepository>().saveMarks(
        classId: id,
        subject: subject.value,
        values: values,
      );
      ToastHelper.show('teacher.marks_saved', kind: ToastKind.success);
    } on AppException catch (error) {
      ToastHelper.show(error.message, kind: ToastKind.error);
    }
  }
}

class PostNoticeController extends GetxController {
  final title = TextEditingController();
  final body = TextEditingController();
  final formKey = GlobalKey<FormState>();
  final category = 'general'.obs;
  final pinned = false.obs;
  final saving = false.obs;

  Future<void> submit() async {
    if (formKey.currentState?.validate() != true) return;
    saving.value = true;
    try {
      await Get.find<NoticeRepository>().post(
        Notice(
          id: 'nt_${DateTime.now().microsecondsSinceEpoch}',
          title: title.text.trim(),
          body: body.text.trim(),
          category: category.value,
          audience: 'all',
          pinned: pinned.value,
          date: DateTime.now(),
          author: Get.find<AuthService>().user.value?.name ?? 'Teacher',
          attachments: const [],
        ),
      );
      ToastHelper.show('teacher.notice_sent', kind: ToastKind.success);
      Get.back<void>();
    } on AppException catch (error) {
      ToastHelper.show(error.message, kind: ToastKind.error);
    } finally {
      saving.value = false;
    }
  }

  @override
  void onClose() {
    title.dispose();
    body.dispose();
    super.onClose();
  }
}
