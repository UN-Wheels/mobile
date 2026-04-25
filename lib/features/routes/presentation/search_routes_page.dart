import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_badge.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/loading.dart';
import '../application/routes_providers.dart';
import '../domain/app_route.dart';

class SearchRoutesPage extends ConsumerWidget {
  const SearchRoutesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(availableRoutesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Buscar rutas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: () => ref.invalidate(availableRoutesProvider),
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => ref.refresh(availableRoutesProvider.future),
        child: state.when(
          loading: () => const Loading(message: 'Buscando rutas...'),
          error: (e, _) => EmptyState(
            message: 'No se pudieron cargar las rutas.\n${e.toString()}',
            icon: Icons.wifi_off_outlined,
            actionLabel: 'Reintentar',
            onAction: () => ref.invalidate(availableRoutesProvider),
          ),
          data: (routes) {
            if (routes.isEmpty) {
              return const EmptyState(
                message: 'No hay rutas disponibles en este momento.',
                icon: Icons.route_outlined,
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: routes.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, i) => _RouteCard(route: routes[i]),
            );
          },
        ),
      ),
    );
  }
}

class _RouteCard extends StatelessWidget {
  const _RouteCard({required this.route});

  final AppRoute route;

  @override
  Widget build(BuildContext context) {
    final driver = route.driver;
    final driverLabel = driver != null ? driver.displayName : route.driverId;
    final driverInitials = driver != null ? driver.initials : _initials(route.driverId);

    return AppCard(
      padding: const EdgeInsets.all(0),
      onTap: () => context.push(RouteNames.routeDetailOf(route.id)),
      child: Column(
        children: [
          // Teal top accent bar
          Container(
            height: 4,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Origin → Destination
                Row(
                  children: [
                    const Icon(Icons.my_location, color: AppColors.primary, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        route.origin.name,
                        style: AppTextStyles.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 7),
                  child: Container(
                    width: 2,
                    height: 12,
                    color: AppColors.border,
                  ),
                ),
                Row(
                  children: [
                    const Icon(Icons.location_on, color: AppColors.secondary, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        route.destination.name,
                        style: AppTextStyles.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Meta row
                Row(
                  children: [
                    // Time
                    const Icon(Icons.schedule_outlined, size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(_formatTime(route.departureTime), style: AppTextStyles.bodySmall),
                    const SizedBox(width: 12),
                    // Price
                    const Icon(Icons.attach_money, size: 14, color: AppColors.success),
                    const SizedBox(width: 2),
                    Text(
                      '\$${route.pricePerSeat.toStringAsFixed(0)}/cupo',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    AppBadge(
                      label: route.isActive ? 'Activa' : route.status,
                      type: route.isActive ? BadgeType.success : BadgeType.neutral,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Driver row
                Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: AppColors.primary.withAlpha(30),
                      child: Text(
                        driverInitials,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        driverLabel,
                        style: AppTextStyles.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: AppColors.textHint, size: 18),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _formatTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  static String _initials(String text) {
    if (text.isEmpty) return '?';
    return text[0].toUpperCase();
  }
}
