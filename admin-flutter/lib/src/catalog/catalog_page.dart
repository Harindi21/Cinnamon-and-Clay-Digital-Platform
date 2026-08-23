import 'package:cinnamon_clay_admin/src/auth/auth_controller.dart';
import 'package:cinnamon_clay_admin/src/auth/auth_models.dart';
import 'package:cinnamon_clay_admin/src/catalog/catalog_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CatalogPage extends ConsumerWidget {
  const CatalogPage({required this.identity, super.key});

  final AdminIdentity identity;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(catalogProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Catalog'),
        actions: <Widget>[
          PopupMenuButton<_AccountAction>(
            tooltip: 'Administrator account',
            onSelected: (action) {
              if (action == _AccountAction.signOut) {
                ref.read(authControllerProvider.notifier).signOut();
              }
            },
            itemBuilder: (context) => <PopupMenuEntry<_AccountAction>>[
              PopupMenuItem<_AccountAction>(
                enabled: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      identity.username,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    if (identity.email.isNotEmpty)
                      Text(
                        identity.email,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    const SizedBox(height: 6),
                    Text(
                      identity.roles.isEmpty
                          ? 'No application role'
                          : identity.roles.join(', '),
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem<_AccountAction>(
                value: _AccountAction.signOut,
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.logout),
                  title: Text('Sign out'),
                ),
              ),
            ],
            icon: const Icon(Icons.account_circle_outlined),
          ),
        ],
      ),
      body: catalog.when(
        data: (categories) => ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: ExpansionTile(
                title: Text(category.name),
                children: category.items
                    .map(
                      (item) => ListTile(
                        title: Text(item.name),
                        subtitle: Text(item.description),
                        trailing: Text(
                          '${item.price.currency} ${(item.price.amountMinor / 100).toStringAsFixed(0)}',
                        ),
                      ),
                    )
                    .toList(growable: false),
              ),
            );
          },
        ),
        error: (error, stackTrace) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Text('Could not load catalog.'),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => ref.invalidate(catalogProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

enum _AccountAction { signOut }
