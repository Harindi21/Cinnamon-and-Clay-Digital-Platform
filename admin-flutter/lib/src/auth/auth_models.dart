class AdminIdentity {
  const AdminIdentity({
    required this.subject,
    required this.username,
    required this.email,
    required this.roles,
  });

  factory AdminIdentity.fromJson(Map<String, dynamic> json) {
    final roles = (json['roles'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<String>()
        .toList(growable: false);

    return AdminIdentity(
      subject: json['subject'] as String? ?? '',
      username: json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
      roles: roles,
    );
  }

  final String subject;
  final String username;
  final String email;
  final List<String> roles;

  bool hasRole(String role) => roles.contains(role);
}

class AuthState {
  const AuthState._({this.identity});

  const AuthState.signedOut() : this._();

  const AuthState.authenticated(AdminIdentity identity)
    : this._(identity: identity);

  final AdminIdentity? identity;

  bool get isAuthenticated => identity != null;
}

class AuthTokens {
  const AuthTokens({
    required this.accessToken,
    required this.expiresAt,
    this.refreshToken,
    this.idToken,
  });

  factory AuthTokens.fromJson(Map<String, dynamic> json) {
    return AuthTokens(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String?,
      idToken: json['idToken'] as String?,
      expiresAt: DateTime.parse(json['expiresAt'] as String).toUtc(),
    );
  }

  final String accessToken;
  final String? refreshToken;
  final String? idToken;
  final DateTime expiresAt;

  bool isExpiringWithin(Duration window) {
    return expiresAt.isBefore(DateTime.now().toUtc().add(window));
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'idToken': idToken,
      'expiresAt': expiresAt.toUtc().toIso8601String(),
    };
  }
}

class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AuthRequiredException extends AuthException {
  const AuthRequiredException()
    : super('Your administrator session has expired. Please sign in again.');
}

class AuthCancelledException extends AuthException {
  const AuthCancelledException() : super('Sign-in was cancelled.');
}
