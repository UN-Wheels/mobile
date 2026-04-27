import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../domain/notification.dart';

class NotificationsApi {
  NotificationsApi(this._dio);
  final Dio _dio;

  Future<List<AppNotification>> getAll({int page = 1, int limit = 20}) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/notifications',
      queryParameters: {'page': page, 'limit': limit},
    );
    final items = res.data?['items'] as List<dynamic>? ?? [];
    return items
        .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<int> getUnreadCount() async {
    final res =
        await _dio.get<Map<String, dynamic>>('/notifications/unread');
    return (res.data?['count'] as num?)?.toInt() ?? 0;
  }

  Future<void> markRead(String id) async {
    await _dio.patch<void>('/notifications/$id/read');
  }

  Future<void> markAllRead() async {
    await _dio.patch<void>('/notifications/read-all');
  }

  Future<void> deleteOne(String id) async {
    await _dio.delete<void>('/notifications/$id');
  }
}

final notificationsApiProvider = Provider<NotificationsApi>(
  (ref) => NotificationsApi(ref.read(dioProvider)),
);
