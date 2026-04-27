import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/loading.dart';
import '../application/notifications_providers.dart';
import '../domain/notification.dart';

class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifsAsync = ref.watch(notificationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones'),
        actions: [
          TextButton(
            onPressed: () =>
                ref.read(notificationsProvider.notifier).markAllRead(),
            child: const Text(
              'Marcar todo',
              style: TextStyle(color: AppColors.primary, fontSize: 13),
            ),
          ),
        ],
      ),
      body: notifsAsync.when(
        loading: () => const Loading(message: 'Cargando notificaciones...'),
        error: (err, _) => EmptyState(
          message: 'No se pudieron cargar las notificaciones.',
          icon: Icons.notifications_off_outlined,
          actionLabel: 'Reintentar',
          onAction: () => ref.invalidate(notificationsProvider),
        ),
        data: (notifs) {
          if (notifs.isEmpty) {
            return const EmptyState(
              message: 'No tienes notificaciones aún.',
              icon: Icons.notifications_none_outlined,
            );
          }
          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () => ref.refresh(notificationsProvider.future),
            child: ListView.separated(
              itemCount: notifs.length,
              separatorBuilder: (context, _) => const Divider(
                height: 1,
                indent: 72,
                color: Colors.white12,
              ),
              itemBuilder: (context, i) => _NotificationTile(
                notif: notifs[i],
                onTap: () => _handleTap(context, ref, notifs[i]),
                onDismiss: () => ref
                    .read(notificationsProvider.notifier)
                    .deleteOne(notifs[i].id),
              ),
            ),
          );
        },
      ),
    );
  }

  void _handleTap(
      BuildContext context, WidgetRef ref, AppNotification notif) {
    if (!notif.read) {
      ref.read(notificationsProvider.notifier).markRead(notif.id);
    }
    switch (notif.type) {
      case NotificationType.chatMessage:
        final convId = notif.data['conversationId'] as String?;
        if (convId != null) context.push(RouteNames.chatDetailOf(convId));
      case NotificationType.reservationRequested:
      case NotificationType.reservationAccepted:
      case NotificationType.reservationRejected:
        context.go(RouteNames.bookings);
      case NotificationType.routeDeleted:
      case NotificationType.unknown:
        break;
    }
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.notif,
    required this.onTap,
    required this.onDismiss,
  });

  final AppNotification notif;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(notif.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: AppColors.error.withAlpha(200),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) => onDismiss(),
      child: InkWell(
        onTap: onTap,
        child: Container(
          color: notif.read ? Colors.transparent : AppColors.primary.withAlpha(20),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _NotifIcon(type: notif.type),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notif.title,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: notif.read
                                  ? FontWeight.normal
                                  : FontWeight.bold,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!notif.read)
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(left: 6),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      notif.body,
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 13),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      timeago.format(notif.createdAt, locale: 'es'),
                      style: const TextStyle(
                          color: Colors.white38, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotifIcon extends StatelessWidget {
  const _NotifIcon({required this.type});
  final NotificationType type;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (type) {
      NotificationType.chatMessage => (
          Icons.chat_bubble_outline,
          AppColors.primary
        ),
      NotificationType.reservationRequested => (
          Icons.person_add_outlined,
          AppColors.info
        ),
      NotificationType.reservationAccepted => (
          Icons.check_circle_outline,
          AppColors.success
        ),
      NotificationType.reservationRejected => (
          Icons.cancel_outlined,
          AppColors.error
        ),
      NotificationType.routeDeleted => (
          Icons.directions_off_outlined,
          AppColors.warning
        ),
      NotificationType.unknown => (Icons.notifications_outlined, Colors.white54),
    };

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }
}
