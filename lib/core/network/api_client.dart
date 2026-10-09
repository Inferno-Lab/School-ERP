import 'package:edunest/core/utils/app_exception.dart';

/// Stub HTTP client. Implement this when a real backend is ready.
class ApiClient {
  Future<dynamic> get(String path, {Map<String, dynamic>? query}) async {
    throw const AppException('errors.remote_unconfigured');
  }

  Future<dynamic> post(String path, Map<String, dynamic> body) async {
    throw const AppException('errors.remote_unconfigured');
  }

  Future<dynamic> patch(String path, Map<String, dynamic> body) async {
    throw const AppException('errors.remote_unconfigured');
  }
}
