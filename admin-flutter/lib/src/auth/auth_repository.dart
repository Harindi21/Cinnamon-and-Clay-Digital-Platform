import 'package:cinnamon_clay_admin/src/auth/auth_models.dart';
import 'package:cinnamon_clay_admin/src/auth/auth_token_store.dart';
import 'package:cinnamon_clay_admin/src/core/environment.dart';
import 'package:dio/dio.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final authTokenStoreProvider = Provider<AuthTokenStore>((ref) {
  return SecureAuthTokenStore(const FlutterSecureStorage());
});

final flutterAppAuthProvider = Provider<FlutterAppAuth>((ref) {
  return const FlutterAppAuth();
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return OidcAuthRepository(
    appAuth: ref.watch(flutterAppAuthProvider),
    tokenStore: ref.watch(authTokenStoreProvider),
    identityClient: Dio(
      BaseOptions(
        baseUrl: apiBaseUrl,
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 5),
        headers: const <String, String>{'Accept': 'application/json'},
      ),
    ),
  );
});

abstract interface class AuthRepository {
  Future<AuthState> restore();

  Future<AuthState> signIn();

  Future<void> signOut();

  Future<void> clearLocalSession();

  Future<String> validAccessToken();
}

class OidcAuthRepository implements AuthRepository {
  OidcAuthRepository({
    required FlutterAppAuth appAuth,
    required AuthTokenStore tokenStore,
    required Dio identityClient,
  }) : this._(appAuth, tokenStore, identityClient);

  OidcAuthRepository._(this._appAuth, this._tokenStore, this._identityClient);

  static const Duration _refreshWindow = Duration(seconds: 60);
  static const List<String> _scopes = <String>['openid', 'profile', 'email'];

  final FlutterAppAuth _appAuth;
  final AuthTokenStore _tokenStore;
  final Dio _identityClient;

  AuthTokens? _tokens;
  Future<AuthTokens>? _refreshInFlight;

  @override
  Future<AuthState> restore() async {
    _tokens = await _tokenStore.read();
    if (_tokens == null) {
      return const AuthState.signedOut();
    }

    try {
      final accessToken = await validAccessToken();
      final identity = await _fetchIdentity(accessToken);
      return AuthState.authenticated(identity);
    } on AuthRequiredException {
      return const AuthState.signedOut();
    } on DioException catch (error) {
      final status = error.response?.statusCode;
      if (status == 401) {
        await clearLocalSession();
        return const AuthState.signedOut();
      }
      if (status == 403) {
        await clearLocalSession();
        throw const AuthException(
          'This identity is authenticated but is not authorized to use the admin app.',
        );
      }
      rethrow;
    }
  }

  @override
  Future<AuthState> signIn() async {
    try {
      final response = await _appAuth.authorizeAndExchangeCode(
        AuthorizationTokenRequest(
          oidcClientId,
          oidcRedirectUrl,
          issuer: oidcIssuerUrl,
          scopes: _scopes,
          allowInsecureConnections: oidcAllowInsecureConnections,
        ),
      );

      final tokens = _tokensFromResponse(response);
      await _saveTokens(tokens);

      try {
        final identity = await _fetchIdentity(tokens.accessToken);
        return AuthState.authenticated(identity);
      } on DioException catch (error) {
        final status = error.response?.statusCode;
        if (status == 401 || status == 403) {
          await clearLocalSession();
          throw const AuthException(
            'This account cannot access Cinnamon & Clay administration.',
          );
        }
        rethrow;
      }
    } on FlutterAppAuthUserCancelledException {
      throw const AuthCancelledException();
    } on FlutterAppAuthPlatformException catch (error) {
      throw AuthException(
        error.platformErrorDetails.errorDescription ??
            error.platformErrorDetails.error ??
            'The identity provider could not complete sign-in.',
      );
    }
  }

  @override
  Future<String> validAccessToken() async {
    final current = _tokens ?? await _tokenStore.read();
    if (current == null) {
      throw const AuthRequiredException();
    }

    _tokens = current;

    if (!current.isExpiringWithin(_refreshWindow)) {
      return current.accessToken;
    }

    final refreshToken = current.refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) {
      await clearLocalSession();
      throw const AuthRequiredException();
    }

    try {
      final refreshed = await _refreshTokens(current);
      return refreshed.accessToken;
    } on FlutterAppAuthPlatformException catch (error) {
      if (error.platformErrorDetails.error ==
          FlutterAppAuthOAuthError.invalidGrant) {
        await clearLocalSession();
        throw const AuthRequiredException();
      }

      throw AuthException(
        error.platformErrorDetails.errorDescription ??
            'The administrator session could not be refreshed.',
      );
    }
  }

  Future<AuthTokens> _refreshTokens(AuthTokens current) async {
    final existingRefresh = _refreshInFlight;
    if (existingRefresh != null) {
      return existingRefresh;
    }

    final refresh = _performRefresh(current);
    _refreshInFlight = refresh;

    try {
      return await refresh;
    } finally {
      if (identical(_refreshInFlight, refresh)) {
        _refreshInFlight = null;
      }
    }
  }

  Future<AuthTokens> _performRefresh(AuthTokens current) async {
    final response = await _appAuth.token(
      TokenRequest(
        oidcClientId,
        oidcRedirectUrl,
        issuer: oidcIssuerUrl,
        refreshToken: current.refreshToken,
        scopes: _scopes,
        allowInsecureConnections: oidcAllowInsecureConnections,
      ),
    );

    final tokens = _tokensFromResponse(response, previous: current);
    await _saveTokens(tokens);
    return tokens;
  }

  AuthTokens _tokensFromResponse(
    TokenResponse response, {
    AuthTokens? previous,
  }) {
    final accessToken = response.accessToken;
    final expiresAt = response.accessTokenExpirationDateTime;

    if (accessToken == null || accessToken.isEmpty || expiresAt == null) {
      throw const AuthException(
        'The identity provider returned an incomplete token response.',
      );
    }

    return AuthTokens(
      accessToken: accessToken,
      refreshToken: response.refreshToken ?? previous?.refreshToken,
      idToken: response.idToken ?? previous?.idToken,
      expiresAt: expiresAt.toUtc(),
    );
  }

  Future<void> _saveTokens(AuthTokens tokens) async {
    _tokens = tokens;
    await _tokenStore.write(tokens);
  }

  Future<AdminIdentity> _fetchIdentity(String accessToken) async {
    final response = await _identityClient.get<Map<String, dynamic>>(
      '/api/v1/admin/me',
      options: Options(
        headers: <String, String>{'Authorization': 'Bearer $accessToken'},
      ),
    );

    final data = response.data;
    if (data == null) {
      throw const AuthException('The admin identity API returned no body.');
    }

    return AdminIdentity.fromJson(data);
  }

  @override
  Future<void> signOut() async {
    final current = _tokens ?? await _tokenStore.read();

    try {
      final idToken = current?.idToken;
      if (idToken != null && idToken.isNotEmpty) {
        await _appAuth.endSession(
          EndSessionRequest(
            idTokenHint: idToken,
            postLogoutRedirectUrl: oidcPostLogoutRedirectUrl,
            issuer: oidcIssuerUrl,
            allowInsecureConnections: oidcAllowInsecureConnections,
          ),
        );
      }
    } on FlutterAppAuthUserCancelledException {
      // Local sign-out must still complete if the browser flow is closed.
    } on FlutterAppAuthPlatformException {
      // Remote logout is best-effort. Local credentials are always removed below.
    } finally {
      await clearLocalSession();
    }
  }

  @override
  Future<void> clearLocalSession() async {
    _tokens = null;
    _refreshInFlight = null;
    await _tokenStore.clear();
  }
}
