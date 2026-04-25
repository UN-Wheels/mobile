import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/secure_storage.dart';
import '../domain/auth_request.dart';
import '../domain/user.dart';
import 'auth_api.dart';

class AuthRepository {
  const AuthRepository(this._api, this._storage);

  final AuthApi _api;
  final SecureStorage _storage;

  Future<User?> getCurrentUser() async {
    final hasToken = await _storage.hasToken();
    if (!hasToken) return null;
    return _api.getMe();
  }

  Future<User> login(String email, String password) async {
    final result = await _api.login(
      LoginRequest(username: email, password: password),
    );
    await _storage.setToken(result.token);
    return result.user;
  }

  Future<User> register(RegisterRequest request) async {
    await _api.register(request);
    // Después de registrar, hacer login automático para obtener el token
    return login(request.email, request.password);
  }

  Future<void> logout() async {
    await _api.logout();
    await _storage.clearAll();
  }

  Future<User> updateProfile(Map<String, dynamic> data) async {
    return _api.updateProfile(data);
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    ref.read(authApiProvider),
    ref.read(secureStorageProvider),
  );
});
