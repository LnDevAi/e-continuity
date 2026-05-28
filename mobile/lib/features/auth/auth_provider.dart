import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/api_client.dart';

const _storage = FlutterSecureStorage();

class AuthState {
  final bool isLoading;
  final bool isAuthenticated;
  final Map<String, dynamic>? user;
  final String? error;

  const AuthState({
    this.isLoading = false,
    this.isAuthenticated = false,
    this.user,
    this.error,
  });

  AuthState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    Map<String, dynamic>? user,
    String? error,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      user: user ?? this.user,
      error: error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiClient _api;

  AuthNotifier(this._api) : super(const AuthState()) {
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final token = await _storage.read(key: 'access_token');
    if (token != null) {
      try {
        final response = await _api.getProfile();
        state = state.copyWith(
          isAuthenticated: true,
          user: Map<String, dynamic>.from(response.data),
        );
      } catch (_) {
        await _storage.deleteAll();
      }
    }
  }

  Future<bool> login({required String email, required String password}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _api.login({'email': email, 'password': password});
      final data = response.data as Map<String, dynamic>;

      await _storage.write(key: 'access_token', value: data['accessToken']);
      await _storage.write(key: 'refresh_token', value: data['refreshToken']);
      await _storage.write(key: 'user_id', value: data['user']['id']);

      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        user: Map<String, dynamic>.from(data['user']),
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Email ou mot de passe incorrect',
      );
      return false;
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _api.register({
        'email': email,
        'password': password,
        'firstName': firstName,
        'lastName': lastName,
      });
      final data = response.data as Map<String, dynamic>;

      await _storage.write(key: 'access_token', value: data['accessToken']);
      await _storage.write(key: 'refresh_token', value: data['refreshToken']);
      await _storage.write(key: 'user_id', value: data['user']['id']);
      // Clé privée stockée sécurisément — une seule fois
      if (data['privateKey'] != null) {
        await _storage.write(key: 'private_key', value: data['privateKey']);
      }

      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        user: Map<String, dynamic>.from(data['user']),
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: "Erreur lors de l'inscription. Email peut-être déjà utilisé.",
      );
      return false;
    }
  }

  Future<void> logout() async {
    await _storage.deleteAll();
    state = const AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final api = ref.watch(apiClientProvider);
  return AuthNotifier(api);
});
