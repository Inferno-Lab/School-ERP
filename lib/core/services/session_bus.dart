import 'package:get/get.dart';

/// Bumps whenever mock data changes so open screens can refresh.
class SessionBus extends GetxService {
  final revision = 0.obs;

  void bump() => revision.value++;
}
