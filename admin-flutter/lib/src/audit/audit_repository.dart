import 'package:cinnamon_clay_admin/src/audit/audit_models.dart';
import 'package:cinnamon_clay_admin/src/core/api_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final auditRepositoryProvider = Provider<AuditRepository>((ref) {
  return AuditRepository(ref.watch(adminApiClientProvider));
});

class AuditRepository {
  const AuditRepository(this._dio);

  final Dio _dio;

  Future<AuditPageResult> find({
    String? actor,
    String? action,
    String? resourceType,
    String? resourceId,
    String? requestId,
    String? traceId,
    String? cursor,
    int limit = 50,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/admin/audit',
      queryParameters: <String, dynamic>{
        if (actor != null && actor.trim().isNotEmpty) 'actor': actor.trim(),
        if (action != null && action.trim().isNotEmpty) 'action': action.trim(),
        if (resourceType != null && resourceType.trim().isNotEmpty)
          'resourceType': resourceType.trim(),
        if (resourceId != null && resourceId.trim().isNotEmpty)
          'resourceId': resourceId.trim(),
        if (requestId != null && requestId.trim().isNotEmpty)
          'requestId': requestId.trim(),
        if (traceId != null && traceId.trim().isNotEmpty)
          'traceId': traceId.trim(),
        if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
        'limit': limit,
      },
    );

    return AuditPageResult.fromJson(response.data ?? const <String, dynamic>{});
  }
}
