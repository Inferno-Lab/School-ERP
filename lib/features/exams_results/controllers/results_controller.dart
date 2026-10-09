import 'package:edunest/core/services/auth_service.dart';
import 'package:edunest/core/utils/loadable.dart';
import 'package:edunest/data/models/academics.dart';
import 'package:edunest/data/repositories/academic_repository.dart';
import 'package:edunest/data/repositories/directory_repository.dart';
import 'package:get/get.dart';

class ResultsController extends GetxController with Loadable {
  final examIndex = 0.obs;
  List<Exam> exams = [];
  List<ExamResult> results = [];

  Exam? get exam => exams.isEmpty ? null : exams[examIndex.value.clamp(0, exams.length - 1)];

  ExamResult? get result {
    final current = exam;
    if (current == null) return null;
    for (final item in results) {
      if (item.examId == current.id) return item;
    }
    return null;
  }

  @override
  Future<void> load() async {
    final id = Get.find<AuthService>().activeStudentId.value;
    if (id == null) {
      await run(() async {}, isEmpty: () => true);
      return;
    }
    await run(() async {
      final student = await Get.find<DirectoryRepository>().student(id);
      exams = await Get.find<ExamRepository>().forClass(student.classId);
      results = await Get.find<ExamRepository>().resultsFor(id);
    }, isEmpty: () => exams.isEmpty);
  }
}
