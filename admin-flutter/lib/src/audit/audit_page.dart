import 'package:cinnamon_clay_admin/src/audit/audit_models.dart';
import 'package:cinnamon_clay_admin/src/audit/audit_repository.dart';
import 'package:cinnamon_clay_admin/src/auth/auth_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuditPage extends ConsumerStatefulWidget {
  const AuditPage({required this.identity, super.key});

  final AdminIdentity identity;

  @override
  ConsumerState<AuditPage> createState() => _AuditPageState();
}

class _AuditPageState extends ConsumerState<AuditPage> {
  static const _actions = <String>[
    'CREATE',
    'UPDATE',
    'DEACTIVATE',
    'REACTIVATE',
    'PUBLISH',
    'HIDE',
    'REPLACE',
    'REORDER',
    'CLEANUP',
  ];

  final _actorController = TextEditingController();
  final _resourceController = TextEditingController();
  final _resourceIdController = TextEditingController();
  final _requestIdController = TextEditingController();
  final _traceIdController = TextEditingController();

  List<AuditEvent> _events = const <AuditEvent>[];
  String? _nextCursor;
  String? _action;
  Object? _error;
  bool _loading = true;
  bool _loadingMore = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load(reset: true));
  }

  @override
  void dispose() {
    _actorController.dispose();
    _resourceController.dispose();
    _resourceIdController.dispose();
    _requestIdController.dispose();
    _traceIdController.dispose();
    super.dispose();
  }

  Future<void> _load({required bool reset}) async {
    if (!widget.identity.hasRole('admin')) {
      return;
    }

    setState(() {
      if (reset) {
        _loading = true;
        _error = null;
      } else {
        _loadingMore = true;
      }
    });

    try {
      final page = await ref
          .read(auditRepositoryProvider)
          .find(
            actor: _actorController.text,
            action: _action,
            resourceType: _resourceController.text,
            resourceId: _resourceIdController.text,
            requestId: _requestIdController.text,
            traceId: _traceIdController.text,
            cursor: reset ? null : _nextCursor,
          );

      if (!mounted) {
        return;
      }
      setState(() {
        _events = reset ? page.items : <AuditEvent>[..._events, ...page.items];
        _nextCursor = page.nextCursor;
        _error = null;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _error = error);
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadingMore = false;
        });
      }
    }
  }

  void _clearFilters() {
    _actorController.clear();
    _resourceController.clear();
    _resourceIdController.clear();
    _requestIdController.clear();
    _traceIdController.clear();
    setState(() => _action = null);
    _load(reset: true);
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.identity.hasRole('admin')) {
      return const Scaffold(
        body: Center(child: Text('Administrator access is required.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Audit trail'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loading ? null : () => _load(reset: true),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          _AuditFilters(
            actorController: _actorController,
            resourceController: _resourceController,
            resourceIdController: _resourceIdController,
            requestIdController: _requestIdController,
            traceIdController: _traceIdController,
            action: _action,
            actions: _actions,
            onActionChanged: (value) => setState(() => _action = value),
            onApply: () => _load(reset: true),
            onClear: _clearFilters,
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _events.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(Icons.error_outline, size: 42),
              const SizedBox(height: 12),
              const Text('Unable to load the audit trail.'),
              const SizedBox(height: 8),
              Text(
                '$_error',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => _load(reset: true),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_events.isEmpty) {
      return const Center(child: Text('No audit events match these filters.'));
    }

    return RefreshIndicator(
      onRefresh: () => _load(reset: true),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 28),
        itemCount: _events.length + (_nextCursor == null ? 0 : 1),
        itemBuilder: (context, index) {
          if (index == _events.length) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: OutlinedButton.icon(
                  onPressed: _loadingMore ? null : () => _load(reset: false),
                  icon: _loadingMore
                      ? const SizedBox.square(
                          dimension: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.expand_more),
                  label: const Text('Load more'),
                ),
              ),
            );
          }

          final event = _events[index];
          return Card(
            child: ListTile(
              leading: CircleAvatar(child: Icon(_iconFor(event.action))),
              title: Text('${event.action} · ${event.resourceType}'),
              subtitle: Text(
                '${event.actorUsername} · ${_formatTimestamp(event.occurredAt)}'
                '${event.resourceId == null ? '' : '\n${event.resourceId}'}',
              ),
              isThreeLine: event.resourceId != null,
              trailing: const Icon(Icons.chevron_right),
              onTap: () => showDialog<void>(
                context: context,
                builder: (context) => _AuditDetailDialog(event: event),
              ),
            ),
          );
        },
      ),
    );
  }

  static IconData _iconFor(String action) {
    return switch (action) {
      'CREATE' => Icons.add_circle_outline,
      'DEACTIVATE' || 'HIDE' => Icons.visibility_off_outlined,
      'REACTIVATE' || 'PUBLISH' => Icons.publish_outlined,
      'REPLACE' => Icons.swap_horiz,
      'REORDER' => Icons.reorder,
      'CLEANUP' => Icons.cleaning_services_outlined,
      _ => Icons.edit_outlined,
    };
  }

  static String _formatTimestamp(DateTime value) {
    final local = value.toLocal();
    String two(int number) => number.toString().padLeft(2, '0');
    return '${local.year}-${two(local.month)}-${two(local.day)} '
        '${two(local.hour)}:${two(local.minute)}:${two(local.second)}';
  }
}

class _AuditFilters extends StatelessWidget {
  const _AuditFilters({
    required this.actorController,
    required this.resourceController,
    required this.resourceIdController,
    required this.requestIdController,
    required this.traceIdController,
    required this.action,
    required this.actions,
    required this.onActionChanged,
    required this.onApply,
    required this.onClear,
  });

  final TextEditingController actorController;
  final TextEditingController resourceController;
  final TextEditingController resourceIdController;
  final TextEditingController requestIdController;
  final TextEditingController traceIdController;
  final String? action;
  final List<String> actions;
  final ValueChanged<String?> onActionChanged;
  final VoidCallback onApply;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: ExpansionTile(
        leading: const Icon(Icons.filter_alt_outlined),
        title: const Text('Filters'),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: <Widget>[
          TextField(
            controller: actorController,
            decoration: const InputDecoration(labelText: 'Actor username'),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: action,
            decoration: const InputDecoration(labelText: 'Action'),
            items: actions
                .map(
                  (value) => DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  ),
                )
                .toList(growable: false),
            onChanged: onActionChanged,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: resourceController,
            decoration: const InputDecoration(
              labelText: 'Resource type',
              hintText: 'catalog.item',
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: resourceIdController,
            decoration: const InputDecoration(labelText: 'Resource ID'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: requestIdController,
            decoration: const InputDecoration(labelText: 'Request ID'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: traceIdController,
            decoration: const InputDecoration(labelText: 'Trace ID'),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              TextButton(onPressed: onClear, child: const Text('Clear')),
              const SizedBox(width: 8),
              FilledButton(onPressed: onApply, child: const Text('Apply')),
            ],
          ),
        ],
      ),
    );
  }
}

class _AuditDetailDialog extends StatelessWidget {
  const _AuditDetailDialog({required this.event});

  final AuditEvent event;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('${event.action} · ${event.resourceType}'),
      content: SizedBox(
        width: 720,
        child: SingleChildScrollView(
          child: SelectionArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _DetailRow('Event ID', event.id),
                _DetailRow('Actor', event.actorUsername),
                _DetailRow('Subject', event.actorSubject),
                _DetailRow('Roles', event.actorRoles.join(', ')),
                _DetailRow('Resource ID', event.resourceId ?? '—'),
                _DetailRow('Request ID', event.requestId ?? '—'),
                _DetailRow('Trace ID', event.traceId ?? '—'),
                const Divider(height: 28),
                const Text(
                  'Before',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(event.pretty(event.beforeState)),
                const Divider(height: 28),
                const Text(
                  'After',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(event.pretty(event.afterState)),
                const Divider(height: 28),
                const Text(
                  'Metadata',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(event.pretty(event.metadata)),
              ],
            ),
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text('$label: $value'),
    );
  }
}
