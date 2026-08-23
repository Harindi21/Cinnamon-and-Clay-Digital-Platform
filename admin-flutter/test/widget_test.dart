import 'package:cinnamon_clay_admin/src/app.dart';
import 'package:cinnamon_clay_admin/src/auth/auth_models.dart';
import 'package:cinnamon_clay_admin/src/auth/auth_repository.dart';
import 'package:cinnamon_clay_admin/src/catalog/catalog_models.dart';
import 'package:cinnamon_clay_admin/src/catalog/catalog_repository.dart';
import 'package:cinnamon_clay_admin/src/reviews/review_models.dart';
import 'package:cinnamon_clay_admin/src/reviews/review_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('signed-out app shows oidc sign-in', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            _FakeAuthRepository(const AuthState.signedOut()),
          ),
        ],
        child: const CinnamonClayAdminApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Administration'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
  });

  testWidgets('authenticated app opens catalog', (tester) async {
    const identity = AdminIdentity(
      subject: 'admin-1',
      username: 'local.admin',
      email: 'local.admin@cinnamonandclay.test',
      roles: <String>['admin'],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            _FakeAuthRepository(const AuthState.authenticated(identity)),
          ),
          catalogProvider.overrideWith((ref) async => const <MenuCategory>[]),
          reviewsProvider.overrideWith((ref) async => const <AdminReview>[]),
        ],
        child: const CinnamonClayAdminApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Catalog'), findsWidgets);
    expect(find.text('Reviews'), findsOneWidget);

    await tester.tap(find.text('Reviews'));
    await tester.pumpAndSettle();

    expect(find.text('No reviews yet.'), findsOneWidget);
  });
}

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository(this.state);

  final AuthState state;

  @override
  Future<void> clearLocalSession() async {}

  @override
  Future<String> validAccessToken() async => 'test-token';

  @override
  Future<AuthState> restore() async => state;

  @override
  Future<AuthState> signIn() async => state;

  @override
  Future<void> signOut() async {}
}
