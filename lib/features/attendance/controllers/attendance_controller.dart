import 'package:edunest/core/services/auth_service.dart';
import 'package:edunest/core/utils/extensions.dart';
import 'package:edunest/core/utils/loadable.dart';
import 'package:edunest/core/utils/status.dart';
import 'package:edunest/data/models/academics.dart';
import 'package:edunest/data/repositories/academic_repository.dart';
import 'package:get/get.dart';

class AttendanceController extends GetxController with Loadable {
  List<AttendanceDay> days = [];
  final focused = DateTime.now().obs;

  List<AttendanceDay> get monthDays => days.where((day) {
    return day.date.year == focused.value.year && day.date.month == focused.value.month;
  }).toList();

  AttendanceSummary get summary => AttendanceSummary.from(monthDays);

  AttendanceDay? on(DateTime date) {
    for (final day in days) {
      if (day.date.isSameDay(date)) return day;
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
      days = await Get.find<AttendanceRepository>().forStudent(id);
    }, isEmpty: () => days.isEmpty);
  }
}
