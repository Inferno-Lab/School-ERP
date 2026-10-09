import 'package:edunest/app.dart';
import 'package:edunest/core/routes/app_routes.dart';
import 'package:edunest/features/auth/controllers/splash_controller.dart';
import 'package:edunest/features/auth/views/onboarding_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'support/harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('splash advances to onboarding', (tester) async {
    await bootMock();
    Get.testMode = false;
    await tester.pumpWidget(const EduNestApp());
    await tester.pump();
    expect(find.text('EduNest'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1700));
    await tester.pump(const Duration(milliseconds: 800));
    expect(Get.currentRoute, AppRoutes.onboarding);
    expect(find.text('Everything Your School Needs, in One Place'), findsOneWidget);
  });

  testWidgets('onboarding next, previous, and skip reach login', (tester) async {
    await bootMock();
    Get.testMode = false;
    await tester.pumpWidget(
      testApp(
        pages: [
          GetPage(
            name: AppRoutes.onboarding,
            page: () => const OnboardingView(),
            binding: BindingsBuilder<void>(() {
              Get.put(OnboardingController());
            }),
          ),
          GetPage(
            name: AppRoutes.login,
            page: () => const Scaffold(body: Text('Login ready')),
          ),
        ],
      ),
    );
    await tester.pump();
    expect(find.text('Everything Your School Needs, in One Place'), findsOneWidget);
    expect(find.text('Previous'), findsNothing);

    await tester.tap(find.text('Next'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Previous'), findsOneWidget);
    expect(find.text('Better Connections. Better Learning.'), findsOneWidget);

    await tester.tap(find.text('Previous'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Everything Your School Needs, in One Place'), findsOneWidget);

    await tester.tap(find.text('Skip'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(Get.currentRoute, AppRoutes.login);
    expect(find.text('Login ready'), findsOneWidget);
  });

  testWidgets('onboarding fits a small phone', (tester) async {
    await bootMock();
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      testApp(
        pages: [
          GetPage(
            name: AppRoutes.onboarding,
            page: () => const OnboardingView(),
            binding: BindingsBuilder<void>(() {
              Get.put(OnboardingController());
            }),
          ),
        ],
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text('Everything Your School Needs, in One Place'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
  });
}
