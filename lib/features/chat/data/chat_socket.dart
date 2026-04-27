import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../domain/chat_message.dart';

class MessageStatusUpdate {
  const MessageStatusUpdate({
    required this.conversationId,
    this.messageId,
    this.status,
    this.bulkStatus,
    this.count,
    this.userId,
  });

  final String conversationId;
  final String? messageId;
  final String? status;
  final String? bulkStatus;
  final int? count;
  final String? userId;

  factory MessageStatusUpdate.fromJson(Map<String, dynamic> json) =>
      MessageStatusUpdate(
        conversationId: (json['conversationId'] ?? '').toString(),
        messageId: json['messageId']?.toString(),
        status: json['status'] as String?,
        bulkStatus: json['bulkStatus'] as String?,
        count: (json['count'] as num?)?.toInt(),
        userId: json['userId']?.toString(),
      );
}

class ChatSocket {
  io.Socket? _socket;
  final _activeRooms = <String>{};

  final _msgCtrl = StreamController<ChatMessage>.broadcast();
  final _statusCtrl = StreamController<MessageStatusUpdate>.broadcast();
  final _notifCtrl = StreamController<Map<String, dynamic>>.broadcast();

  Stream<ChatMessage> get messageStream => _msgCtrl.stream;
  Stream<MessageStatusUpdate> get statusStream => _statusCtrl.stream;
  Stream<Map<String, dynamic>> get notificationStream => _notifCtrl.stream;

  bool get isConnected => _socket?.connected ?? false;

  void connect({required String token}) {
    if (_socket?.connected == true) return;

    _socket?.dispose();

    final apiBase = dotenv.env['API_BASE_URL'] ?? '';
    final socketBase = apiBase.endsWith('/api')
        ? apiBase.substring(0, apiBase.length - 4)
        : apiBase;

    _socket = io.io(
      socketBase,
      io.OptionBuilder()
          .setPath('/api/chat/socket.io')
          .setTransports(['polling', 'websocket'])
          .setAuth({'token': token})
          .setExtraHeaders({'authorization': 'Bearer $token'})
          .enableReconnection()
          .setReconnectionAttempts(5)
          .setReconnectionDelay(1000)
          .build(),
    );

    _socket!.onConnect((_) {
      debugPrint('Socket.IO conectado: ${_socket!.id}');
      for (final room in _activeRooms) {
        _socket!.emit('conversation:join', {'conversationId': room});
      }
    });
    _socket!.onDisconnect((_) => debugPrint('Socket.IO desconectado'));
    _socket!.onConnectError((e) => debugPrint('Socket.IO connect error: $e'));

    _socket!.on('message:new', (data) {
      if (_msgCtrl.isClosed) return;
      try {
        _msgCtrl.add(ChatMessage.fromJson(Map<String, dynamic>.from(data as Map)));
      } catch (e) {
        debugPrint('message:new parse error: $e');
      }
    });

    _socket!.on('message:status', (data) {
      if (_statusCtrl.isClosed) return;
      try {
        _statusCtrl
            .add(MessageStatusUpdate.fromJson(Map<String, dynamic>.from(data as Map)));
      } catch (e) {
        debugPrint('message:status parse error: $e');
      }
    });

    _socket!.on('notification:new', (data) {
      if (_notifCtrl.isClosed) return;
      try {
        _notifCtrl.add(Map<String, dynamic>.from(data as Map));
      } catch (e) {
        debugPrint('notification:new parse error: $e');
      }
    });

    _socket!.connect();
  }

  void joinConversation(String conversationId) {
    _activeRooms.add(conversationId);
    _safeEmit('conversation:join', {'conversationId': conversationId});
  }

  void leaveConversation(String conversationId) {
    _activeRooms.remove(conversationId);
    _safeEmit('conversation:leave', {'conversationId': conversationId});
  }

  Future<void> ensureConnected() async {
    if (isConnected) return;
    if (_socket == null) return;
    final completer = Completer<void>();
    void handler(_) {
      if (!completer.isCompleted) completer.complete();
    }
    _socket!.once('connect', handler);
    // TOCTOU: check again in case connect fired between the first check and
    // registering the once handler
    if (isConnected) {
      completer.complete();
      return;
    }
    await completer.future
        .timeout(const Duration(seconds: 10), onTimeout: () {});
  }

  void sendMessageViaSocket(
    String conversationId,
    String content,
    void Function(bool success, ChatMessage? msg) callback,
  ) {
    if (_socket == null || !isConnected) {
      callback(false, null);
      return;
    }
    _socket!.emitWithAck(
      'message:send',
      {'conversationId': conversationId, 'content': content},
      ack: (dynamic data) {
        try {
          final ack = data as Map<String, dynamic>;
          final success = ack['success'] as bool? ?? false;
          ChatMessage? msg;
          if (success && ack['message'] != null) {
            msg = ChatMessage.fromJson(ack['message'] as Map<String, dynamic>);
          }
          callback(success, msg);
        } catch (_) {
          callback(false, null);
        }
      },
    );
  }

  void markAsRead(String conversationId) {
    _safeEmit('message:read', {'conversationId': conversationId});
  }

  void markDelivered(String conversationId, String messageId) {
    _safeEmit('message:delivered', {
      'conversationId': conversationId,
      'messageId': messageId,
    });
  }

  void _safeEmit(String event, Map<String, dynamic> data) {
    if (_socket == null) return;
    if (isConnected) {
      _socket!.emit(event, data);
    } else {
      _socket!.once('connect', (_) => _socket?.emit(event, data));
    }
  }

  void dispose() {
    _socket?.dispose();
    _socket = null;
    _activeRooms.clear();
    _msgCtrl.close();
    _statusCtrl.close();
    _notifCtrl.close();
  }
}

final chatSocketProvider = Provider<ChatSocket>((ref) {
  final socket = ChatSocket();
  ref.onDispose(socket.dispose);
  return socket;
});
