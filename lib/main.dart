import 'package:edunest/app.dart';
import 'package:edunest/core/services/auth_service.dart';
import 'package:edunest/core/services/connectivity_service.dart';
import 'package:edunest/core/services/session_bus.dart';
import 'package:edunest/core/services/storage_service.dart';
import 'package:edunest/core/services/theme_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  await initializeDateFormatting();
  final storage = await StorageService().init();
  Get.put(storage, permanent: true);
  final themes = ThemeService(storage)..load();
  Get.put(themes, permanent: true);
  final auth = AuthService(storage)..restore();
  Get.put(auth, permanent: true);
  Get.put(ConnectivityService(), permanent: true);
  Get.put(SessionBus(), permanent: true);
  runApp(const EduNestApp());
}
