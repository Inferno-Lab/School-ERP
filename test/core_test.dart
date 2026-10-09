import 'package:edunest/core/config/app_config.dart';
import 'package:edunest/core/services/storage_service.dart';
import 'package:edunest/core/services/theme_service.dart';
import 'package:edunest/core/theme/app_theme.dart';
import 'package:edunest/core/utils/app_exception.dart';
import 'package:edunest/core/utils/status.dart';
import 'package:edunest/data/datasources/mock_json_datasource.dart';
import 'package:edunest/data/models/academics.dart';
import 'package:edunest/data/models/campus.dart';
import 'package:edunest/data/models/user.dart';
import 'package:edunest/data/repositories/academic_repository.dart';
import 'package:edunest/data/repositories/auth_repository.dart';
import 'package:edunest/data/repositories/campus_repository.dart';
import 'package:edunest/data/repositories/directory_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'support/harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(bootMock);

  tearDown(Get.reset);

  test('mock json loads relative dates and rejects simulated errors', () async {
    final source = Get.find<MockJsonDataSource>();
    await source.ensureLoaded();
    expect(source.users.map((user) => user.id), contains('usr_aarav'));
    expect(source.school?.name, 'Greenfield International School');
    expect(source.attendance, isNotEmpty);
    final sample = source.attendance.first.date;
    expect(sample.isAfter(DateTime.now().subtract(const Duration(days: 120))), isTrue);

    AppConfig.simulateErrors.value = true;
    await expectLater(source.guard(() => 1), throwsA(isA<AppException>()));
    AppConfig.simulateErrors.value = false;
  });

  test('theme choices survive in memory storage', () async {
    final storage = Get.find<StorageService>();
    final themes = Get.find<ThemeService>();
    await themes.setMode(AppThemeMode.amoled);
    await themes.setTextScale(1.15);
    await themes.setLocale(const Locale('hi'));

    final restored = ThemeService(storage)..load();
    expect(restored.mode.value, AppThemeMode.amoled);
    expect(restored.textScale.value, 1.15);
    expect(restored.locale.value.languageCode, 'hi');
  });

  test('auth, fees, homework, notices, and chat repositories', () async {
    final auth = Get.find<AuthRepository>();
    final student = await auth.login(
      email: 'aarav.sharma@edunest.app',
      password: AppConfig.demoPassword,
    );
    expect(student.role, UserRole.student);
    expect(
      () => auth.login(email: student.email, password: 'nope'),
      throwsA(isA<AppException>()),
    );
    expect(
      () => auth.loginWithOtp(email: student.email, otp: '000000'),
      throwsA(isA<AppException>()),
    );

    final fees = Get.find<FeeRepository>();
    final before = await fees.forStudent('stu_aarav');
    final due = before!.installments.firstWhere(
      (item) => moneyStatus(item) == MoneyStatus.overdue || moneyStatus(item) == MoneyStatus.due,
    );
    await fees.pay(studentId: 'stu_aarav', installmentId: due.id, method: 'upi');
    final after = await fees.forStudent('stu_aarav');
    expect(after!.installments.firstWhere((item) => item.id == due.id).paid, isTrue);

    final homework = Get.find<HomeworkRepository>();
    final work = await homework.forClass('cls_8a');
    expect(work, isNotEmpty);
    await homework.submit(
      homeworkId: work.first.id,
      studentId: 'stu_aarav',
      fileName: 'scan.jpg',
    );
    final updated = await homework.byId(work.first.id);
    expect(updated!.forStudent('stu_aarav')?.status, HomeworkStatus.submitted);

    final notices = Get.find<NoticeRepository>();
    final count = (await notices.all()).length;
    await notices.post(
      Notice(
        id: 'nt_test',
        title: 'Sports day lanes',
        body: 'House lanes are posted outside the gym.',
        category: 'sports',
        audience: 'all',
        pinned: true,
        date: DateTime.now(),
        author: 'Office',
        attachments: const [],
      ),
    );
    expect((await notices.all()).length, count + 1);

    final inbox = await Get.find<ChatRepository>().inbox('usr_aarav');
    expect(inbox.threads, isNotEmpty);

    final school = await Get.find<DirectoryRepository>().school();
    expect(school.name, contains('Greenfield'));
    final days = await Get.find<AttendanceRepository>().forStudent('stu_aarav');
    expect(days, isNotEmpty);
  });
}
