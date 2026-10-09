import 'package:edunest/core/services/auth_service.dart';
import 'package:edunest/core/utils/app_exception.dart';
import 'package:edunest/core/utils/loadable.dart';
import 'package:edunest/core/widgets/toast.dart';
import 'package:edunest/data/models/campus.dart';
import 'package:edunest/data/repositories/campus_repository.dart';
import 'package:get/get.dart';

class EventsController extends GetxController with Loadable {
  List<SchoolEvent> items = [];

  @override
  Future<void> load() => run(() async {
    items = await Get.find<EventRepository>().all();
    items.sort((a, b) => a.date.compareTo(b.date));
  }, isEmpty: () => items.isEmpty);

  SchoolEvent? byId(String? id) {
    for (final item in items) {
      if (item.id == id) return item;
    }
    return null;
  }

  Future<void> rsvp(String eventId, RsvpStatus status) async {
    final userId = Get.find<AuthService>().user.value?.id;
    if (userId == null) return;
    try {
      await Get.find<EventRepository>().rsvp(
        eventId: eventId,
        userId: userId,
        status: status,
      );
      ToastHelper.show('events.saved', kind: ToastKind.success);
    } on AppException catch (error) {
      ToastHelper.show(error.message, kind: ToastKind.error);
    }
  }
}
