import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import '../../auth/domain/user.dart';
import '../../vehicles/domain/vehicle.dart';

class ProfileApi {
  const ProfileApi(this._dio);

  final Dio _dio;

  Future<User> getMe() async {
    try {
      final res = await _dio.get<dynamic>('/auth/me');
      return _parseUser(res.data);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<User> updateMe(Map<String, dynamic> data) async {
    try {
      final res = await _dio.put<dynamic>('/auth/me', data: data);
      return _parseUser(res.data);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  static User _parseUser(dynamic data) {
    if (data is Map<String, dynamic>) {
      if (data.containsKey('user') && data['user'] is Map<String, dynamic>) {
        return User.fromJson(data['user'] as Map<String, dynamic>);
      }
      return User.fromJson(data);
    }
    throw const ServerException('Respuesta de perfil invalida.');
  }

  Future<List<Vehicle>> getMyVehicles() async {
    try {
      // GET /vehicles — returns the authenticated user's vehicles via JWT
      final res = await _dio.get<dynamic>('/vehicles');
      final data = res.data;
      if (data is List) {
        return data.whereType<Map<String, dynamic>>().map(Vehicle.fromJson).toList();
      }
      if (data is Map && data.containsKey('vehicles')) {
        final list = data['vehicles'];
        if (list is List) {
          return list.whereType<Map<String, dynamic>>().map(Vehicle.fromJson).toList();
        }
      }
      return [];
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Vehicle> createVehicle(Map<String, dynamic> data) async {
    try {
      final res = await _dio.post<dynamic>('/vehicles', data: data);
      return Vehicle.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> deleteVehicle(String id) async {
    try {
      await _dio.delete<dynamic>('/vehicles/$id');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}

final profileApiProvider = Provider<ProfileApi>(
  (ref) => ProfileApi(ref.read(dioProvider)),
);
