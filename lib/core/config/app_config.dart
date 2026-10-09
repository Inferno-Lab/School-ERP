import 'package:get/get.dart';

/// Single place for the product name and the mock/remote switch.
class AppConfig {
  const AppConfig._();

  static const appName = 'EduNest';
  static const logoAsset = 'assets/images/logo.svg';
  static const version = '1.0.0';

  /// Flip to false to route every repository through the remote stub.
  static bool useMockData = true;

  static int mockDelayMinMs = 400;
  static int mockDelayMaxMs = 900;

  /// Toggled from Settings so loading and error states can be demoed.
  static final simulateErrors = false.obs;

  static const demoPassword = 'demo123';
  static const demoOtp = '123456';
}
