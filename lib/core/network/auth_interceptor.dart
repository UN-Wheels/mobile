import 'package:dio/dio.dart';

import '../storage/secure_storage.dart';

class AuthInterceptor extends Interceptor {
  const AuthInterceptor(this._storage);

  final SecureStorage _storage;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storage.getToken();
    // Only inject if not already present (e.g. login flow sets it explicitly).
    if (token != null && !options.headers.containsKey('Authorization')) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    return handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // Only invalidate the session when the auth service itself rejects the
    // token (i.e. the /auth/* endpoints return 401). A 401 from an unrelated
    // microservice (chat, routes…) must NOT wipe the stored token — doing so
    // cascades into every subsequent request also losing auth.
    final path = err.requestOptions.path;
    if (err.response?.statusCode == 401 && path.startsWith('/auth')) {
      await _storage.deleteToken();
    }
    return handler.next(err);
  }
}
