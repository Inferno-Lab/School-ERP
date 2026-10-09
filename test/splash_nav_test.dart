import 'package:edunest/app.dart';
import 'package:edunest/core/routes/app_routes.dart';
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
    expect(find.text('The day, at a glance'), findsOneWidget);
  });
}
