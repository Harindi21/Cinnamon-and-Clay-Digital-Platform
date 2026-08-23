import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cinnamon_clay_admin/src/catalog/catalog_repository.dart';

class CatalogPage extends ConsumerWidget {
  const CatalogPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(catalogProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Catalog')),
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
