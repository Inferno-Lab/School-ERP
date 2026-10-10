import 'package:edunest/core/routes/app_routes.dart';
import 'package:edunest/core/routes/middlewares.dart';
import 'package:edunest/core/services/auth_service.dart';
import 'package:edunest/core/theme/tokens.dart';
import 'package:edunest/data/models/user.dart';
import 'package:edunest/features/attendance/controllers/attendance_controller.dart';
import 'package:edunest/features/attendance/views/attendance_view.dart';
import 'package:edunest/features/auth/controllers/login_controller.dart';
import 'package:edunest/features/auth/controllers/splash_controller.dart';
import 'package:edunest/features/auth/views/login_view.dart';
import 'package:edunest/features/auth/views/onboarding_view.dart';
import 'package:edunest/features/auth/views/splash_view.dart';
import 'package:edunest/features/chat/controllers/chat_controller.dart';
import 'package:edunest/features/chat/views/chat_list_view.dart';
import 'package:edunest/features/dashboard/controllers/dashboard_controller.dart';
import 'package:edunest/features/events/controllers/events_controller.dart';
import 'package:edunest/features/events/views/events_view.dart';
import 'package:edunest/features/exams_results/controllers/results_controller.dart';
import 'package:edunest/features/exams_results/views/results_view.dart';
import 'package:edunest/features/fees/controllers/fees_controller.dart';
import 'package:edunest/features/fees/views/fees_view.dart';
import 'package:edunest/features/gallery/views/gallery_view.dart';
import 'package:edunest/features/homework/controllers/homework_controller.dart';
import 'package:edunest/features/homework/views/homework_scan_view.dart';
import 'package:edunest/features/homework/views/homework_view.dart';
import 'package:edunest/features/leave/views/leave_view.dart';
import 'package:edunest/features/library/views/library_view.dart';
import 'package:edunest/features/notices/controllers/notices_controller.dart';
import 'package:edunest/features/notices/views/notices_view.dart';
import 'package:edunest/features/notifications/views/notifications_view.dart';
import 'package:edunest/features/profile/views/profile_view.dart';
import 'package:edunest/features/search/search_view.dart';
import 'package:edunest/features/settings/views/design_system_view.dart';
import 'package:edunest/features/settings/views/settings_view.dart';
import 'package:edunest/features/shell/shell_controller.dart';
import 'package:edunest/features/shell/shell_view.dart';
import 'package:edunest/features/teacher_tools/controllers/teacher_controller.dart';
import 'package:edunest/features/teacher_tools/views/teacher_tools_view.dart';
import 'package:edunest/features/timetable/controllers/timetable_controller.dart';
import 'package:edunest/features/timetable/views/timetable_view.dart';
import 'package:edunest/features/transport/views/transport_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ShellBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(ShellController.new);
    final teacher = Get.find<AuthService>().role == UserRole.teacher;
    Get
      ..lazyPut(ChatListController.new)
      ..lazyPut(ProfileController.new)
      ..lazyPut(NoticesController.new);
    if (teacher) {
      Get
        ..lazyPut(TeacherHomeController.new)
        ..lazyPut(TeacherClassesController.new);
    } else {
      Get
        ..lazyPut(DashboardController.new)
        ..lazyPut(FeesController.new);
    }
  }
}

class AppPages {
  const AppPages._();

  static final pages = <GetPage<dynamic>>[
    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashView(),
      binding: BindingsBuilder<void>(() {
        Get.put<SplashController>(SplashController());
      }),
      transition: Transition.fadeIn,
    ),
    GetPage(name: AppRoutes.onboarding, page: () => const OnboardingView(), binding: BindingsBuilder<void>(() => Get.lazyPut(OnboardingController.new)), transition: Transition.fadeIn),
    GetPage(name: AppRoutes.login, page: () => const LoginView(), binding: BindingsBuilder<void>(() => Get.lazyPut(LoginController.new)), transition: Transition.fadeIn),
    GetPage(name: AppRoutes.shell, page: () => const ShellView(), binding: ShellBinding(), middlewares: [AuthMiddleware()], transition: Transition.fadeIn, transitionDuration: AppDurations.medium),
    _page(AppRoutes.attendance, const AttendanceView(), AttendanceController.new),
    _page(AppRoutes.homework, const HomeworkView(), HomeworkController.new),
    GetPage(
      name: AppRoutes.homeworkDetail,
      page: () => const HomeworkDetailView(),
      binding: BindingsBuilder<void>(() {
        Get
          ..lazyPut(HomeworkDetailController.new)
          ..lazyPut(HomeworkController.new);
      }),
      middlewares: [AuthMiddleware()],
      transition: Transition.fadeIn,
      transitionDuration: AppDurations.medium,
    ),
    GetPage(name: AppRoutes.homeworkScan, page: () => const HomeworkScanView(), middlewares: [AuthMiddleware()], transition: Transition.downToUp),
    _page(AppRoutes.timetable, const TimetableView(), TimetableController.new),
    _page(AppRoutes.results, const ResultsView(), ResultsController.new),
    _page(AppRoutes.fees, const FeesView(), FeesController.new),
    GetPage(name: AppRoutes.receipt, page: () => const ReceiptView(), middlewares: [AuthMiddleware()], transition: Transition.fadeIn),
    _page(AppRoutes.notices, const NoticesView(), NoticesController.new),
    _page(AppRoutes.noticeDetail, const NoticeDetailView(), NoticeDetailController.new),
    _page(AppRoutes.events, const EventsView(), EventsController.new),
    GetPage(name: AppRoutes.eventDetail, page: () => const EventDetailView(), binding: BindingsBuilder<void>(() => Get.lazyPut(EventsController.new, fenix: true)), middlewares: [AuthMiddleware()], transition: Transition.fadeIn),
    _page(AppRoutes.chatThread, const ChatThreadView(), ChatThreadController.new),
    _page(AppRoutes.library, const LibraryView(), LibraryController.new),
    _page(AppRoutes.transport, const TransportView(), TransportController.new),
    _page(AppRoutes.gallery, const GalleryView(), GalleryController.new),
    _page(AppRoutes.leave, const LeaveView(), LeaveController.new),
    _page(AppRoutes.leaveApply, const LeaveApplyView(), LeaveApplyController.new),
    GetPage(
      name: AppRoutes.search,
      page: () => const SearchView(),
      binding: BindingsBuilder<void>(() => Get.lazyPut(AppSearchController.new)),
      middlewares: [AuthMiddleware()],
      transition: Transition.fadeIn,
      transitionDuration: AppDurations.fast,
    ),
    _page(AppRoutes.notifications, const NotificationsView(), NotificationsController.new),
    GetPage(name: AppRoutes.settings, page: () => const SettingsView(), middlewares: [AuthMiddleware()], transition: Transition.cupertino, transitionDuration: AppDurations.medium),
    GetPage(name: AppRoutes.about, page: () => const AboutView(), middlewares: [AuthMiddleware()], transition: Transition.cupertino),
    GetPage(name: AppRoutes.help, page: () => const HelpView(), middlewares: [AuthMiddleware()], transition: Transition.cupertino),
    GetPage(name: AppRoutes.designSystem, page: () => const DesignSystemView(), middlewares: [AuthMiddleware()], transition: Transition.fadeIn),
    _teacher(AppRoutes.teacherAttendance, const MarkAttendanceView(), MarkAttendanceController.new),
    _teacher(AppRoutes.teacherAssign, const AssignHomeworkView(), AssignHomeworkController.new),
    _teacher(AppRoutes.teacherGrade, const GradingView(), GradingController.new),
    _teacher(AppRoutes.teacherMarks, const MarksEntryView(), MarksEntryController.new),
    _teacher(AppRoutes.teacherNotice, const PostNoticeView(), PostNoticeController.new),
  ];

  static GetPage<dynamic> _page<T extends GetxController>(
    String name,
    Widget page,
    InstanceBuilderCallback<T> controller,
  ) {
    return GetPage(
      name: name,
      page: () => page,
      binding: BindingsBuilder<void>(() => Get.lazyPut<T>(controller)),
      middlewares: [AuthMiddleware()],
      transition: Transition.fadeIn,
      transitionDuration: AppDurations.medium,
    );
  }

  static GetPage<dynamic> _teacher<T extends GetxController>(
    String name,
    Widget page,
    InstanceBuilderCallback<T> controller,
  ) {
    return GetPage(
      name: name,
      page: () => page,
      binding: BindingsBuilder<void>(() => Get.lazyPut<T>(controller)),
      middlewares: [
        AuthMiddleware(),
        RoleMiddleware([UserRole.teacher]),
      ],
      transition: Transition.fadeIn,
      transitionDuration: AppDurations.medium,
    );
  }
}
