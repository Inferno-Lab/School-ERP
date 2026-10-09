import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';

class ConnectivityService extends GetxService {
  final isOnline = true.obs;
  StreamSubscription<List<ConnectivityResult>>? _sub;

  @override
  void onInit() {
    super.onInit();
    _sub = Connectivity().onConnectivityChanged.listen(_apply);
    unawaited(_prime());
  }

  Future<void> _prime() async {
    final current = await Connectivity().checkConnectivity();
    _apply(current);
  }

  void _apply(List<ConnectivityResult> results) {
    isOnline.value = results.any((result) => result != ConnectivityResult.none);
  }

  @override
  void onClose() {
    unawaited(_sub?.cancel());
    super.onClose();
  }
}
