import 'package:cinnamon_clay_admin/src/app.dart';
import 'package:cinnamon_clay_admin/src/auth/auth_models.dart';
import 'package:cinnamon_clay_admin/src/auth/auth_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Android runner launches the signed-out administration shell', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(_SignedOutAuthRepository()),
        ],
        child: const CinnamonClayAdminApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Cinnamon & Clay'), findsOneWidget);
    expect(find.text('Administration'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
  });
}

class _SignedOutAuthRepository implements AuthRepository {
  @override
  Future<void> clearLocalSession() async {}

  @override
  Future<String> validAccessToken() async => throw AuthRequiredException();

  @override
  Future<AuthState> restore() async => const AuthState.signedOut();

  @override
  Future<AuthState> signIn() async => const AuthState.signedOut();

  @override
  Future<void> signOut() async {}
}
