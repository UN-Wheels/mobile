import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import '../domain/auth_request.dart';
import '../domain/user.dart';

class AuthApi {
  const AuthApi(this._dio, this._cookieJar);

  final Dio _dio;
  final CookieJar _cookieJar;

  Future<({String token, User user})> login(LoginRequest request) async {
    try {
      final loginRes = await _dio.post<dynamic>(
        '/auth/login',
        data: request.toJson(),
      );

      if (kDebugMode) {
        debugPrint('[AuthApi.login] status: ${loginRes.statusCode}');
        debugPrint('[AuthApi.login] data: ${loginRes.data}');
      }

      // Gateway sets the JWT as an httpOnly cookie. CookieManager captures it
      // automatically. GET /auth/me will now include the cookie header.
      final meRes = await _dio.get<dynamic>('/auth/me');

      if (kDebugMode) {
        debugPrint('[AuthApi.getMe] data: ${meRes.data}');
      }

      final user = _parseUser(meRes.data);
      if (user == null) {
        throw const ServerException('No se pudieron obtener los datos del usuario.');
      }

      // Read the token from the cookie jar to persist it in SecureStorage.
      // This lets the app restore the session across restarts via Bearer auth.
      final token = await _readTokenFromJar();
      if (token == null) {
        throw const ServerException(
          'El servidor no devolvió un token. Verifica las credenciales.',
        );
      }

      return (token: token, user: user);
    } on ApiException {
      rethrow;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> register(RegisterRequest request) async {
    try {
      final res = await _dio.post<dynamic>(
        '/auth/register',
        data: request.toJson(),
      );

      if (kDebugMode) {
        debugPrint('[AuthApi.register] status: ${res.statusCode}');
        debugPrint('[AuthApi.register] data: ${res.data}');
      }
    } on ApiException {
      rethrow;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<User> getMe() async {
    try {
      final res = await _dio.get<dynamic>('/auth/me');
      final user = _parseUser(res.data);
      if (user == null) {
        throw const ServerException('Respuesta de usuario inválida.');
      }
      return user;
    } on ApiException {
      rethrow;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post<void>('/auth/logout');
    } on DioException {
      // Ignorar errores — limpiar sesión local igualmente
    }
  }

  Future<User> updateProfile(Map<String, dynamic> data) async {
    try {
      final res = await _dio.put<dynamic>('/auth/me', data: data);
      final user = _parseUser(res.data);
      if (user == null) {
        throw const ServerException('Respuesta de perfil inválida.');
      }
      return user;
    } on ApiException {
      rethrow;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  // Reads the access_token cookie from the in-memory jar.
  // The base URL is e.g. "http://127.0.0.1:8080/api" — the cookie Path="/"
  // so it is accessible at the host root.
  Future<String?> _readTokenFromJar() async {
    try {
      final base = Uri.parse(_dio.options.baseUrl);
      final hostRoot = base.replace(path: '/');
      final cookies = await _cookieJar.loadForRequest(hostRoot);
      if (kDebugMode) {
        debugPrint('[AuthApi] cookies in jar: ${cookies.map((c) => c.name).toList()}');
      }
      return cookies
          .where((c) => c.name == 'access_token')
          .map((c) => c.value)
          .firstOrNull;
    } catch (_) {
      return null;
    }
  }

  // Convierte la respuesta en User — el gateway puede devolver el user
  // directamente o anidado en data/user.
  static User? _parseUser(dynamic data) {
    if (data == null) return null;
    Map<String, dynamic>? map;
    if (data is Map<String, dynamic>) {
      if (data.containsKey('user') && data['user'] is Map<String, dynamic>) {
        map = data['user'] as Map<String, dynamic>;
      } else if (data.containsKey('email') || data.containsKey('id')) {
        map = data;
      }
    }
    if (map == null) return null;
    return User.fromJson(map);
  }
}

final authApiProvider = Provider<AuthApi>((ref) {
  return AuthApi(ref.read(dioProvider), ref.read(cookieJarProvider));
});
