import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/secure_storage.dart';
import '../../auth/application/auth_controller.dart';
import '../data/notifications_api.dart';
import '../data/notifications_socket.dart';
import '../domain/notification.dart';

// ── Socket lifecycle ──────────────────────────────────────────────────────────

final notificationsSocketInitProvider = FutureProvider<bool>((ref) async {
  final user = await ref.watch(authControllerProvider.future);
  if (user == null) return false;

  final token = await ref.read(secureStorageProvider).getToken();
  if (token == null) return false;

  final socket = ref.read(notificationsSocketProvider);
  if (!socket.isConnected) socket.connect(token: token);
  await socket.ensureConnected();

  return true;
});

// ── Incoming notification for in-app banner ───────────────────────────────────

/// Holds the most recently received notification from the socket.
/// DashboardShell listens to this to show in-app banners.
final incomingNotificationProvider = StateProvider<AppNotification?>((ref) => null);

// ── Unread count ──────────────────────────────────────────────────────────────

class UnreadCountNotifier extends StateNotifier<int> {
  UnreadCountNotifier(this._ref) : super(0) {
    _init();
  }

  final Ref _ref;
  StreamSubscription<AppNotification>? _notifSub;
  StreamSubscription<int>? _countSub;

  Future<void> _init() async {
    // Load initial count from REST
    try {
      state = await _ref.read(notificationsApiProvider).getUnreadCount();
    } catch (_) {}

    // Wait for socket then subscribe
    try {
      await _ref.read(notificationsSocketInitProvider.future);
    } catch (_) {
      return;
    }
    final socket = _ref.read(notificationsSocketProvider);

    _countSub = socket.unreadCountStream.listen((n) => state = n);
    _notifSub = socket.notificationStream.listen((notif) {
      state = state + 1;
      _ref.read(incomingNotificationProvider.notifier).state = notif;
    });
  }

  void decrement() {
    if (state > 0) state = state - 1;
  }

  void reset() => state = 0;

  @override
  void dispose() {
    _notifSub?.cancel();
    _countSub?.cancel();
    super.dispose();
  }
}

final unreadCountProvider =
    StateNotifierProvider<UnreadCountNotifier, int>(
  (ref) => UnreadCountNotifier(ref),
);

// ── Notifications list ────────────────────────────────────────────────────────

class NotificationsNotifier extends AsyncNotifier<List<AppNotification>> {
  StreamSubscription<AppNotification>? _sub;

  @override
  Future<List<AppNotification>> build() async {
    await ref.watch(notificationsSocketInitProvider.future);
    final socket = ref.read(notificationsSocketProvider);

    unawaited(_sub?.cancel());
    _sub = socket.notificationStream.listen((notif) {
      if (state.hasValue) {
        state = state.whenData((list) => [notif, ...list]);
      }
    });

    ref.onDispose(() => _sub?.cancel());

    return ref.read(notificationsApiProvider).getAll();
  }

  Future<void> markRead(String id) async {
    final list = state.valueOrNull ?? [];
    final wasUnread = list.any((n) => n.id == id && !n.read);
    await ref.read(notificationsApiProvider).markRead(id);
    if (wasUnread) ref.read(unreadCountProvider.notifier).decrement();
    state = state.whenData(
      (list) => list.map((n) => n.id == id ? n.copyWith(read: true) : n).toList(),
    );
  }

  Future<void> markAllRead() async {
    await ref.read(notificationsApiProvider).markAllRead();
    ref.read(unreadCountProvider.notifier).reset();
    state = state.whenData(
      (list) => list.map((n) => n.copyWith(read: true)).toList(),
    );
  }

  Future<void> deleteOne(String id) async {
    final list = state.valueOrNull ?? [];
    final wasUnread = list.any((n) => n.id == id && !n.read);
    await ref.read(notificationsApiProvider).deleteOne(id);
    if (wasUnread) ref.read(unreadCountProvider.notifier).decrement();
    state = state.whenData((list) => list.where((n) => n.id != id).toList());
  }
}

final notificationsProvider =
    AsyncNotifierProvider<NotificationsNotifier, List<AppNotification>>(
  NotificationsNotifier.new,
);
