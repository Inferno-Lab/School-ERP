import 'package:edunest/core/config/app_config.dart';
import 'package:edunest/core/utils/app_exception.dart';
import 'package:edunest/data/datasources/mock_json_datasource.dart';
import 'package:edunest/data/datasources/remote_datasource.dart';
import 'package:edunest/data/models/user.dart';

abstract class AuthRepository {
  Future<AppUser> login({required String email, required String password});

  Future<AppUser> loginWithOtp({required String email, required String otp});

  Future<AppUser> loginAs(UserRole role);
}

class MockAuthRepository implements AuthRepository {
  MockAuthRepository(this._ds);

  final MockJsonDataSource _ds;

  @override
  Future<AppUser> login({required String email, required String password}) {
    return _ds.guard(() => _match(email, password: password));
  }

  @override
  Future<AppUser> loginWithOtp({required String email, required String otp}) {
    return _ds.guard(() {
      if (otp != AppConfig.demoOtp) {
        throw const AppException('errors.bad_otp');
      }
      return _match(email);
    });
  }

  @override
  Future<AppUser> loginAs(UserRole role) {
    return _ds.guard(() {
      const ids = {
        UserRole.student: 'usr_aarav',
        UserRole.parent: 'usr_priya',
        UserRole.teacher: 'usr_kavita',
      };
      return _byId(ids[role]!);
    });
  }

  AppUser _match(String email, {String? password}) {
    final needle = email.trim().toLowerCase();
    for (final user in _ds.users) {
      if (user.email.toLowerCase() != needle) continue;
      if (password != null && user.password != password) {
        throw const AppException('errors.bad_login');
      }
      return user;
    }
    throw const AppException('errors.bad_login');
  }

  AppUser _byId(String id) {
    for (final user in _ds.users) {
      if (user.id == id) return user;
    }
    throw const AppException('errors.bad_login');
  }
}

class RemoteAuthRepository implements AuthRepository {
  RemoteAuthRepository(this._remote);

  final RemoteDataSource _remote;

  @override
  Future<AppUser> login({required String email, required String password}) async {
    final json = await _remote.post('/auth/login', {
      'email': email,
      'password': password,
    });
    return AppUser.fromJson(Map<String, dynamic>.from(json as Map));
  }

  @override
  Future<AppUser> loginWithOtp({
    required String email,
    required String otp,
  }) async {
    final json = await _remote.post('/auth/otp', {'email': email, 'otp': otp});
    return AppUser.fromJson(Map<String, dynamic>.from(json as Map));
  }

  @override
  Future<AppUser> loginAs(UserRole role) async {
    final json = await _remote.post('/auth/demo', {'role': role.name});
    return AppUser.fromJson(Map<String, dynamic>.from(json as Map));
  }
}
