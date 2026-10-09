import 'dart:async';

import 'package:edunest/core/config/app_config.dart';
import 'package:edunest/core/services/storage_service.dart';
import 'package:edunest/core/theme/accent_palettes.dart';
import 'package:edunest/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ThemeService extends GetxService {
  ThemeService(this._storage);

  final StorageService _storage;

  final mode = AppThemeMode.system.obs;
  final accent = AccentPalette.all.first.obs;
  final textScale = 1.0.obs;
  final useDynamicColor = false.obs;
  final reduceMotion = false.obs;
  final locale = const Locale('en').obs;
  final notifyHomework = true.obs;
  final notifyFees = true.obs;
  final notifyChat = true.obs;

  void load() {
    mode.value = AppThemeMode.values.firstWhere(
      (item) => item.name == _storage.read<String>(StorageKeys.themeMode),
      orElse: () => AppThemeMode.system,
    );
    accent.value = AccentPalette.byName(
      _storage.read<String>(StorageKeys.accent) ?? AccentPreset.oceanBlue.name,
    );
    textScale.value = _storage.read<double>(StorageKeys.textScale) ?? 1;
    useDynamicColor.value = _storage.read<bool>(StorageKeys.dynamicColor) ?? false;
    reduceMotion.value = _storage.read<bool>(StorageKeys.reduceMotion) ?? false;
    final code = _storage.read<String>(StorageKeys.locale) ?? 'en';
    locale.value = Locale(code);
    notifyHomework.value = _storage.read<bool>(StorageKeys.notifyHomework) ?? true;
    notifyFees.value = _storage.read<bool>(StorageKeys.notifyFees) ?? true;
    notifyChat.value = _storage.read<bool>(StorageKeys.notifyChat) ?? true;
    AppConfig.simulateErrors.value =
        _storage.read<bool>(StorageKeys.simulateErrors) ?? false;
  }

  Future<void> setMode(AppThemeMode value) async {
    mode.value = value;
    await _storage.write(StorageKeys.themeMode, value.name);
  }

  Future<void> setAccent(AccentPalette value) async {
    accent.value = value;
    await _storage.write(StorageKeys.accent, value.preset.name);
  }

  Future<void> setTextScale(double value) async {
    textScale.value = value;
    await _storage.write(StorageKeys.textScale, value);
  }

  Future<void> setDynamicColor({required bool value}) async {
    useDynamicColor.value = value;
    await _storage.write(StorageKeys.dynamicColor, value);
  }

  Future<void> setReduceMotion({required bool value}) async {
    reduceMotion.value = value;
    await _storage.write(StorageKeys.reduceMotion, value);
  }

  Future<void> setLocale(Locale value) async {
    locale.value = value;
    await _storage.write(StorageKeys.locale, value.languageCode);
    if (!Get.testMode) unawaited(Get.updateLocale(value));
  }

  Future<void> setNotify({
    bool? homework,
    bool? fees,
    bool? chat,
  }) async {
    if (homework != null) {
      notifyHomework.value = homework;
      await _storage.write(StorageKeys.notifyHomework, homework);
    }
    if (fees != null) {
      notifyFees.value = fees;
      await _storage.write(StorageKeys.notifyFees, fees);
    }
    if (chat != null) {
      notifyChat.value = chat;
      await _storage.write(StorageKeys.notifyChat, chat);
    }
  }

  Future<void> setSimulateErrors({required bool value}) async {
    AppConfig.simulateErrors.value = value;
    await _storage.write(StorageKeys.simulateErrors, value);
  }
}
