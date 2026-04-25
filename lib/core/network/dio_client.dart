import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/secure_storage.dart';
import 'auth_interceptor.dart';

/// In-memory cookie jar — keeps the httpOnly session cookie alive for the
/// duration of the app process. Also used by AuthApi to read the token
/// value after login for SecureStorage persistence.
final cookieJarProvider = Provider<CookieJar>((ref) => CookieJar());

final dioProvider = Provider<Dio>((ref) {
  final storage = ref.read(secureStorageProvider);
  final cookieJar = ref.read(cookieJarProvider);

  final dio = Dio(
    BaseOptions(
      baseUrl: dotenv.env['API_BASE_URL'] ?? '',
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: const {'Content-Type': 'application/json'},
    ),
  );

  // CookieManager must come before AuthInterceptor so the session cookie is
  // captured from the login response before we try to read it.
  dio.interceptors.add(CookieManager(cookieJar));
  dio.interceptors.add(AuthInterceptor(storage));

  if (kDebugMode) {
    dio.interceptors.add(
      LogInterceptor(requestBody: true, responseBody: true),
    );
  }

  return dio;
});
