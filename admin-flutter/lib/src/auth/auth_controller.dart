import 'package:cinnamon_clay_admin/src/auth/auth_models.dart';
import 'package:cinnamon_clay_admin/src/auth/auth_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authControllerProvider = AsyncNotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

class AuthController extends AsyncNotifier<AuthState> {
  @override
  Future<AuthState> build() {
    return ref.watch(authRepositoryProvider).restore();
  }

  Future<void> retryRestore() async {
    state = const AsyncLoading<AuthState>();
    state = await AsyncValue.guard(ref.read(authRepositoryProvider).restore);
  }

  Future<void> signIn() async {
    final previous = state.value ?? const AuthState.signedOut();
    state = const AsyncLoading<AuthState>();

    try {
      final next = await ref.read(authRepositoryProvider).signIn();
      state = AsyncData<AuthState>(next);
    } on AuthCancelledException {
      state = AsyncData<AuthState>(previous);
    } catch (error, stackTrace) {
      state = AsyncError<AuthState>(error, stackTrace);
    }
  }

  Future<void> signOut() async {
    state = const AsyncLoading<AuthState>();
    await ref.read(authRepositoryProvider).signOut();
    state = const AsyncData<AuthState>(AuthState.signedOut());
  }

  Future<String> accessToken() async {
    try {
      return await ref.read(authRepositoryProvider).validAccessToken();
    } on AuthRequiredException {
      state = const AsyncData<AuthState>(AuthState.signedOut());
      rethrow;
    }
  }

  Future<void> expireLocalSession() async {
    await ref.read(authRepositoryProvider).clearLocalSession();
    state = const AsyncData<AuthState>(AuthState.signedOut());
  }
}
