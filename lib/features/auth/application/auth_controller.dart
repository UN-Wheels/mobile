import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/secure_storage.dart';
import '../data/auth_repository.dart';
import '../domain/auth_request.dart';
import '../domain/user.dart';

class AuthController extends AsyncNotifier<User?> {
  AuthRepository get _repo => ref.read(authRepositoryProvider);

  @override
  Future<User?> build() async {
    final hasToken = await ref.read(secureStorageProvider).hasToken();
    if (!hasToken) return null;
    try {
      return await _repo.getCurrentUser();
    } catch (_) {
      // Token inválido o expirado
      await ref.read(secureStorageProvider).clearAll();
      return null;
    }
  }

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _repo.login(email, password),
    );
  }

  Future<void> register(RegisterRequest request) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _repo.register(request),
    );
  }

  Future<void> logout() async {
    await _repo.logout();
    state = const AsyncValue.data(null);
  }

  Future<void> updateUser(User updated) async {
    state = AsyncValue.data(updated);
  }
}

final authControllerProvider =
    AsyncNotifierProvider<AuthController, User?>(AuthController.new);
