import 'package:edunest/core/theme/tokens.dart';
import 'package:edunest/core/utils/extensions.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

Future<T?> showAppSheet<T>({required Widget child}) {
  return Get.bottomSheet<T>(
    child,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
  );
}

class AppBottomSheet extends StatelessWidget {
  const AppBottomSheet({required this.child, this.title, super.key});

  final Widget child;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.88),
        decoration: BoxDecoration(
          color: context.colors.surfaceContainerLowest,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.colors.outline,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            if (title != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(title!.tr, style: context.text.headlineSmall),
                ),
              ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<bool> confirmSheet({
  required String title,
  required String body,
  required String confirm,
}) async {
  final result = await showAppSheet<bool>(
    child: AppBottomSheet(
      title: title,
      child: Builder(
        builder: (context) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(body.tr, style: context.text.bodyMedium),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => Get.back(result: true),
              child: Text(confirm.tr),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Get.back(result: false),
              child: Text('common.cancel'.tr),
            ),
          ],
        ),
      ),
    ),
  );
  return result ?? false;
}
