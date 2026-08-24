import 'package:cinnamon_clay_admin/src/audit/audit_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AuditPageResult parses actor and state metadata', () {
    final page = AuditPageResult.fromJson(<String, dynamic>{
      'items': <Map<String, dynamic>>[
        <String, dynamic>{
          'id': '10000000-0000-0000-0000-000000000001',
          'occurredAt': '2026-08-24T00:00:00Z',
          'actorSubject': 'subject-1',
          'actorUsername': 'local.admin',
          'actorRoles': <String>['admin'],
          'action': 'UPDATE',
          'resourceType': 'content.site',
          'resourceId': '30000000-0000-0000-0000-000000000001',
          'requestId': 'admin-request-1234',
          'traceId': 'abc123',
          'beforeState': <String, dynamic>{'brandName': 'Before'},
          'afterState': <String, dynamic>{'brandName': 'After'},
          'metadata': <String, dynamic>{'reason': 'test'},
        },
      ],
      'nextCursor': 'cursor-value',
    });

    expect(page.items, hasLength(1));
    expect(page.nextCursor, 'cursor-value');
    expect(page.items.single.actorUsername, 'local.admin');
    expect(page.items.single.actorRoles, <String>['admin']);
    expect(page.items.single.action, 'UPDATE');
    expect(
      page.items.single.pretty(page.items.single.afterState),
      contains('After'),
    );
  });
}
