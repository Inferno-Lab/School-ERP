import 'dart:convert';

import 'package:edunest/core/services/storage_service.dart';
import 'package:edunest/data/models/user.dart';
import 'package:get/get.dart';

class AuthService extends GetxService {
  AuthService(this._storage);

  final StorageService _storage;
  final user = Rxn<AppUser>();
  final activeStudentId = RxnString();

  bool get isLoggedIn => user.value != null;

  UserRole? get role => user.value?.role;

  void restore() {
    final raw = _storage.read<String>(StorageKeys.sessionUser);
    if (raw == null) return;
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) return;
    user.value = AppUser.fromJson(decoded);
    activeStudentId.value =
        _storage.read<String>(StorageKeys.activeStudent) ??
        user.value?.studentId ??
        user.value?.childIds.firstOrNull;
  }

  Future<void> setSession(AppUser next, {String? studentId}) async {
    user.value = next;
    final resolved =
        studentId ?? next.studentId ?? next.childIds.firstOrNull;
    activeStudentId.value = resolved;
    await _storage.write(StorageKeys.sessionUser, jsonEncode(next.toJson()));
    if (resolved == null) {
      await _storage.remove(StorageKeys.activeStudent);
    } else {
      await _storage.write(StorageKeys.activeStudent, resolved);
    }
  }

  Future<void> switchChild(String studentId) async {
    activeStudentId.value = studentId;
    await _storage.write(StorageKeys.activeStudent, studentId);
  }

  Future<void> updateAvatar(String url) async {
    final current = user.value;
    if (current == null) return;
    await setSession(current.copyWith(avatarUrl: url), studentId: activeStudentId.value);
  }

  Future<void> logout() async {
    user.value = null;
    activeStudentId.value = null;
    await _storage.remove(StorageKeys.sessionUser);
    await _storage.remove(StorageKeys.activeStudent);
  }
}
