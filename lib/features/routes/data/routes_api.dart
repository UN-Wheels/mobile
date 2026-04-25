import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import '../domain/app_route.dart';
import '../domain/availability_rule.dart';
import '../domain/route_slot.dart';

class RoutesApi {
  const RoutesApi(this._dio);

  final Dio _dio;

  // ── Routes ──────────────────────────────────────────────────────────────────

  Future<List<AppRoute>> getAvailableRoutes() async {
    try {
      final res = await _dio.get<dynamic>('/routes/routes/available');
      return _parseRoutes(res.data);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<List<AppRoute>> getMyRoutes() async {
    try {
      final res = await _dio.get<dynamic>('/routes/routes/me');
      return _parseRoutes(res.data);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<AppRoute> getRoute(String id) async {
    try {
      final res = await _dio.get<dynamic>('/routes/routes/$id');
      if (res.data is Map<String, dynamic>) {
        return AppRoute.fromJson(res.data as Map<String, dynamic>);
      }
      throw const ServerException('Respuesta de ruta inválida.');
    } on ApiException {
      rethrow;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<List<RouteSlot>> getSlots(
    String id, {
    DateTime? from,
    DateTime? to,
  }) async {
    try {
      final params = <String, String>{};
      if (from != null) params['from'] = from.toUtc().toIso8601String();
      if (to != null) params['to'] = to.toUtc().toIso8601String();
      final res = await _dio.get<dynamic>(
        '/routes/routes/$id/slots',
        queryParameters: params,
      );
      return _parseSlots(res.data);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<AppRoute> createRoute(Map<String, dynamic> data) async {
    try {
      final res = await _dio.post<dynamic>('/routes/routes', data: data);
      return AppRoute.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<AppRoute> updateRoute(String id, Map<String, dynamic> data) async {
    try {
      final res = await _dio.patch<dynamic>('/routes/routes/$id', data: data);
      return AppRoute.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> deleteRoute(String id) async {
    try {
      await _dio.delete<dynamic>('/routes/routes/$id');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  // ── Availability rules ───────────────────────────────────────────────────────

  Future<AvailabilityRule> addAvailabilityRule(
    String routeId,
    Map<String, dynamic> data,
  ) async {
    try {
      final res = await _dio.post<dynamic>(
        '/routes/routes/$routeId/availability/rules',
        data: data,
      );
      return AvailabilityRule.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> deleteAvailabilityRule(String routeId, String ruleId) async {
    try {
      await _dio.delete<dynamic>(
        '/routes/routes/$routeId/availability/rules/$ruleId',
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  // ── Reservations ─────────────────────────────────────────────────────────────

  Future<void> requestReservation(String routeId, DateTime travelDate) async {
    try {
      // travelDate must be start of day UTC
      final startOfDay = DateTime.utc(travelDate.year, travelDate.month, travelDate.day);
      await _dio.post<dynamic>('/routes/reservations/request', data: {
        'routeId': routeId,
        'travelDate': startOfDay.toIso8601String(),
      });
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────────

  static List<AppRoute> _parseRoutes(dynamic data) {
    if (data is List) {
      return data.whereType<Map<String, dynamic>>().map(AppRoute.fromJson).toList();
    }
    return [];
  }

  static List<RouteSlot> _parseSlots(dynamic data) {
    if (data is List) {
      return data.whereType<Map<String, dynamic>>().map(RouteSlot.fromJson).toList();
    }
    return [];
  }
}

final routesApiProvider = Provider<RoutesApi>((ref) {
  return RoutesApi(ref.read(dioProvider));
});
