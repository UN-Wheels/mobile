import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/secure_storage.dart';
import '../../auth/application/auth_controller.dart';
import '../data/chat_api.dart';
import '../data/chat_socket.dart';
import '../domain/chat_message.dart';
import '../domain/conversation.dart';

// ── Socket lifecycle ──────────────────────────────────────────────────────────

/// Ensures the socket is connected whenever a user is authenticated.
final chatSocketInitProvider = FutureProvider<bool>((ref) async {
  final user = await ref.watch(authControllerProvider.future);
  if (user == null) return false;

  final token = await ref.read(secureStorageProvider).getToken();
  if (token == null) return false;

  final socket = ref.read(chatSocketProvider);
  if (!socket.isConnected) socket.connect(token: token);
  await socket.ensureConnected();

  return true;
});

// ── Conversations ─────────────────────────────────────────────────────────────

class ConversationsNotifier extends AsyncNotifier<List<Conversation>> {
  StreamSubscription<Map<String, dynamic>>? _notifSub;

  @override
  Future<List<Conversation>> build() async {
    final user = await ref.watch(authControllerProvider.future);
    if (user == null) return [];

    final conversations =
        await ref.read(chatApiProvider).getUserConversations(user.email);

    unawaited(_notifSub?.cancel());
    _notifSub = ref
        .read(chatSocketProvider)
        .notificationStream
        .listen(_onNotification);

    ref.onDispose(() => _notifSub?.cancel());

    return conversations;
  }

  void _onNotification(Map<String, dynamic> data) {
    final convId = data['conversationId']?.toString();
    if (convId == null) return;

    state = state.whenData(
      (list) => list.map((c) {
        if (c.id != convId) return c;
        return c.copyWith(
          unreadCount: c.unreadCount + 1,
          lastMessageText: data['preview'] as String?,
          lastMessageAt: DateTime.now(),
        );
      }).toList(),
    );
  }

  Future<String> createOrGetConversation({
    required String routeId,
    required String driverId,
    required String passengerId,
  }) async {
    final id = await ref.read(chatApiProvider).createOrGetConversation(
          routeId: routeId,
          driverId: driverId,
          passengerId: passengerId,
        );
    ref.invalidateSelf();
    return id;
  }
}

final conversationsProvider =
    AsyncNotifierProvider<ConversationsNotifier, List<Conversation>>(
  ConversationsNotifier.new,
);

// ── Messages per conversation ─────────────────────────────────────────────────

class MessagesNotifier
    extends FamilyAsyncNotifier<List<ChatMessage>, String> {
  StreamSubscription<ChatMessage>? _msgSub;
  StreamSubscription<MessageStatusUpdate>? _statusSub;

  @override
  Future<List<ChatMessage>> build(String conversationId) async {
    // Ensure socket is connected before joining the room
    await ref.watch(chatSocketInitProvider.future);

    final socket = ref.read(chatSocketProvider);

    // Subscribe BEFORE the REST load so no socket messages are missed while
    // the HTTP request is in flight. Collect them in a buffer and merge later.
    final buffer = <ChatMessage>[];
    final user = await ref.read(authControllerProvider.future);

    unawaited(_msgSub?.cancel());
    _msgSub = socket.messageStream
        .where((m) => m.conversationId == conversationId)
        .listen((m) {
      // Notify sender that the message was delivered
      if (m.senderId != user?.email) {
        socket.markDelivered(conversationId, m.id);
      }
      if (state.hasValue) {
        state = state.whenData((list) {
          if (list.any((e) => e.id == m.id)) return list;
          return [m, ...list];
        });
      } else {
        if (!buffer.any((e) => e.id == m.id)) buffer.add(m);
      }
    });

    unawaited(_statusSub?.cancel());
    _statusSub = socket.statusStream
        .where((s) => s.conversationId == conversationId)
        .listen(_onStatusUpdate);

    ref.onDispose(() {
      _msgSub?.cancel();
      _statusSub?.cancel();
      socket.leaveConversation(conversationId);
    });

    socket.joinConversation(conversationId);

    final msgs = await ref.read(chatApiProvider).getMessages(conversationId);

    socket.markAsRead(conversationId);

    // Merge buffered socket messages that arrived during the REST call,
    // deduplicating by id, then sort newest-first for reverse ListView.
    final idSet = {for (final m in msgs) m.id};
    final merged = [
      ...buffer.where((m) => !idSet.contains(m.id)),
      ...msgs,
    ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return merged;
  }

  void _onStatusUpdate(MessageStatusUpdate update) {
    state = state.whenData(
      (list) => list.map((m) {
        if (update.messageId != null && m.id != update.messageId) return m;
        final newStatus = _parseStatus(
          update.status ?? update.bulkStatus,
        );
        return newStatus != null ? m.copyWith(status: newStatus) : m;
      }).toList(),
    );
  }

  static MessageStatus? _parseStatus(String? s) => switch (s?.toUpperCase()) {
        'READ' => MessageStatus.read,
        'DELIVERED' => MessageStatus.delivered,
        'SENT' => MessageStatus.sent,
        _ => null,
      };

  Future<void> sendMessage(String content) async {
    final user = await ref.read(authControllerProvider.future);
    if (user == null) return;

    final optimisticId = 'opt_${DateTime.now().millisecondsSinceEpoch}';
    final optimistic = ChatMessage(
      id: optimisticId,
      conversationId: arg,
      senderId: user.email,
      content: content,
      status: MessageStatus.sent,
      createdAt: DateTime.now(),
      isOptimistic: true,
    );

    state = state.whenData((list) => [optimistic, ...list]);

    final socket = ref.read(chatSocketProvider);

    if (socket.isConnected) {
      final completer = Completer<void>();
      socket.sendMessageViaSocket(arg, content, (success, msg) {
        if (completer.isCompleted) return;
        if (success && msg != null) {
          state = state.whenData(
            (list) => list.map((m) => m.id == optimisticId ? msg : m).toList(),
          );
        } else {
          state = state.whenData(
            (list) => list.where((m) => m.id != optimisticId).toList(),
          );
        }
        completer.complete();
      });
      await completer.future.timeout(
        const Duration(seconds: 8),
        onTimeout: () {
          state = state.whenData(
            (list) => list.where((m) => m.id != optimisticId).toList(),
          );
        },
      );
    } else {
      // REST fallback
      try {
        final msg = await ref.read(chatApiProvider).sendMessage(arg, content);
        state = state.whenData(
          (list) => list.map((m) => m.id == optimisticId ? msg : m).toList(),
        );
      } catch (_) {
        state = state.whenData(
          (list) => list.where((m) => m.id != optimisticId).toList(),
        );
      }
    }
  }
}

final messagesProvider = AsyncNotifierProviderFamily<MessagesNotifier,
    List<ChatMessage>, String>(
  MessagesNotifier.new,
);
