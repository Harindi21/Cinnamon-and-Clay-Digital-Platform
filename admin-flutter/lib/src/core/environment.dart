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
  defaultValue: false,
);
