import 'package:edunest/core/config/app_config.dart';
import 'package:edunest/core/services/auth_service.dart';
import 'package:edunest/core/services/session_bus.dart';
import 'package:edunest/core/services/storage_service.dart';
import 'package:edunest/core/services/theme_service.dart';
import 'package:edunest/core/theme/app_colors.dart';
import 'package:edunest/core/theme/app_theme.dart';
import 'package:edunest/core/translations/app_translations.dart';
import 'package:edunest/data/datasources/mock_json_datasource.dart';
import 'package:edunest/data/models/user.dart';
import 'package:edunest/data/repositories/academic_repository.dart';
import 'package:edunest/data/repositories/auth_repository.dart';
import 'package:edunest/data/repositories/campus_repository.dart';
import 'package:edunest/data/repositories/directory_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';

Future<void> bootMock() async {
  await initializeDateFormatting();
  Get.reset();
  Get.testMode = true;
  AppConfig.useMockData = true;
  AppConfig.mockDelayMinMs = 0;
  AppConfig.mockDelayMaxMs = 0;
  AppConfig.simulateErrors.value = false;

  final storage = StorageService(memory: <String, dynamic>{});
  Get
    ..put<StorageService>(storage, permanent: true)
    ..put<ThemeService>(ThemeService(storage)..load(), permanent: true)
    ..put<AuthService>(AuthService(storage), permanent: true)
    ..put<SessionBus>(SessionBus(), permanent: true);

  final source = Get.put(MockJsonDataSource(), permanent: true);
  Get
    ..put<AuthRepository>(MockAuthRepository(source), permanent: true)
    ..put<DirectoryRepository>(MockDirectoryRepository(source), permanent: true)
    ..put<AttendanceRepository>(MockAttendanceRepository(source), permanent: true)
    ..put<TimetableRepository>(MockTimetableRepository(source), permanent: true)
    ..put<HomeworkRepository>(MockHomeworkRepository(source), permanent: true)
    ..put<ExamRepository>(MockExamRepository(source), permanent: true)
    ..put<FeeRepository>(MockFeeRepository(source), permanent: true)
    ..put<NoticeRepository>(MockNoticeRepository(source), permanent: true)
    ..put<EventRepository>(MockEventRepository(source), permanent: true)
    ..put<ChatRepository>(MockChatRepository(source), permanent: true)
    ..put<LibraryRepository>(MockLibraryRepository(source), permanent: true)
    ..put<TransportRepository>(MockTransportRepository(source), permanent: true)
    ..put<LeaveRepository>(MockLeaveRepository(source), permanent: true)
    ..put<GalleryRepository>(MockGalleryRepository(source), permanent: true)
    ..put<NotificationRepository>(
      MockNotificationRepository(source),
      permanent: true,
    );
}

Future<T?> real<T>(WidgetTester tester, Future<T> Function() body) {
  return tester.runAsync(body);
}

Future<AppUser> signIn(UserRole role) async {
  final user = await Get.find<AuthRepository>().loginAs(role);
  await Get.find<AuthService>().setSession(user);
  return user;
}

Widget testApp({Widget? home, List<GetPage<dynamic>> pages = const []}) {
  return GetMaterialApp(
    translations: AppTranslations(),
    locale: const Locale('en'),
    fallbackLocale: const Locale('en'),
    theme: AppTheme.build(AppColors.light),
    home: pages.isEmpty ? home : null,
    initialRoute: pages.isEmpty ? null : pages.first.name,
    getPages: pages,
  );
}
