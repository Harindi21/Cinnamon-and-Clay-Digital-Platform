import 'package:flutter/foundation.dart';

const bool appEnvironmentWasProvided = bool.hasEnvironment('APP_ENVIRONMENT');

const String appEnvironmentName = String.fromEnvironment(
  'APP_ENVIRONMENT',
  defaultValue: 'local',
);

const String apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:8082',
);

const String oidcIssuerUrl = String.fromEnvironment(
  'OIDC_ISSUER_URL',
  defaultValue: 'http://localhost:8081/realms/cinnamon-clay',
);

const String oidcClientId = String.fromEnvironment(
  'OIDC_CLIENT_ID',
  defaultValue: 'cinnamon-clay-admin-mobile',
);

const String oidcRedirectUrl = String.fromEnvironment(
  'OIDC_REDIRECT_URL',
  defaultValue: 'dev.cinnamonandclay.admin:/oauthredirect',
);

const String oidcPostLogoutRedirectUrl = String.fromEnvironment(
  'OIDC_POST_LOGOUT_REDIRECT_URL',
  defaultValue: oidcRedirectUrl,
);

const bool oidcAllowInsecureConnections = bool.fromEnvironment(
  'OIDC_ALLOW_INSECURE',
  defaultValue: appEnvironmentName == 'local',
);

const String _nativeRedirectUrl = 'dev.cinnamonandclay.admin:/oauthredirect';

const Set<String> _knownEnvironments = <String>{
  'local',
  'staging',
  'production',
};

List<String> validateAdminEnvironment({
  String environment = appEnvironmentName,
  String apiUrl = apiBaseUrl,
  String issuerUrl = oidcIssuerUrl,
  String clientId = oidcClientId,
  String redirectUrl = oidcRedirectUrl,
  String postLogoutRedirectUrl = oidcPostLogoutRedirectUrl,
  bool allowInsecure = oidcAllowInsecureConnections,
  bool releaseMode = kReleaseMode,
  bool environmentWasProvided = appEnvironmentWasProvided,
}) {
  final errors = <String>[];
  final normalizedEnvironment = environment.trim().toLowerCase();

  if (!_knownEnvironments.contains(normalizedEnvironment)) {
    errors.add(
      'APP_ENVIRONMENT must be one of ${_knownEnvironments.join(', ')}.',
    );
  }

  if (releaseMode && !environmentWasProvided) {
    errors.add('Release builds must define APP_ENVIRONMENT explicitly.');
  }
  if (releaseMode && normalizedEnvironment == 'local') {
    errors.add('Release builds cannot use APP_ENVIRONMENT=local.');
  }

  final api = Uri.tryParse(apiUrl);
  if (!_isHttpEndpoint(api)) {
    errors.add('API_BASE_URL must be an absolute HTTP(S) URL.');
  }

  final issuer = Uri.tryParse(issuerUrl);
  if (!_isHttpEndpoint(issuer)) {
    errors.add('OIDC_ISSUER_URL must be an absolute HTTP(S) URL.');
  }

  if (clientId.trim().isEmpty) {
    errors.add('OIDC_CLIENT_ID must not be empty.');
  }

  _validateRedirect(redirectUrl, name: 'OIDC_REDIRECT_URL', errors: errors);
  _validateRedirect(
    postLogoutRedirectUrl,
    name: 'OIDC_POST_LOGOUT_REDIRECT_URL',
    errors: errors,
  );

  if (normalizedEnvironment != 'local') {
    if (api?.scheme != 'https') {
      errors.add('Non-local API_BASE_URL must use HTTPS.');
    }
    if (issuer?.scheme != 'https') {
      errors.add('Non-local OIDC_ISSUER_URL must use HTTPS.');
    }
    if (allowInsecure) {
      errors.add(
        'OIDC_ALLOW_INSECURE must be false outside local development.',
      );
    }
  }

  return errors;
}

void validateAdminEnvironmentOrThrow() {
  final errors = validateAdminEnvironment();
  if (errors.isNotEmpty) {
    throw StateError(
      'Invalid Cinnamon & Clay admin environment:\n- ${errors.join('\n- ')}',
    );
  }
}

bool _isHttpEndpoint(Uri? value) {
  if (value == null || !value.hasScheme || value.host.isEmpty) {
    return false;
  }
  return value.scheme == 'http' || value.scheme == 'https';
}

void _validateRedirect(
  String value, {
  required String name,
  required List<String> errors,
}) {
  final redirect = Uri.tryParse(value);
  if (redirect == null || !redirect.hasScheme || redirect.path.isEmpty) {
    errors.add('$name must be an absolute custom-scheme URI.');
    return;
  }

  if (redirect.scheme != redirect.scheme.toLowerCase()) {
    errors.add('$name scheme must be lowercase.');
  }

  if (redirect.scheme == 'http' || redirect.scheme == 'https') {
    errors.add('$name must use the native application custom scheme.');
  }

  if (redirect.scheme != 'dev.cinnamonandclay.admin') {
    errors.add(
      '$name scheme must remain dev.cinnamonandclay.admin to match Android and Keycloak.',
    );
    return;
  }

  if (value != _nativeRedirectUrl) {
    errors.add(
      '$name must remain $_nativeRedirectUrl to match Android and Keycloak.',
    );
  }
}
