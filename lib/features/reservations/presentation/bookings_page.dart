import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_badge.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/loading.dart';
import '../../auth/application/auth_controller.dart';
import '../../chat/application/chat_providers.dart';
import '../../notifications/application/notifications_providers.dart';
import '../../notifications/domain/notification.dart';
import '../application/reservations_providers.dart';
import '../data/reservations_api.dart';
import '../domain/reservation.dart';

class BookingsPage extends ConsumerStatefulWidget {
  const BookingsPage({super.key});

  @override
  ConsumerState<BookingsPage> createState() => _BookingsPageState();
}

class _BookingsPageState extends ConsumerState<BookingsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Auto-refresh lists when a reservation notification arrives
    ref.listen<AppNotification?>(incomingNotificationProvider, (_, notif) {
      if (notif == null) return;
      switch (notif.type) {
        case NotificationType.reservationRequested:
          ref.invalidate(driverRequestsProvider);
        case NotificationType.reservationAccepted:
        case NotificationType.reservationRejected:
          ref.invalidate(passengerRequestsProvider);
          ref.invalidate(passengerConfirmedProvider);
        case NotificationType.routeDeleted:
          ref.invalidate(passengerConfirmedProvider);
          ref.invalidate(passengerHistoryProvider);
        default:
          break;
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis reservas'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'Pasajero'),
            Tab(text: 'Conductor'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _PassengerTab(),
          _DriverTab(),
        ],
      ),
    );
  }
}

// ── Passenger tab ─────────────────────────────────────────────────────────────

class _PassengerTab extends ConsumerStatefulWidget {
  const _PassengerTab();

  @override
  ConsumerState<_PassengerTab> createState() => _PassengerTabState();
}

class _PassengerTabState extends ConsumerState<_PassengerTab>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tab,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'Pendientes'),
            Tab(text: 'Confirmadas'),
            Tab(text: 'Historial'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tab,
            children: [
              _ReservationList(
                provider: passengerRequestsProvider,
                emptyMessage: 'No tienes solicitudes pendientes.',
                emptyIcon: Icons.pending_outlined,
                showCancelAction: true,
              ),
              _ReservationList(
                provider: passengerConfirmedProvider,
                emptyMessage: 'No tienes reservas confirmadas.',
                emptyIcon: Icons.event_available_outlined,
                showChatAction: true,
              ),
              _ReservationList(
                provider: passengerHistoryProvider,
                emptyMessage: 'Tu historial de viajes está vacío.',
                emptyIcon: Icons.history_outlined,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Driver tab ─────────────────────────────────────────────────────────────────

class _DriverTab extends ConsumerStatefulWidget {
  const _DriverTab();

  @override
  ConsumerState<_DriverTab> createState() => _DriverTabState();
}

class _DriverTabState extends ConsumerState<_DriverTab>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tab,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'Solicitudes'),
            Tab(text: 'Confirmadas'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tab,
            children: [
              _ReservationList(
                provider: driverRequestsProvider,
                emptyMessage: 'No tienes solicitudes pendientes.',
                emptyIcon: Icons.inbox_outlined,
                showAcceptRejectActions: true,
              ),
              _ReservationList(
                provider: driverConfirmedProvider,
                emptyMessage: 'No tienes reservas confirmadas.',
                emptyIcon: Icons.check_circle_outline,
                showChatAction: true,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Generic reservation list ──────────────────────────────────────────────────

class _ReservationList extends ConsumerWidget {
  const _ReservationList({
    required this.provider,
    required this.emptyMessage,
    required this.emptyIcon,
    this.showCancelAction = false,
    this.showAcceptRejectActions = false,
    this.showChatAction = false,
  });

  final FutureProvider<List<Reservation>> provider;
  final String emptyMessage;
  final IconData emptyIcon;
  final bool showCancelAction;
  final bool showAcceptRejectActions;
  final bool showChatAction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(provider);

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => ref.refresh(provider.future),
      child: state.when(
        loading: () => const Loading(message: 'Cargando...'),
        error: (e, _) => EmptyState(
          message: 'No se pudieron cargar las reservas.\n$e',
          icon: Icons.wifi_off_outlined,
          actionLabel: 'Reintentar',
          onAction: () => ref.invalidate(provider),
        ),
        data: (reservations) {
          if (reservations.isEmpty) {
            return EmptyState(message: emptyMessage, icon: emptyIcon);
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: reservations.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, i) => _ReservationCard(
              reservation: reservations[i],
              showCancelAction: showCancelAction,
              showAcceptRejectActions: showAcceptRejectActions,
              showChatAction: showChatAction,
              onActionDone: () => ref.invalidate(provider),
            ),
          );
        },
      ),
    );
  }
}

// ── Reservation card ──────────────────────────────────────────────────────────

class _ReservationCard extends ConsumerWidget {
  const _ReservationCard({
    required this.reservation,
    required this.onActionDone,
    this.showCancelAction = false,
    this.showAcceptRejectActions = false,
    this.showChatAction = false,
  });

  final Reservation reservation;
  final VoidCallback onActionDone;
  final bool showCancelAction;
  final bool showAcceptRejectActions;
  final bool showChatAction;

  Future<void> _accept(BuildContext ctx, WidgetRef ref) async {
    try {
      await ref.read(reservationsApiProvider).accept(reservation.id);
      onActionDone();
      if (!ctx.mounted) return;
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(
          content: Text('Solicitud aceptada.'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!ctx.mounted) return;
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _reject(BuildContext ctx, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: ctx,
      builder: (c) => AlertDialog(
        title: const Text('Rechazar solicitud'),
        content: const Text('¿Seguro que quieres rechazar esta solicitud?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Rechazar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !ctx.mounted) return;
    try {
      await ref.read(reservationsApiProvider).reject(reservation.id);
      onActionDone();
      if (!ctx.mounted) return;
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(content: Text('Solicitud rechazada.')),
      );
    } catch (e) {
      if (!ctx.mounted) return;
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _cancel(BuildContext ctx, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: ctx,
      builder: (c) => AlertDialog(
        title: const Text('Cancelar solicitud'),
        content: const Text('¿Seguro que quieres cancelar esta solicitud?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('No')),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Cancelar solicitud'),
          ),
        ],
      ),
    );
    if (confirmed != true || !ctx.mounted) return;
    try {
      await ref.read(reservationsApiProvider).cancel(reservation.id);
      onActionDone();
      if (!ctx.mounted) return;
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(content: Text('Solicitud cancelada.')),
      );
    } catch (e) {
      if (!ctx.mounted) return;
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _openChat(BuildContext ctx, WidgetRef ref) async {
    final currentUser = ref.read(authControllerProvider).valueOrNull;
    if (currentUser == null || !ctx.mounted) return;

    // Chat service uses JWT sub (email) as userId
    final driverId = reservation.route?.driver?.email ?? '';
    final passengerId = currentUser.email;
    final routeId = reservation.routeId;

    if (driverId.isEmpty || passengerId.isEmpty || routeId.isEmpty) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(content: Text('No se puede abrir el chat.')),
      );
      return;
    }

    try {
      final convId = await ref
          .read(conversationsProvider.notifier)
          .createOrGetConversation(
            routeId: routeId,
            driverId: driverId,
            passengerId: passengerId,
          );
      if (!ctx.mounted) return;
      unawaited(ctx.push(RouteNames.chatDetailOf(convId)));
    } catch (e) {
      if (!ctx.mounted) return;
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final route = reservation.route;
    final passenger = reservation.passenger;

    final (BadgeType badgeType, String badgeLabel) = switch (reservation.status) {
      'PENDING' => (BadgeType.warning, 'Pendiente'),
      'CONFIRMED' => (BadgeType.success, 'Confirmada'),
      'REJECTED' => (BadgeType.neutral, 'Rechazada'),
      'CANCELLED' => (BadgeType.neutral, 'Cancelada'),
      _ => (BadgeType.neutral, reservation.status),
    };

    return Card(
      color: AppColors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Route row
            if (route != null) ...[
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.route, color: AppColors.primary, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          route.origin.name,
                          style: AppTextStyles.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Row(
                          children: [
                            const Icon(Icons.arrow_downward, size: 10, color: AppColors.textHint),
                            const SizedBox(width: 2),
                            Expanded(
                              child: Text(
                                route.destination.name,
                                style: AppTextStyles.bodySmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  AppBadge(label: badgeLabel, type: badgeType),
                ],
              ),
              const SizedBox(height: 10),
            ] else ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [AppBadge(label: badgeLabel, type: badgeType)],
              ),
              const SizedBox(height: 6),
            ],

            // Date + price
            Row(
              children: [
                const Icon(Icons.calendar_today_outlined, size: 13, color: AppColors.textHint),
                const SizedBox(width: 4),
                Text(_fmtDate(reservation.travelDate), style: AppTextStyles.bodySmall),
                if (route != null) ...[
                  const SizedBox(width: 12),
                  const Icon(Icons.attach_money, size: 13, color: AppColors.success),
                  Text(
                    '\$${route.pricePerSeat.toStringAsFixed(0)}',
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.success),
                  ),
                ],
              ],
            ),

            // Passenger info (visible for driver view)
            if (passenger != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: AppColors.secondary.withAlpha(30),
                    child: Text(
                      passenger.initials,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.secondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      passenger.displayName,
                      style: AppTextStyles.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],

            // Action buttons
            if (showAcceptRejectActions) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _reject(context, ref),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                        minimumSize: const Size(0, 36),
                      ),
                      child: const Text('Rechazar'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _accept(context, ref),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: AppColors.white,
                        minimumSize: const Size(0, 36),
                      ),
                      child: const Text('Aceptar'),
                    ),
                  ),
                ],
              ),
            ] else if (showCancelAction && reservation.isPending) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _cancel(context, ref),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                    minimumSize: const Size(0, 36),
                  ),
                  child: const Text('Cancelar solicitud'),
                ),
              ),
            ],

            // Chat button for confirmed reservations
            if (showChatAction && reservation.isConfirmed) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _openChat(context, ref),
                  icon: const Icon(Icons.chat_bubble_outline, size: 16),
                  label: const Text('Abrir chat'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    minimumSize: const Size(0, 36),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _fmtDate(DateTime dt) {
    const months = ['', 'ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];
    return '${dt.day} de ${months[dt.month]} de ${dt.year}';
  }
}
