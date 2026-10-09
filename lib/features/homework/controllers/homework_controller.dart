import 'package:edunest/core/services/auth_service.dart';
import 'package:edunest/core/utils/app_exception.dart';
import 'package:edunest/core/utils/loadable.dart';
import 'package:edunest/core/widgets/toast.dart';
import 'package:edunest/data/models/academics.dart';
import 'package:edunest/data/models/student.dart';
import 'package:edunest/data/repositories/academic_repository.dart';
import 'package:edunest/data/repositories/directory_repository.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

class HomeworkController extends GetxController with Loadable {
  final tab = 0.obs;
  final selectedId = RxnString();
  List<Homework> items = [];
  String? studentId;
  Student? student;

  List<Homework> get visible {
    final status = switch (tab.value) {
      1 => HomeworkStatus.submitted,
      2 => HomeworkStatus.graded,
      _ => HomeworkStatus.pending,
    };
    return items.where((item) {
      final mine = studentId == null ? null : item.forStudent(studentId!);
      final current = mine?.status ?? HomeworkStatus.pending;
      return current == status;
    }).toList();
  }

  String? get pick => selectedId.value;

  set pick(String? id) => selectedId.value = id;

  Homework? get selected {
    final id = selectedId.value;
    if (id != null) {
      for (final item in items) {
        if (item.id == id) return item;
      }
    }
    return visible.firstOrNull;
  }

  @override
  Future<void> load() async {
    studentId = Get.find<AuthService>().activeStudentId.value;
    if (studentId == null) {
      await run(() async {}, isEmpty: () => true);
      return;
    }
    await run(() async {
      student = await Get.find<DirectoryRepository>().student(studentId!);
      items = await Get.find<HomeworkRepository>().forClass(student!.classId);
    }, isEmpty: () => false);
  }

  Future<void> submit(
    Homework homework, {
    required bool camera,
    bool sample = false,
  }) async {
    final id = studentId;
    if (id == null) return;
    var fileName = 'Homework_scan.jpg';
    if (!sample) {
      try {
        final file = await ImagePicker().pickImage(
          source: camera ? ImageSource.camera : ImageSource.gallery,
        );
        if (file == null) return;
        fileName = file.name;
      } on Exception {
        ToastHelper.show('errors.generic', kind: ToastKind.error);
        return;
      }
    }
    try {
      await Get.find<HomeworkRepository>().submit(
        homeworkId: homework.id,
        studentId: id,
        fileName: fileName,
      );
      ToastHelper.show('homework.sent', kind: ToastKind.success);
      Get.back<void>();
    } on AppException catch (error) {
      ToastHelper.show(error.message, kind: ToastKind.error);
    }
  }
}

class HomeworkDetailController extends GetxController with Loadable {
  Homework? item;

  @override
  Future<void> load() async {
    final id = Get.parameters['id'];
    if (id == null) {
      await run(() async {}, isEmpty: () => true);
      return;
    }
    await run(() async {
      item = await Get.find<HomeworkRepository>().byId(id);
    }, isEmpty: () => item == null);
  }
}
