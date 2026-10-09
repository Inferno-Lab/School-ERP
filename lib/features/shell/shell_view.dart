import 'dart:async';

import 'package:edunest/core/widgets/floating_nav_bar.dart';
import 'package:edunest/features/chat/views/chat_list_view.dart';
import 'package:edunest/features/dashboard/views/academics_view.dart';
import 'package:edunest/features/dashboard/views/dashboard_view.dart';
import 'package:edunest/features/fees/views/fees_view.dart';
import 'package:edunest/features/notices/views/notices_view.dart';
import 'package:edunest/features/profile/views/profile_view.dart';
import 'package:edunest/features/shell/shell_controller.dart';
import 'package:edunest/features/teacher_tools/views/teacher_home_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class ShellView extends GetView<ShellController> {
  const ShellView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final teacher = controller.isTeacher;
      final destinations = teacher ? _teacherNav : _familyNav;
      final pages = teacher ? _teacherPages : _familyPages;
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) unawaited(controller.onBack());
        },
        child: AdaptiveShell(
          index: controller.index.value,
          destinations: destinations,
          onChanged: (value) => controller.index.value = value,
          child: IndexedStack(index: controller.index.value, children: pages),
        ),
      );
    });
  }
}

const _familyNav = [
  NavDestination(
    icon: PhosphorIconsRegular.house,
    activeIcon: PhosphorIconsFill.house,
    label: 'nav.home',
  ),
  NavDestination(
    icon: PhosphorIconsRegular.books,
    activeIcon: PhosphorIconsFill.books,
    label: 'nav.academics',
  ),
  NavDestination(
    icon: PhosphorIconsRegular.wallet,
    activeIcon: PhosphorIconsFill.wallet,
    label: 'nav.fees',
  ),
  NavDestination(
    icon: PhosphorIconsRegular.chatCircle,
    activeIcon: PhosphorIconsFill.chatCircle,
    label: 'nav.chat',
  ),
  NavDestination(
    icon: PhosphorIconsRegular.user,
    activeIcon: PhosphorIconsFill.user,
    label: 'nav.profile',
  ),
];

const _teacherNav = [
  NavDestination(
    icon: PhosphorIconsRegular.house,
    activeIcon: PhosphorIconsFill.house,
    label: 'nav.home',
  ),
  NavDestination(
    icon: PhosphorIconsRegular.chalkboardTeacher,
    activeIcon: PhosphorIconsFill.chalkboardTeacher,
    label: 'nav.classes',
  ),
  NavDestination(
    icon: PhosphorIconsRegular.megaphone,
    activeIcon: PhosphorIconsFill.megaphone,
    label: 'nav.notices',
  ),
  NavDestination(
    icon: PhosphorIconsRegular.chatCircle,
    activeIcon: PhosphorIconsFill.chatCircle,
    label: 'nav.chat',
  ),
  NavDestination(
    icon: PhosphorIconsRegular.user,
    activeIcon: PhosphorIconsFill.user,
    label: 'nav.profile',
  ),
];

const _familyPages = [
  DashboardView(),
  AcademicsView(),
  FeesView(),
  ChatListView(),
  ProfileView(),
];

const _teacherPages = [
  TeacherHomeView(),
  TeacherClassesView(),
  NoticesView(),
  ChatListView(),
  ProfileView(),
];
