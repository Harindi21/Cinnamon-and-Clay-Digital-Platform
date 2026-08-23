import 'dart:convert';

import 'package:cinnamon_clay_admin/src/auth/auth_models.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract interface class AuthTokenStore {
  Future<AuthTokens?> read();

  Future<void> write(AuthTokens tokens);

  Future<void> clear();
}

class SecureAuthTokenStore implements AuthTokenStore {
  SecureAuthTokenStore(this._storage);

  static const String _sessionKey = 'cinnamon_clay.auth.tokens.v1';

  final FlutterSecureStorage _storage;

  @override
  Future<AuthTokens?> read() async {
    final encoded = await _storage.read(key: _sessionKey);
    if (encoded == null || encoded.isEmpty) {
      return null;
    }

    try {
      return AuthTokens.fromJson(jsonDecode(encoded) as Map<String, dynamic>);
    } on FormatException {
      await clear();
      return null;
    } on TypeError {
      await clear();
      return null;
    }
  }

  @override
  Future<void> write(AuthTokens tokens) {
    return _storage.write(key: _sessionKey, value: jsonEncode(tokens.toJson()));
  }

  @override
  Future<void> clear() {
    return _storage.delete(key: _sessionKey);
  }
}
