import 'package:edunest/core/services/auth_service.dart';
import 'package:edunest/core/theme/tokens.dart';
import 'package:edunest/core/utils/extensions.dart';
import 'package:edunest/core/widgets/app_avatar.dart';
import 'package:edunest/core/widgets/app_bottom_sheet.dart';
import 'package:edunest/data/models/user.dart';
import 'package:edunest/data/repositories/directory_repository.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class ChildSwitcher extends StatelessWidget {
  const ChildSwitcher({this.name, this.avatarUrl, super.key});

  final String? name;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthService>();
    return Obx(() {
      if (auth.role != UserRole.parent) return const SizedBox.shrink();
      final label = name ?? 'home.switch_child'.tr;
      return Align(
        alignment: Alignment.centerLeft,
        child: ActionChip(
          avatar: AppAvatar(name: label, url: avatarUrl, size: 24),
          label: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width - 120),
            child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          onPressed: () => _open(context),
        ),
      );
    });
  }

  Future<void> _open(BuildContext context) async {
    final auth = Get.find<AuthService>();
    final directory = Get.find<DirectoryRepository>();
    final primary = context.colors.primary;
    final children = <Widget>[];
    for (final id in auth.user.value?.childIds ?? <String>[]) {
      final student = await directory.student(id);
      final schoolClass = await directory.schoolClass(student.classId);
      children.add(
        ListTile(
          leading: AppAvatar(name: student.name, url: student.avatarUrl),
          title: Text(student.name),
          subtitle: Text(schoolClass.label),
          trailing: auth.activeStudentId.value == id
              ? Icon(PhosphorIconsFill.checkCircle, color: primary)
              : null,
          onTap: () async {
            await auth.switchChild(id);
            Get.back<void>();
          },
        ),
      );
    }
    if (!context.mounted) return;
    await showAppSheet<void>(
      child: AppBottomSheet(
        title: 'home.switch_child',
        child: Column(children: children),
      ),
    );
  }
}

class QuickAction {
  const QuickAction(this.label, this.icon, this.onTap, this.tint);

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color tint;
}

class QuickActionGrid extends StatelessWidget {
  const QuickActionGrid({required this.actions, super.key});

  final List<QuickAction> actions;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: context.isWide ? 8 : 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      children: [
        for (final action in actions)
          InkWell(
            borderRadius: BorderRadius.circular(AppRadius.tile),
            onTap: action.onTap,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: action.tint.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(action.icon, color: action.tint),
                ),
                const SizedBox(height: 6),
                Text(
                  action.label.tr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.bodySmall,
                ),
              ],
            ),
          ),
      ],
    );
  }
}
