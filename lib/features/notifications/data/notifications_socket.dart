import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../domain/notification.dart';

class NotificationsSocket {
  io.Socket? _socket;

  final _notifCtrl = StreamController<AppNotification>.broadcast();
  final _unreadCtrl = StreamController<int>.broadcast();

  Stream<AppNotification> get notificationStream => _notifCtrl.stream;
  Stream<int> get unreadCountStream => _unreadCtrl.stream;

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
          .setPath('/api/notifications/socket.io')
          .setTransports(['polling', 'websocket'])
          .setAuth({'token': token})
          .setExtraHeaders({'authorization': 'Bearer $token'})
          .enableReconnection()
          .setReconnectionAttempts(5)
          .setReconnectionDelay(1000)
          .build(),
    );

    _socket!.onConnect((_) {
      debugPrint('Notifications Socket.IO conectado: ${_socket!.id}');
      _socket!.emit('join');
    });
    _socket!.onDisconnect((_) =>
        debugPrint('Notifications Socket.IO desconectado'));
    _socket!.onConnectError((e) =>
        debugPrint('Notifications Socket.IO connect error: $e'));

    _socket!.on('notification', (data) {
      if (_notifCtrl.isClosed) return;
      try {
        _notifCtrl
            .add(AppNotification.fromJson(data as Map<String, dynamic>));
      } catch (e) {
        debugPrint('notification parse error: $e');
      }
    });

    _socket!.on('unread_count', (data) {
      if (_unreadCtrl.isClosed) return;
      try {
        final count = data is int
            ? data
            : (data as Map<String, dynamic>)['count'] as int? ?? 0;
        _unreadCtrl.add(count);
      } catch (e) {
        debugPrint('unread_count parse error: $e');
      }
    });

    _socket!.connect();
  }

  Future<void> ensureConnected() async {
    if (isConnected) return;
    if (_socket == null) return;
    final completer = Completer<void>();
    void handler(_) {
      if (!completer.isCompleted) completer.complete();
    }
    _socket!.once('connect', handler);
    // TOCTOU: check again after registering the handler
    if (isConnected) {
      completer.complete();
      return;
    }
    await completer.future
        .timeout(const Duration(seconds: 10), onTimeout: () {});
  }

  void dispose() {
    _socket?.dispose();
    _socket = null;
    _notifCtrl.close();
    _unreadCtrl.close();
  }
}

final notificationsSocketProvider = Provider<NotificationsSocket>((ref) {
  final socket = NotificationsSocket();
  ref.onDispose(socket.dispose);
  return socket;
});
