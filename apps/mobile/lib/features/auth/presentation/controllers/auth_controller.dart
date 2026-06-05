import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import '../../domain/models/user.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/services/sync_service.dart';
import '../../../../core/network/dio_provider.dart';

class AuthState {
  final User? user;
  final bool isLoading;
  final String? errorMessage;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.errorMessage,
  });

  AuthState copyWith({
    User? user,
    bool? isLoading,
    String? errorMessage,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final Ref _ref;
  final _storage = const FlutterSecureStorage();
  Dio get _dio => _ref.read(dioProvider);

  AuthNotifier(this._ref) : super(const AuthState()) {
    _loadPersistedUser();
  }

  Future<void> _loadPersistedUser() async {
    final token = await _storage.read(key: 'jwt_token');
    final userId = await _storage.read(key: 'user_id');
    final username = await _storage.read(key: 'username');
    final role = await _storage.read(key: 'role');

    if (token != null && userId != null && username != null && role != null) {
      if (!mounted) return;
      state = AuthState(
        user: User(id: userId, username: username, role: role, token: token),
      );
    }
  }

  Future<bool> login(String serverIp, String username, String password) async {
    state = state.copyWith(isLoading: true);
    try {
      final baseUrl = AppConfig.enableSimulationDebug
          ? 'http://$serverIp:3000/api/v1'
          : AppConfig.apiBaseUrl;

      final response = await _dio.post(
        '$baseUrl/auth/login',
        data: {'username': username, 'password': password},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final token = data['accessToken'] as String;
        final user = User.fromJson(data, token);

        // Persist token & server IP in secure storage
        await _storage.write(key: 'jwt_token', value: token);
        await _storage.write(key: 'user_id', value: user.id);
        await _storage.write(key: 'username', value: user.username);
        await _storage.write(key: 'role', value: user.role);
        await _storage.write(key: 'server_ip', value: serverIp);

        state = AuthState(user: user);

        // Proactively pull the latest product catalog and process offline checkouts
        _ref.read(syncServiceProvider).downloadCatalog();
        _ref.read(syncServiceProvider).processOfflineQueue();
        _ref.read(syncServiceProvider).fetchShopSettings();

        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Invalid credentials',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Connection failed: Check Server IP / Network',
      );
      return false;
    }
  }

  Future<bool> changePassword(String newPassword) async {
    try {
      final token = await _storage.read(key: 'jwt_token');
      if (token == null) return false;

      final baseUrl = AppConfig.enableSimulationDebug
          ? 'http://localhost:3000/api/v1'
          : AppConfig.apiBaseUrl;

      final response = await _dio.put(
        '$baseUrl/auth/change-password',
        data: {'newPassword': newPassword},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: 'jwt_token');
    await _storage.delete(key: 'user_id');
    await _storage.delete(key: 'username');
    await _storage.delete(key: 'role');
    await _storage.delete(key: 'server_ip');
    state = const AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref);
});
