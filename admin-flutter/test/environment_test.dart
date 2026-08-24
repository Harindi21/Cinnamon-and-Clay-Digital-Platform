import 'package:cinnamon_clay_admin/src/core/environment.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('local development accepts the documented loopback endpoints', () {
    final errors = validateAdminEnvironment(
      environment: 'local',
      apiUrl: 'http://localhost:8082',
      issuerUrl: 'http://localhost:8081/realms/cinnamon-clay',
      clientId: 'cinnamon-clay-admin-mobile',
      redirectUrl: 'dev.cinnamonandclay.admin:/oauthredirect',
      postLogoutRedirectUrl: 'dev.cinnamonandclay.admin:/oauthredirect',
      allowInsecure: true,
    );

    expect(errors, isEmpty);
  });

  test('production rejects cleartext endpoints and insecure oidc', () {
    final errors = validateAdminEnvironment(
      environment: 'production',
      apiUrl: 'http://api.example.test',
      issuerUrl: 'http://identity.example.test/realms/cinnamon-clay',
      clientId: 'cinnamon-clay-admin-mobile',
      redirectUrl: 'dev.cinnamonandclay.admin:/oauthredirect',
      postLogoutRedirectUrl: 'dev.cinnamonandclay.admin:/oauthredirect',
      allowInsecure: true,
    );

    expect(errors, contains('Non-local API_BASE_URL must use HTTPS.'));
    expect(errors, contains('Non-local OIDC_ISSUER_URL must use HTTPS.'));
    expect(
      errors,
      contains('OIDC_ALLOW_INSECURE must be false outside local development.'),
    );
  });

  test('production accepts secure endpoints', () {
    final errors = validateAdminEnvironment(
      environment: 'production',
      apiUrl: 'https://api.cinnamon-clay.example',
      issuerUrl: 'https://identity.cinnamon-clay.example/realms/cinnamon-clay',
      clientId: 'cinnamon-clay-admin-mobile',
      redirectUrl: 'dev.cinnamonandclay.admin:/oauthredirect',
      postLogoutRedirectUrl: 'dev.cinnamonandclay.admin:/oauthredirect',
      allowInsecure: false,
    );

    expect(errors, isEmpty);
  });

  test(
    'redirect scheme cannot drift from native and keycloak configuration',
    () {
      final errors = validateAdminEnvironment(
        environment: 'staging',
        apiUrl: 'https://api.staging.example',
        issuerUrl: 'https://identity.staging.example/realms/cinnamon-clay',
        clientId: 'cinnamon-clay-admin-mobile',
        redirectUrl: 'example.admin:/oauthredirect',
        postLogoutRedirectUrl: 'example.admin:/oauthredirect',
        allowInsecure: false,
      );

      expect(
        errors.where((error) => error.contains('dev.cinnamonandclay.admin')),
        hasLength(2),
      );
    },
  );

  test('release builds require an explicit non-local environment', () {
    final errors = validateAdminEnvironment(
      environment: 'local',
      apiUrl: 'http://localhost:8082',
      issuerUrl: 'http://localhost:8081/realms/cinnamon-clay',
      clientId: 'cinnamon-clay-admin-mobile',
      redirectUrl: 'dev.cinnamonandclay.admin:/oauthredirect',
      postLogoutRedirectUrl: 'dev.cinnamonandclay.admin:/oauthredirect',
      allowInsecure: true,
      releaseMode: true,
      environmentWasProvided: false,
    );

    expect(
      errors,
      contains('Release builds must define APP_ENVIRONMENT explicitly.'),
    );
    expect(
      errors,
      contains('Release builds cannot use APP_ENVIRONMENT=local.'),
    );
  });

  test('redirect path cannot drift from the registered native callback', () {
    final errors = validateAdminEnvironment(
      environment: 'production',
      apiUrl: 'https://api.cinnamon-clay.example',
      issuerUrl: 'https://identity.cinnamon-clay.example/realms/cinnamon-clay',
      clientId: 'cinnamon-clay-admin-mobile',
      redirectUrl: 'dev.cinnamonandclay.admin:/different-path',
      postLogoutRedirectUrl: 'dev.cinnamonandclay.admin:/oauthredirect',
      allowInsecure: false,
    );

    expect(
      errors,
      contains(
        'OIDC_REDIRECT_URL must remain dev.cinnamonandclay.admin:/oauthredirect to match Android and Keycloak.',
      ),
    );
  });
}
