import 'package:edunest/core/utils/loadable.dart';
import 'package:edunest/data/models/campus.dart';
import 'package:edunest/data/repositories/campus_repository.dart';
import 'package:get/get.dart';

class NoticesController extends GetxController with Loadable {
  final filter = 'all'.obs;
  final selectedId = RxnString();
  List<Notice> items = [];

  List<Notice> get visible {
    final list = [...items]..sort((a, b) {
      if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
      return b.date.compareTo(a.date);
    });
    if (filter.value == 'all') return list;
    return list.where((item) => item.category == filter.value).toList();
  }

  String? get pick => selectedId.value;

  set pick(String? id) => selectedId.value = id;

  Notice? get selected {
    final current = visible;
    if (current.isEmpty) return null;
    final id = selectedId.value;
    if (id != null) {
      for (final item in current) {
        if (item.id == id) return item;
      }
    }
    return current.first;
  }

  Notice? byId(String id) {
    for (final item in items) {
      if (item.id == id) return item;
    }
    return null;
  }

  @override
  Future<void> load() => run(() async {
    items = await Get.find<NoticeRepository>().all();
  }, isEmpty: () => items.isEmpty);
}

class NoticeDetailController extends GetxController with Loadable {
  Notice? notice;

  @override
  Future<void> load() => run(() async {
    final id = Get.parameters['id'];
    final items = await Get.find<NoticeRepository>().all();
    for (final item in items) {
      if (item.id == id) notice = item;
    }
  }, isEmpty: () => notice == null);
}
