import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_badge.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/loading.dart';
import '../application/routes_providers.dart';
import '../data/routes_api.dart';
import '../domain/app_route.dart';

class MyRoutesPage extends ConsumerWidget {
  const MyRoutesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(myRoutesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Mis rutas')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(RouteNames.publishRoute),
        icon: const Icon(Icons.add_road),
        label: const Text('Publicar ruta'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => ref.refresh(myRoutesProvider.future),
        child: state.when(
          loading: () => const Loading(message: 'Cargando tus rutas...'),
          error: (e, _) => EmptyState(
            message: 'No se pudieron cargar tus rutas.\n$e',
            icon: Icons.wifi_off_outlined,
            actionLabel: 'Reintentar',
            onAction: () => ref.invalidate(myRoutesProvider),
          ),
          data: (routes) {
            if (routes.isEmpty) {
              return EmptyState(
                message: 'Aún no has publicado ninguna ruta.',
                icon: Icons.add_road_outlined,
                actionLabel: 'Publicar mi primera ruta',
                onAction: () => context.push(RouteNames.publishRoute),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              itemCount: routes.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, i) => _MyRouteCard(
                route: routes[i],
                onDeleted: () => ref.invalidate(myRoutesProvider),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _MyRouteCard extends ConsumerWidget {
  const _MyRouteCard({required this.route, required this.onDeleted});

  final AppRoute route;
  final VoidCallback onDeleted;

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar ruta'),
        content: Text('¿Eliminar la ruta "${route.description}"? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await ref.read(routesApiProvider).deleteRoute(route.id);
      onDeleted();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ruta eliminada.'), backgroundColor: AppColors.success),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusType = switch (route.status) {
      'ACTIVE' => BadgeType.success,
      'IN_PROGRESS' => BadgeType.warning,
      'COMPLETED' => BadgeType.neutral,
      _ => BadgeType.neutral,
    };
    final statusLabel = switch (route.status) {
      'ACTIVE' => 'Activa',
      'IN_PROGRESS' => 'En curso',
      'COMPLETED' => 'Completada',
      'INACTIVE' => 'Inactiva',
      _ => route.status,
    };

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push(RouteNames.routeDetailOf(route.id)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(25),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.route, color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(route.origin.name, style: AppTextStyles.label, maxLines: 1, overflow: TextOverflow.ellipsis),
                        Row(
                          children: [
                            const Icon(Icons.arrow_downward, size: 10, color: AppColors.textHint),
                            const SizedBox(width: 2),
                            Expanded(
                              child: Text(route.destination.name, style: AppTextStyles.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  AppBadge(label: statusLabel, type: statusType),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.schedule_outlined, size: 13, color: AppColors.textHint),
                  const SizedBox(width: 4),
                  Text(_fmtDateTime(route.departureTime), style: AppTextStyles.bodySmall),
                  const SizedBox(width: 12),
                  const Icon(Icons.attach_money, size: 13, color: AppColors.success),
                  Text(
                    '\$${route.pricePerSeat.toStringAsFixed(0)} / cupo',
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.success),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    onPressed: () => _delete(context, ref),
                    tooltip: 'Eliminar',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _fmtDateTime(DateTime dt) {
    const months = ['', 'ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];
    final time = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    return '${dt.day} ${months[dt.month]} · $time';
  }
}
