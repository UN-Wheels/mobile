import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_badge.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/loading.dart';
import '../application/routes_providers.dart';
import '../data/routes_api.dart';
import '../domain/app_route.dart';
import '../domain/route_slot.dart';

class RouteDetailPage extends ConsumerStatefulWidget {
  const RouteDetailPage({required this.id, super.key});

  final String id;

  @override
  ConsumerState<RouteDetailPage> createState() => _RouteDetailPageState();
}

class _RouteDetailPageState extends ConsumerState<RouteDetailPage> {
  RouteSlot? _selectedSlot;
  bool _reserving = false;

  Future<void> _reserve(BuildContext ctx) async {
    if (_selectedSlot == null) return;
    setState(() => _reserving = true);
    try {
      await ref.read(routesApiProvider).requestReservation(
            widget.id,
            _selectedSlot!.date,
          );
      if (!ctx.mounted) return;
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(
          content: Text('¡Solicitud enviada! El conductor debe aceptarla.'),
          backgroundColor: AppColors.success,
        ),
      );
      setState(() => _selectedSlot = null);
    } catch (e) {
      if (!ctx.mounted) return;
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _reserving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final routeAsync = ref.watch(routeDetailProvider(widget.id));
    final slotsAsync = ref.watch(routeSlotsProvider(widget.id));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Detalle de ruta')),
      body: routeAsync.when(
        loading: () => const Loading(message: 'Cargando ruta...'),
        error: (e, _) => EmptyState(
          message: 'No se pudo cargar la ruta.\n$e',
          icon: Icons.error_outline,
          actionLabel: 'Reintentar',
          onAction: () => ref.invalidate(routeDetailProvider(widget.id)),
        ),
        data: (route) => Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _RouteHeader(route: route),
                    const SizedBox(height: 16),
                    _DriverCard(route: route),
                    const SizedBox(height: 16),
                    if (route.vehicle != null) ...[
                      _VehicleCard(vehicle: route.vehicle!),
                      const SizedBox(height: 16),
                    ],
                    _SlotsSection(
                      slotsAsync: slotsAsync,
                      selected: _selectedSlot,
                      onSelect: (slot) => setState(() => _selectedSlot = slot),
                      onRetry: () => ref.invalidate(routeSlotsProvider(widget.id)),
                    ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
            _ReserveBar(
              slot: _selectedSlot,
              loading: _reserving,
              pricePerSeat: route.pricePerSeat,
              onReserve: () => _reserve(context),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _RouteHeader extends StatelessWidget {
  const _RouteHeader({required this.route});
  final AppRoute route;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: const Border.fromBorderSide(BorderSide(color: AppColors.border)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('ORIGEN', style: TextStyle(fontSize: 10, color: AppColors.textHint, fontWeight: FontWeight.w600, letterSpacing: 1)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.my_location, color: AppColors.primary, size: 16),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(route.origin.name, style: AppTextStyles.label, maxLines: 2, overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(20),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_forward, color: AppColors.primary, size: 16),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('DESTINO', style: TextStyle(fontSize: 10, color: AppColors.textHint, fontWeight: FontWeight.w600, letterSpacing: 1)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: AppColors.secondary, size: 16),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(route.destination.name, style: AppTextStyles.label, maxLines: 2, overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            children: [
              _MetaChip(icon: Icons.schedule_outlined, label: _fmtTime(route.departureTime)),
              const SizedBox(width: 8),
              _MetaChip(
                icon: Icons.attach_money,
                label: '\$${route.pricePerSeat.toStringAsFixed(0)} / cupo',
                color: AppColors.success,
              ),
              const Spacer(),
              AppBadge(
                label: route.isActive ? 'Activa' : route.status,
                type: route.isActive ? BadgeType.success : BadgeType.neutral,
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _fmtTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label, this.color = AppColors.textSecondary});
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(label, style: AppTextStyles.bodySmall.copyWith(color: color, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class _DriverCard extends StatelessWidget {
  const _DriverCard({required this.route});
  final AppRoute route;

  @override
  Widget build(BuildContext context) {
    final driver = route.driver;
    final name = driver?.displayName ?? route.driverId;
    final initials = driver?.initials ?? (route.driverId.isNotEmpty ? route.driverId[0].toUpperCase() : '?');
    final email = driver?.email;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: const Border.fromBorderSide(BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.primary.withAlpha(30),
            child: Text(
              initials,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: AppTextStyles.label),
                if (email != null)
                  Text(email, style: AppTextStyles.bodySmall),
                const SizedBox(height: 4),
                const Text('Conductor verificado', style: TextStyle(fontSize: 11, color: AppColors.success, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          const Icon(Icons.verified_user_outlined, color: AppColors.success, size: 20),
        ],
      ),
    );
  }
}

class _VehicleCard extends StatelessWidget {
  const _VehicleCard({required this.vehicle});
  final VehicleInfo vehicle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: const Border.fromBorderSide(BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.secondary.withAlpha(20),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.directions_car, color: AppColors.secondary),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(vehicle.summary, style: AppTextStyles.label),
              Text(vehicle.color, style: AppTextStyles.bodySmall),
            ],
          ),
        ],
      ),
    );
  }
}

class _SlotsSection extends StatelessWidget {
  const _SlotsSection({
    required this.slotsAsync,
    required this.selected,
    required this.onSelect,
    required this.onRetry,
  });

  final AsyncValue<List<RouteSlot>> slotsAsync;
  final RouteSlot? selected;
  final ValueChanged<RouteSlot?> onSelect;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Fechas disponibles', style: AppTextStyles.h4),
        const SizedBox(height: 12),
        slotsAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          ),
          error: (e, _) => EmptyState(
            message: 'No se pudieron cargar los horarios.',
            icon: Icons.calendar_month_outlined,
            actionLabel: 'Reintentar',
            onAction: onRetry,
          ),
          data: (slots) {
            final available = slots.where((s) => s.hasAvailability).toList();
            if (available.isEmpty) {
              return const EmptyState(
                message: 'No hay fechas con cupos disponibles.',
                icon: Icons.event_busy_outlined,
              );
            }
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: available.map((slot) {
                final isSelected = selected?.date == slot.date;
                return GestureDetector(
                  onTap: () => onSelect(isSelected ? null : slot),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : AppColors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.border,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _fmtDate(slot.date),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? AppColors.white : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${slot.availableSeats} cupo${slot.availableSeats != 1 ? 's' : ''}',
                          style: TextStyle(
                            fontSize: 11,
                            color: isSelected ? AppColors.white.withAlpha(200) : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  static String _fmtDate(DateTime dt) {
    const months = ['', 'ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];
    return '${dt.day} ${months[dt.month]}';
  }
}

class _ReserveBar extends StatelessWidget {
  const _ReserveBar({
    required this.slot,
    required this.loading,
    required this.pricePerSeat,
    required this.onReserve,
  });

  final RouteSlot? slot;
  final bool loading;
  final double pricePerSeat;
  final VoidCallback onReserve;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          if (slot != null) ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '\$${pricePerSeat.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                Text(
                  _fmtDate(slot!.date),
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
            const SizedBox(width: 16),
          ],
          Expanded(
            child: ElevatedButton(
              onPressed: slot == null || loading ? null : onReserve,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              child: loading
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white),
                    )
                  : Text(slot == null ? 'Selecciona una fecha' : 'Solicitar cupo'),
            ),
          ),
        ],
      ),
    );
  }

  static String _fmtDate(DateTime dt) {
    const months = ['', 'ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];
    return '${dt.day} de ${months[dt.month]}';
  }
}
