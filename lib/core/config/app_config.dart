import 'package:get/get.dart';

/// Single place for the product name and the mock/remote switch.
class AppConfig {
  const AppConfig._();

  static const appName = 'EduNest';

  /// Per-school build values; a school's build profile replaces these.
  static const schoolName = 'Greenfield International School';
  static const schoolTagline = 'Curiosity first. Kindness always.';
  static const logoAsset = 'assets/images/logo.svg';
  static const version = '2.0.0';
  static const build = 210;

  /// Flip to false to route every repository through the remote stub.
  static bool useMockData = true;

  static int mockDelayMinMs = 400;
  static int mockDelayMaxMs = 900;

  /// Design system "Slow network": off answers mock calls almost at once.
  static final slowNetwork = true.obs;

  /// Toggled from Settings so loading and error states can be demoed.
  static final simulateErrors = false.obs;

  static const demoPassword = 'demo123';
  static const demoOtp = '123456';
}
