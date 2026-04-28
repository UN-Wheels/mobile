import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_controller.dart';
import '../../auth/domain/user.dart';
import '../../vehicles/domain/vehicle.dart';
import '../data/profile_api.dart';

// ── Profile ───────────────────────────────────────────────────────────────────

class ProfileNotifier extends AsyncNotifier<User> {
  @override
  Future<User> build() async {
    return ref.read(profileApiProvider).getMe();
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    final updated = await ref.read(profileApiProvider).updateMe(data);
    state = AsyncData(updated);
  }
}

final profileProvider = AsyncNotifierProvider<ProfileNotifier, User>(
  ProfileNotifier.new,
);

// ── Vehicles ──────────────────────────────────────────────────────────────────

class VehiclesNotifier extends AsyncNotifier<List<Vehicle>> {
  @override
  Future<List<Vehicle>> build() async {
    final user = await ref.watch(authControllerProvider.future);
    if (user == null) return [];
    return ref.read(profileApiProvider).getMyVehicles();
  }

  Future<void> addVehicle(Map<String, dynamic> data) async {
    final vehicle = await ref.read(profileApiProvider).createVehicle(data);
    // Use valueOrNull so this works even when the initial fetch failed
    final current = state.valueOrNull ?? [];
    state = AsyncValue.data([...current, vehicle]);
  }

  Future<void> deleteVehicle(String id) async {
    await ref.read(profileApiProvider).deleteVehicle(id);
    state = state.whenData((list) => list.where((v) => v.id != id).toList());
  }
}

final vehiclesProvider = AsyncNotifierProvider<VehiclesNotifier, List<Vehicle>>(
  VehiclesNotifier.new,
);

// ── Logout ────────────────────────────────────────────────────────────────────

final logoutProvider = Provider<Future<void> Function()>(
  (ref) => () => ref.read(authControllerProvider.notifier).logout(),
);
