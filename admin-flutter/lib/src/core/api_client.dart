import 'dart:math';

import 'package:cinnamon_clay_admin/src/auth/auth_controller.dart';
import 'package:cinnamon_clay_admin/src/core/environment.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final apiClientProvider = Provider<Dio>((ref) {
  return _newApiClient();
});

final adminApiClientProvider = Provider<Dio>((ref) {
  final dio = _newApiClient();

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        try {
          final accessToken = await ref
              .read(authControllerProvider.notifier)
              .accessToken();
          options.headers['Authorization'] = 'Bearer $accessToken';
          handler.next(options);
        } catch (error, stackTrace) {
          handler.reject(
            DioException(
              requestOptions: options,
              type: DioExceptionType.unknown,
              error: error,
              stackTrace: stackTrace,
            ),
          );
        }
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          await ref.read(authControllerProvider.notifier).expireLocalSession();
        }
        handler.next(error);
      },
    ),
  );

  return dio;
});

final Random _secureRandom = Random.secure();

Dio _newApiClient() {
  final dio = Dio(
    BaseOptions(
      baseUrl: apiBaseUrl,
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
      headers: const <String, String>{'Accept': 'application/json'},
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        options.headers['X-Request-Id'] = _newRequestId();
        handler.next(options);
      },
    ),
  );

  return dio;
}

String _newRequestId() {
  final randomPart = List<int>.generate(
    12,
    (_) => _secureRandom.nextInt(256),
    growable: false,
  ).map((value) => value.toRadixString(16).padLeft(2, '0')).join();

  return 'admin-${DateTime.now().microsecondsSinceEpoch}-$randomPart';
}
