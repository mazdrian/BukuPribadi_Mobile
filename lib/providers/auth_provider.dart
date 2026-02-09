import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/local_auth_service.dart';
import '../models/user_model.dart';

final authServiceProvider = Provider<LocalAuthService>((ref) {
  return LocalAuthService();
});

// Auth state notifier to manage authentication state
class AuthStateNotifier extends Notifier<AsyncValue<UserModel?>> {
  @override
  AsyncValue<UserModel?> build() {
    _checkAuthState();
    return const AsyncValue.loading();
  }

  Future<void> _checkAuthState() async {
    try {
      final authService = ref.read(authServiceProvider);
      final user = await authService.getCurrentUser();
      state = AsyncValue.data(user);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    await _checkAuthState();
  }

  Future<void> signOut() async {
    final authService = ref.read(authServiceProvider);
    await authService.signOut();
    state = const AsyncValue.data(null);
  }
}

final authStateProvider =
    NotifierProvider<AuthStateNotifier, AsyncValue<UserModel?>>(
  AuthStateNotifier.new,
);

final currentUserProvider = Provider<UserModel?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) => user,
    loading: () => null,
    error: (_, __) => null,
  );
});
