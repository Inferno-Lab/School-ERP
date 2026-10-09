import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

abstract final class StorageKeys {
  static const themeMode = 'themeMode';
  static const accent = 'accent';
  static const textScale = 'textScale';
  static const onboardingSeen = 'onboardingSeen';
  static const sessionUser = 'sessionUser';
  static const activeStudent = 'activeStudent';
  static const dynamicColor = 'dynamicColor';
  static const reduceMotion = 'reduceMotion';
  static const simulateErrors = 'simulateErrors';
  static const locale = 'locale';
  static const notifyHomework = 'notifyHomework';
  static const notifyFees = 'notifyFees';
  static const notifyChat = 'notifyChat';
}

class StorageService extends GetxService {
  StorageService({Map<String, dynamic>? memory}) : _memory = memory;

  GetStorage? _box;
  final Map<String, dynamic>? _memory;

  Future<StorageService> init() async {
    if (_memory == null) {
      await GetStorage.init();
      _box = GetStorage();
    }
    return this;
  }

  T? read<T>(String key) {
    if (_memory != null) return _memory[key] as T?;
    return _box?.read<T>(key);
  }

  Future<void> write(String key, dynamic value) async {
    if (_memory != null) {
      _memory[key] = value;
      return;
    }
    await _box?.write(key, value);
  }

  Future<void> remove(String key) async {
    if (_memory != null) {
      _memory.remove(key);
      return;
    }
    await _box?.remove(key);
  }
}
