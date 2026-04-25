import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/app_badge.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/loading.dart';
import '../../auth/application/auth_controller.dart';
import '../application/dashboard_controller.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).valueOrNull;
    final dashState = ref.watch(dashboardControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hola, ${user?.fullName.split(' ').first ?? ''}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.white,
              ),
            ),
            const Text(
              'UNWheels',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white70,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          GestureDetector(
            onTap: () => context.push(RouteNames.profile),
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: AppAvatar(
                imageUrl: user?.profilePicture,
                name: user?.fullName,
                size: 36,
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => ref.refresh(dashboardControllerProvider.future),
        child: dashState.when(
          loading: () => const Loading(message: 'Cargando...'),
          error: (e, _) => EmptyState(
            message: 'No se pudo cargar la información.\n${e.toString()}',
            icon: Icons.wifi_off_outlined,
            actionLabel: 'Reintentar',
            onAction: () => ref.invalidate(dashboardControllerProvider),
          ),
          data: (data) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── Resumen rápido ──────────────────────────────────────────
              _SummaryRow(
                trips: user?.totalTrips ?? 0,
                rating: user?.avgRating ?? 0.0,
              ),
              const SizedBox(height: 24),

              // ── Próximos viajes confirmados ─────────────────────────────
              _SectionHeader(
                title: 'Próximos viajes',
                onSeeAll: () => context.push(RouteNames.bookings),
              ),
              const SizedBox(height: 12),
              if (data.upcomingTrips.isEmpty)
                const EmptyState(
                  message: 'No tienes viajes confirmados próximos.',
                  icon: Icons.event_seat_outlined,
                )
              else
                ...data.upcomingTrips.map(
                  (r) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _TripCard(reservation: r),
                  ),
                ),

              const SizedBox(height: 24),

              // ── Mis rutas publicadas (solo si tiene) ───────────────────
              if (data.myRoutes.isNotEmpty) ...[
                _SectionHeader(
                  title: 'Mis rutas',
                  onSeeAll: () => context.push(RouteNames.myRoutes),
                ),
                const SizedBox(height: 12),
                ...data.myRoutes.take(3).map(
                      (route) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _RouteCard(route: route),
                      ),
                    ),
                const SizedBox(height: 16),
              ],

              // ── CTA buscar ruta ─────────────────────────────────────────
              _SearchCta(onTap: () => context.push(RouteNames.search)),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Widgets auxiliares ────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.onSeeAll});

  final String title;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: AppTextStyles.h4.copyWith(color: AppColors.white)),
        if (onSeeAll != null)
          TextButton(
            onPressed: onSeeAll,
            child: const Text('Ver todo'),
          ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.trips, required this.rating});

  final int trips;
  final double rating;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.directions_car,
            value: '$trips',
            label: 'Viajes',
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.star,
            value: rating > 0 ? rating.toStringAsFixed(1) : '—',
            label: 'Calificación',
            color: AppColors.warning,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: const Border.fromBorderSide(
          BorderSide(color: AppColors.border),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withAlpha(25),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(label, style: AppTextStyles.bodySmall),
            ],
          ),
        ],
      ),
    );
  }
}

class _TripCard extends StatelessWidget {
  const _TripCard({required this.reservation});

  final DashboardReservation reservation;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: () => context.push(RouteNames.routeDetailOf(reservation.routeId)),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.directions_car,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reservation.routeDescription,
                  style: AppTextStyles.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  reservation.travelDate,
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
          const AppBadge(
            label: 'Confirmado',
            type: BadgeType.success,
          ),
        ],
      ),
    );
  }
}

class _RouteCard extends StatelessWidget {
  const _RouteCard({required this.route});

  final DashboardRoute route;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: () => context.push(RouteNames.routeDetailOf(route.id)),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.secondary.withAlpha(25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.route,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  route.description,
                  style: AppTextStyles.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '\$${route.pricePerSeat.toStringAsFixed(0)} por asiento • '
                  '${route.availableSeats} disponibles',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
          AppBadge(
            label: route.status == 'active' ? 'Activa' : route.status,
            type: route.status == 'active'
                ? BadgeType.success
                : BadgeType.neutral,
          ),
        ],
      ),
    );
  }
}

class _SearchCta extends StatelessWidget {
  const _SearchCta({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.primaryDark],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '¿Necesitas un ride?',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Busca rutas disponibles ahora',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.search,
              color: AppColors.white,
              size: 32,
            ),
          ],
        ),
      ),
    );
  }
}
