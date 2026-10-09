import 'package:cached_network_image/cached_network_image.dart';
import 'package:edunest/core/services/auth_service.dart';
import 'package:edunest/core/utils/app_exception.dart';
import 'package:edunest/core/utils/formatters.dart';
import 'package:edunest/core/utils/loadable.dart';
import 'package:edunest/core/widgets/feature_page.dart';
import 'package:edunest/core/widgets/states.dart';
import 'package:edunest/core/widgets/toast.dart';
import 'package:edunest/data/models/campus.dart';
import 'package:edunest/data/repositories/campus_repository.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LibraryController extends GetxController with Loadable {
  final query = ''.obs;
  List<LibraryBook> books = [];

  List<LibraryBook> get visible {
    final needle = query.value.trim().toLowerCase();
    if (needle.isEmpty) return books;
    return books.where((book) {
      return book.title.toLowerCase().contains(needle) ||
          book.author.toLowerCase().contains(needle) ||
          book.category.toLowerCase().contains(needle);
    }).toList();
  }

  @override
  Future<void> load() => run(() async {
    books = await Get.find<LibraryRepository>().all();
  }, isEmpty: () => books.isEmpty);

  Future<void> reserve(LibraryBook book) async {
    final id = Get.find<AuthService>().activeStudentId.value;
    if (id == null) return;
    try {
      await Get.find<LibraryRepository>().reserve(bookId: book.id, studentId: id);
      ToastHelper.show('library.reserved', kind: ToastKind.success);
    } on AppException catch (error) {
      ToastHelper.show(error.message, kind: ToastKind.error);
    }
  }
}

class LibraryView extends GetView<LibraryController> {
  const LibraryView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => FeaturePage(
        title: 'library.title',
        subtitle: 'library.subtitle',
        onRefresh: controller.load,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          child: Column(
            children: [
              TextField(
                decoration: InputDecoration(hintText: 'common.search'.tr),
                onChanged: (value) => controller.query.value = value,
              ),
              const SizedBox(height: 12),
              ViewStateView(
                state: controller.state.value,
                onRetry: controller.load,
                errorKey: controller.errorMessage.value,
                child: Column(
                  children: [
                    for (final book in controller.visible)
                      Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: CachedNetworkImage(
                              imageUrl: book.coverUrl,
                              width: 42,
                              height: 56,
                              fit: BoxFit.cover,
                              errorWidget: (_, _, _) => const SizedBox(width: 42, height: 56),
                            ),
                          ),
                          title: Text(book.title),
                          subtitle: Text(
                            book.borrowedBy == null
                                ? '${book.author} · ${'library.available'.tr}'
                                : '${book.author} · ${book.dueDate == null ? 'library.borrowed'.tr : Formatters.fullDate(book.dueDate!)}',
                          ),
                          trailing: book.available
                              ? TextButton(
                                  onPressed: () => controller.reserve(book),
                                  child: Text('library.reserve'.tr),
                                )
                              : null,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
