import 'package:edunest/core/services/auth_service.dart';
import 'package:edunest/core/utils/loadable.dart';
import 'package:edunest/core/utils/status.dart';
import 'package:edunest/data/models/academics.dart';
import 'package:edunest/data/repositories/academic_repository.dart';
import 'package:edunest/data/repositories/directory_repository.dart';
import 'package:get/get.dart';

class TimetableController extends GetxController with Loadable {
  final dayIndex = (DateTime.now().weekday - 1).clamp(0, 5).obs;
  List<TimetableDay> days = [];
  final teachers = <String, String>{}.obs;

  static const keys = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat'];

  TimetableDay? get selected {
    final key = keys[dayIndex.value];
    for (final day in days) {
      if (day.day == key) return day;
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
      days = await Get.find<TimetableRepository>().forClass(student.classId);
      final people = await Get.find<DirectoryRepository>().teachers();
      teachers
        ..clear()
        ..addAll({for (final teacher in people) teacher.id: teacher.name});
    }, isEmpty: () => days.isEmpty);
  }

  bool isNow(PeriodSlot period) {
    if (weekdayKey(DateTime.now()) != keys[dayIndex.value]) return false;
    final now = DateTime.now();
    final current = now.hour * 60 + now.minute;
    int clock(String value) {
      final parts = value.split(':');
      return int.parse(parts[0]) * 60 + int.parse(parts[1]);
    }

    return current >= clock(period.start) && current < clock(period.end);
  }
}
