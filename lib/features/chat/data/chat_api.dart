import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../domain/chat_message.dart';
import '../domain/conversation.dart';

class ChatApi {
  ChatApi(this._dio);
  final Dio _dio;

  Future<String> createOrGetConversation({
    required String routeId,
    required String driverId,
    required String passengerId,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/chat/conversations',
      data: {
        'routeId': routeId,
        'driverId': driverId,
        'passengerId': passengerId,
      },
    );
    final conv = res.data!['conversation'] as Map<String, dynamic>;
    return conv['_id']?.toString() ?? '';
  }

  Future<List<Conversation>> getUserConversations(String userId) async {
    final res = await _dio.get<List<dynamic>>(
        '/chat/conversations/user/${Uri.encodeComponent(userId)}');
    return (res.data ?? [])
        .map((e) => Conversation.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<ChatMessage>> getMessages(
    String conversationId, {
    int page = 1,
    int limit = 50,
  }) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/chat/conversations/$conversationId/messages',
      queryParameters: {'page': page, 'limit': limit},
    );
    final items = res.data?['items'] as List<dynamic>? ?? [];
    return items
        .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ChatMessage> sendMessage(
      String conversationId, String content) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/chat/conversations/$conversationId/messages',
      data: {'content': content},
    );
    return ChatMessage.fromJson(res.data!);
  }

  Future<void> markAsRead(String conversationId) async {
    await _dio.patch<void>('/chat/conversations/$conversationId/read');
  }
}

final chatApiProvider = Provider<ChatApi>(
  (ref) => ChatApi(ref.read(dioProvider)),
);
