import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../domain/reservation.dart';

class ReservationsApi {
  const ReservationsApi(this._dio);
  final Dio _dio;

  Future<List<Reservation>> getDriverPendingRequests() async {
    final res = await _dio.get<dynamic>('/routes/reservations/me/driver/requests');
    return _parseList(res.data);
  }

  Future<List<Reservation>> getDriverConfirmed() async {
    final res = await _dio.get<dynamic>('/routes/reservations/me/driver/confirmed');
    return _parseList(res.data);
  }

  Future<List<Reservation>> getPassengerRequests() async {
    final res = await _dio.get<dynamic>('/routes/reservations/me/passenger/requests');
    return _parseList(res.data);
  }

  Future<List<Reservation>> getPassengerConfirmed() async {
    final res = await _dio.get<dynamic>('/routes/reservations/me/passenger/confirmed');
    return _parseList(res.data);
  }

  Future<List<Reservation>> getPassengerHistory() async {
    final res = await _dio.get<dynamic>('/routes/reservations/me/passenger/history');
    return _parseList(res.data);
  }

  Future<Reservation> accept(String id) async {
    final res = await _dio.patch<dynamic>('/routes/reservations/$id/accept');
    return Reservation.fromJson(res.data as Map<String, dynamic>);
  }

  Future<Reservation> reject(String id) async {
    final res = await _dio.patch<dynamic>('/routes/reservations/$id/reject');
    return Reservation.fromJson(res.data as Map<String, dynamic>);
  }

  Future<Reservation> cancel(String id) async {
    final res = await _dio.delete<dynamic>('/routes/reservations/$id');
    return Reservation.fromJson(res.data as Map<String, dynamic>);
  }

  List<Reservation> _parseList(dynamic data) {
    if (data is! List) return [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(Reservation.fromJson)
        .toList();
  }
}

final reservationsApiProvider = Provider<ReservationsApi>(
  (ref) => ReservationsApi(ref.read(dioProvider)),
);
