import 'dart:async';

import 'package:edunest/core/services/auth_service.dart';
import 'package:edunest/core/utils/loadable.dart';
import 'package:edunest/data/models/campus.dart';
import 'package:edunest/data/repositories/campus_repository.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

class TransportController extends GetxController with Loadable {
  TransportInfo? route;

  @override
  Future<void> load() async {
    final id = Get.find<AuthService>().activeStudentId.value;
    if (id == null) {
      await run(() async {}, isEmpty: () => true);
      return;
    }
    await run(() async {
      route = await Get.find<TransportRepository>().forStudent(id);
    }, isEmpty: () => route == null);
  }

  Future<void> callDriver() async {
    final phone = route?.driver.phone;
    if (phone == null) return;
    await launchUrl(Uri(scheme: 'tel', path: phone));
  }
}
