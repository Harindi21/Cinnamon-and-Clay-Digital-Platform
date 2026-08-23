import 'dart:convert';

class AuditEvent {
  const AuditEvent({
    required this.id,
    required this.occurredAt,
    required this.actorSubject,
    required this.actorUsername,
    required this.actorRoles,
    required this.action,
    required this.resourceType,
    required this.metadata,
    this.resourceId,
    this.requestId,
    this.traceId,
    this.beforeState,
    this.afterState,
  });

  factory AuditEvent.fromJson(Map<String, dynamic> json) {
    return AuditEvent(
      id: json['id'] as String,
      occurredAt: DateTime.parse(json['occurredAt'] as String).toUtc(),
      actorSubject: json['actorSubject'] as String? ?? '',
      actorUsername: json['actorUsername'] as String? ?? '',
      actorRoles: (json['actorRoles'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<String>()
          .toList(growable: false),
      action: json['action'] as String? ?? '',
      resourceType: json['resourceType'] as String? ?? '',
      resourceId: json['resourceId'] as String?,
      requestId: json['requestId'] as String?,
      traceId: json['traceId'] as String?,
      beforeState: json['beforeState'],
      afterState: json['afterState'],
      metadata: json['metadata'] ?? const <String, dynamic>{},
    );
  }

  final String id;
  final DateTime occurredAt;
  final String actorSubject;
  final String actorUsername;
  final List<String> actorRoles;
  final String action;
  final String resourceType;
  final String? resourceId;
  final String? requestId;
  final String? traceId;
  final Object? beforeState;
  final Object? afterState;
  final Object metadata;

  String pretty(Object? value) {
    if (value == null) {
      return '—';
    }
    return const JsonEncoder.withIndent('  ').convert(value);
  }
}

class AuditPageResult {
  const AuditPageResult({required this.items, this.nextCursor});

  factory AuditPageResult.fromJson(Map<String, dynamic> json) {
    return AuditPageResult(
      items: (json['items'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(AuditEvent.fromJson)
          .toList(growable: false),
      nextCursor: json['nextCursor'] as String?,
    );
  }

  final List<AuditEvent> items;
  final String? nextCursor;
}
