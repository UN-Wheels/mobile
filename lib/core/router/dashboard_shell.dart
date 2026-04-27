import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/chat/application/chat_providers.dart';
import '../../features/notifications/application/notifications_providers.dart';
import '../../features/notifications/domain/notification.dart';
import '../theme/app_colors.dart';
import 'route_names.dart';

class DashboardShell extends ConsumerWidget {
  const DashboardShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Keep both sockets alive for the entire authenticated session
    ref.watch(notificationsSocketInitProvider);
    ref.watch(chatSocketInitProvider);

    final unreadCount = ref.watch(unreadCountProvider);

    // In-app banner when a notification arrives and user is NOT on
    // the notifications tab (index 4)
    ref.listen<AppNotification?>(incomingNotificationProvider, (_, notif) {
      if (notif == null) return;
      if (navigationShell.currentIndex == 4) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.authCard1,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 4),
          content: Row(
            children: [
              Icon(
                _iconForType(notif.type),
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      notif.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      notif.body,
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          action: SnackBarAction(
            label: 'Ver',
            textColor: AppColors.primary,
            onPressed: () => _handleBannerTap(context, notif),
          ),
        ),
      );
    });

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.authBg1, AppColors.navBg, AppColors.secondary],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: navigationShell,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Inicio',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.search_outlined),
            activeIcon: Icon(Icons.search),
            label: 'Buscar',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.bookmark_outline),
            activeIcon: Icon(Icons.bookmark),
            label: 'Reservas',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            activeIcon: Icon(Icons.chat_bubble),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: _BadgeIcon(
              count: unreadCount,
              icon: Icons.notifications_outlined,
            ),
            activeIcon: _BadgeIcon(
              count: unreadCount,
              icon: Icons.notifications,
            ),
            label: 'Alertas',
          ),
        ],
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.white54,
        backgroundColor: AppColors.authBg2,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }

  void _handleBannerTap(BuildContext context, AppNotification notif) {
    switch (notif.type) {
      case NotificationType.chatMessage:
        final convId = notif.data['conversationId'] as String?;
        if (convId != null) {
          context.push(RouteNames.chatDetailOf(convId));
        } else {
          context.go(RouteNames.notifications);
        }
      case NotificationType.reservationRequested:
      case NotificationType.reservationAccepted:
      case NotificationType.reservationRejected:
      case NotificationType.routeDeleted:
        context.go(RouteNames.bookings);
      case NotificationType.unknown:
        context.go(RouteNames.notifications);
    }
  }

  IconData _iconForType(NotificationType type) => switch (type) {
        NotificationType.chatMessage => Icons.chat_bubble_outline,
        NotificationType.reservationRequested => Icons.person_add_outlined,
        NotificationType.reservationAccepted => Icons.check_circle_outline,
        NotificationType.reservationRejected => Icons.cancel_outlined,
        NotificationType.routeDeleted => Icons.directions_off_outlined,
        NotificationType.unknown => Icons.notifications_outlined,
      };
}

class _BadgeIcon extends StatelessWidget {
  const _BadgeIcon({required this.count, required this.icon});

  final int count;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    if (count == 0) return Icon(icon);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon),
        Positioned(
          top: -4,
          right: -6,
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(
              color: AppColors.error,
              shape: BoxShape.circle,
            ),
            constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
            child: Text(
              count > 99 ? '99+' : '$count',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }
}
