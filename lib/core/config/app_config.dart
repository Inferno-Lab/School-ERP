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

  /// Mock calls answer almost at once, like a good connection.
  static int mockDelayMinMs = 30;
  static int mockDelayMaxMs = 90;

  /// Feature switches. Off until the screen and the backend for it exist, so unfinished work
  /// never reaches families. A school's build profile can turn them on with --dart-define.
  static const assistantEnabled = bool.fromEnvironment('ASSISTANT');

  /// Design system "Empty school": a brand-new school with people but no content,
  /// to check every empty state. `--dart-define=EMPTY_DATA=true` starts that way.
  static final emptyData = const bool.fromEnvironment('EMPTY_DATA').obs;

  /// Design system "Slow network": 0.4 to 0.9 s per call, to test loading states.
  static final slowNetwork = false.obs;

  /// Toggled from Settings so loading and error states can be demoed.
  static final simulateErrors = false.obs;

  static const demoPassword = 'demo123';
  static const demoOtp = '123456';
}
