import 'package:dio/dio.dart';

sealed class ApiException implements Exception {
  const ApiException(this.message);

  final String message;

  @override
  String toString() => message;

  static ApiException fromDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return const NetworkException();
      case DioExceptionType.badResponse:
        return switch (e.response?.statusCode) {
          401 => const UnauthorizedException(),
          404 => const NotFoundException(),
          422 => ValidationException(
              _extractMessage(e.response?.data) ?? 'Datos inválidos.',
            ),
          500 || 502 || 503 => const ServerException(),
          _ => ServerException(
              _extractMessage(e.response?.data) ?? 'Error inesperado.',
            ),
        };
      default:
        return const ServerException();
    }
  }

  static String? _extractMessage(dynamic data) {
    if (data is Map<String, dynamic>) {
      return (data['message'] ?? data['detail'])?.toString();
    }
    return null;
  }
}

final class UnauthorizedException extends ApiException {
  const UnauthorizedException([
    super.message = 'Sesión expirada. Inicia sesión nuevamente.',
  ]);
}

final class NotFoundException extends ApiException {
  const NotFoundException([super.message = 'Recurso no encontrado.']);
}

final class ValidationException extends ApiException {
  const ValidationException(super.message);
}

final class NetworkException extends ApiException {
  const NetworkException([
    super.message = 'Sin conexión. Verifica tu red.',
  ]);
}

final class ServerException extends ApiException {
  const ServerException([
    super.message = 'Error del servidor. Intenta más tarde.',
  ]);
}
