import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/loading.dart';
import '../../../core/widgets/star_rating.dart';
import '../../auth/domain/user.dart';
import '../../vehicles/domain/vehicle.dart';
import '../../vehicles/presentation/add_vehicle_sheet.dart';
import '../application/profile_providers.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mi perfil')),
      body: profileAsync.when(
        loading: () => const Loading(message: 'Cargando perfil...'),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 12),
              Text('No se pudo cargar el perfil.\n$e',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              AppButton(
                label: 'Reintentar',
                onPressed: () => ref.invalidate(profileProvider),
              ),
            ],
          ),
        ),
        data: (user) => _ProfileBody(user: user),
      ),
    );
  }
}

// ── Body ──────────────────────────────────────────────────────────────────────

class _ProfileBody extends ConsumerWidget {
  const _ProfileBody({required this.user});

  final User user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => ref.refresh(profileProvider.future),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ProfileHeader(user: user),
          const SizedBox(height: 16),
          if ((user.totalTrips != null && user.totalTrips! > 0) ||
              user.avgRating != null) ...[
            _StatsRow(user: user),
            const SizedBox(height: 16),
          ],
          _InfoCard(user: user),
          const SizedBox(height: 16),
          const _VehiclesCard(),
          const SizedBox(height: 24),
          _LogoutButton(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.white,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            _Avatar(user: user),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.fullName, style: AppTextStyles.h4),
                  const SizedBox(height: 2),
                  Text(user.email,
                      style: AppTextStyles.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 8),
                  _RoleBadge(role: user.role),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    final picture = user.profilePicture;
    if (picture != null && picture.isNotEmpty) {
      return CircleAvatar(
        radius: 36,
        backgroundImage: CachedNetworkImageProvider(picture),
        backgroundColor: AppColors.primary.withAlpha(30),
      );
    }
    return CircleAvatar(
      radius: 36,
      backgroundColor: AppColors.primary.withAlpha(40),
      child: Text(
        user.initials,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.role});

  final String role;

  @override
  Widget build(BuildContext context) {
    final isDriver = role == 'docente' || role == 'driver';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: (isDriver ? AppColors.info : AppColors.primary).withAlpha(25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: (isDriver ? AppColors.info : AppColors.primary).withAlpha(80),
        ),
      ),
      child: Text(
        isDriver ? 'Conductor' : 'Pasajero',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isDriver ? AppColors.info : AppColors.primary,
        ),
      ),
    );
  }
}

// ── Stats ─────────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (user.totalTrips != null)
          Expanded(
            child: _StatChip(
              icon: Icons.directions_car_outlined,
              label: '${user.totalTrips} viajes',
            ),
          ),
        if (user.totalTrips != null && user.avgRating != null)
          const SizedBox(width: 12),
        if (user.avgRating != null)
          Expanded(
            child: _StatChip(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  StarRating(rating: user.avgRating!, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    user.avgRating!.toStringAsFixed(1),
                    style: const TextStyle(
                      color: AppColors.warning,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({this.icon, this.label, this.child});

  final IconData? icon;
  final String? label;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: child ??
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null)
                Icon(icon, size: 16, color: AppColors.primary),
              if (icon != null) const SizedBox(width: 6),
              Text(
                label ?? '',
                style: const TextStyle(
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
    );
  }
}

// ── Info card ─────────────────────────────────────────────────────────────────

class _InfoCard extends ConsumerWidget {
  const _InfoCard({required this.user});

  final User user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      color: AppColors.white,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Información personal', style: AppTextStyles.h4),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.edit_outlined,
                      size: 18, color: AppColors.primary),
                  onPressed: () => _showEditSheet(context, ref),
                  tooltip: 'Editar',
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _InfoRow(Icons.phone_outlined, 'Teléfono', user.phone ?? '—'),
            _InfoRow(Icons.school_outlined, 'Carrera', user.major ?? '—'),
            _InfoRow(Icons.person_outline, 'Género', _genderLabel(user.gender)),
            _InfoRow(Icons.cake_outlined, 'Edad',
                user.age != null ? '${user.age} años' : '—'),
          ],
        ),
      ),
    );
  }

  String _genderLabel(String? g) => switch (g?.toLowerCase()) {
        'masculino' || 'male' => 'Masculino',
        'femenino' || 'female' => 'Femenino',
        'otro' || 'other' => 'Otro',
        'prefiero no decir' || 'prefer_not_to_say' => 'Prefiero no decir',
        _ => g ?? '—',
      };

  void _showEditSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.authBg2,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _EditProfileSheet(user: user),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.icon, this.label, this.value);

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textHint),
          const SizedBox(width: 10),
          Text('$label: ',
              style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Edit profile sheet ────────────────────────────────────────────────────────

class _EditProfileSheet extends ConsumerStatefulWidget {
  const _EditProfileSheet({required this.user});

  final User user;

  @override
  ConsumerState<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends ConsumerState<_EditProfileSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.user.fullName);
    _phoneCtrl = TextEditingController(text: widget.user.phone ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    setState(() => _saving = true);
    try {
      await ref.read(profileProvider.notifier).updateProfile({
        'fullName': name,
        if (_phoneCtrl.text.trim().isNotEmpty) 'phone': _phoneCtrl.text.trim(),
      });
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Perfil actualizado.'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Editar perfil', style: AppTextStyles.h4),
          const SizedBox(height: 16),
          TextFormField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              labelText: 'Nombre completo',
              prefixIcon: Icon(Icons.person_outline),
            ),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _phoneCtrl,
            decoration: const InputDecoration(
              labelText: 'Teléfono',
              prefixIcon: Icon(Icons.phone_outlined),
            ),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.white),
                    )
                  : const Text('Guardar'),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Vehicles card ─────────────────────────────────────────────────────────────

class _VehiclesCard extends ConsumerWidget {
  const _VehiclesCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehiclesAsync = ref.watch(vehiclesProvider);

    return Card(
      color: AppColors.white,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Mis vehículos', style: AppTextStyles.h4),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline,
                      color: AppColors.primary),
                  onPressed: () => _showAddSheet(context, ref),
                  tooltip: 'Agregar vehículo',
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
            const SizedBox(height: 8),
            vehiclesAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
              error: (e, _) => Text('Error cargando vehículos: $e',
                  style: const TextStyle(color: AppColors.error, fontSize: 12)),
              data: (vehicles) {
                if (vehicles.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'No tienes vehículos registrados.',
                      style: TextStyle(
                          color: AppColors.textHint, fontSize: 13),
                    ),
                  );
                }
                return Column(
                  children: vehicles
                      .map((v) => _VehicleTile(
                            vehicle: v,
                            onDelete: () => _confirmDelete(context, ref, v),
                          ))
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, Vehicle v) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Eliminar vehículo'),
        content: Text('¿Eliminar ${v.displayName}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await ref.read(vehiclesProvider.notifier).deleteVehicle(v.id);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  void _showAddSheet(BuildContext context, WidgetRef ref) {
    showAddVehicleSheet(context);
  }
}

class _VehicleTile extends StatelessWidget {
  const _VehicleTile({required this.vehicle, required this.onDelete});

  final Vehicle vehicle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(vehicle.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: AppColors.error.withAlpha(200),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) => onDelete(),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const Icon(Icons.directions_car_outlined,
                size: 18, color: AppColors.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${vehicle.brand} ${vehicle.model}',
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                        fontSize: 13),
                  ),
                  Text(
                    '${vehicle.plate} · ${vehicle.color}',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  size: 18, color: AppColors.error),
              onPressed: onDelete,
              constraints: const BoxConstraints(),
              padding: const EdgeInsets.only(left: 8),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Logout button ─────────────────────────────────────────────────────────────

class _LogoutButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return OutlinedButton.icon(
      onPressed: () => _confirmLogout(context, ref),
      icon: const Icon(Icons.logout, color: AppColors.error),
      label:
          const Text('Cerrar sesión', style: TextStyle(color: AppColors.error)),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: AppColors.error),
        minimumSize: const Size(double.infinity, 48),
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Seguro que quieres cerrar sesión?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await ref.read(logoutProvider)();
  }
}
