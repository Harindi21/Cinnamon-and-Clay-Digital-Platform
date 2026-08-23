import 'package:cinnamon_clay_admin/src/auth/auth_controller.dart';
import 'package:cinnamon_clay_admin/src/auth/auth_models.dart';
import 'package:cinnamon_clay_admin/src/catalog/catalog_models.dart';
import 'package:cinnamon_clay_admin/src/catalog/catalog_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CatalogPage extends ConsumerStatefulWidget {
  const CatalogPage({required this.identity, super.key});

  final AdminIdentity identity;

  @override
  ConsumerState<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends ConsumerState<CatalogPage> {
  bool _mutating = false;

  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(catalogProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Catalog'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Refresh catalog',
            onPressed: _mutating ? null : () => ref.invalidate(catalogProvider),
            icon: const Icon(Icons.refresh),
          ),
          _AccountMenu(identity: widget.identity),
        ],
        bottom: _mutating
            ? const PreferredSize(
                preferredSize: Size.fromHeight(3),
                child: LinearProgressIndicator(minHeight: 3),
              )
            : null,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _mutating ? null : () => _createCategory(context),
        icon: const Icon(Icons.add),
        label: const Text('Category'),
      ),
      body: catalog.when(
        data: (categories) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(catalogProvider);
            await ref.read(catalogProvider.future);
          },
          child: categories.isEmpty
              ? const _EmptyCatalog()
              : ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                  itemCount: categories.length,
                  itemBuilder: (context, index) => _CategoryCard(
                    category: categories[index],
                    disabled: _mutating,
                    onEdit: () => _editCategory(context, categories[index]),
                    onAddItem: () =>
                        _createItem(context, categories, categories[index]),
                    onDeactivate: () =>
                        _deactivateCategory(context, categories[index]),
                    onEditItem: (item) => _editItem(context, categories, item),
                    onDeactivateItem: (item) => _deactivateItem(context, item),
                  ),
                ),
        ),
        error: (error, stackTrace) => _CatalogError(
          error: error,
          onRetry: () => ref.invalidate(catalogProvider),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Future<void> _createCategory(BuildContext context) async {
    final draft = await showDialog<_CategoryDraft>(
      context: context,
      builder: (context) => const _CategoryEditorDialog(),
    );
    if (draft == null || !mounted) {
      return;
    }

    await _runMutation(
      successMessage: 'Category created.',
      operation: () => ref
          .read(catalogRepositoryProvider)
          .createCategory(
            slug: draft.slug,
            name: draft.name,
            sortOrder: draft.sortOrder,
            active: draft.active,
          ),
    );
  }

  Future<void> _editCategory(
    BuildContext context,
    MenuCategory category,
  ) async {
    final draft = await showDialog<_CategoryDraft>(
      context: context,
      builder: (context) => _CategoryEditorDialog(category: category),
    );
    if (draft == null || !mounted) {
      return;
    }

    final updated = MenuCategory(
      id: category.id,
      slug: draft.slug,
      name: draft.name,
      sortOrder: draft.sortOrder,
      active: draft.active,
      version: category.version,
      items: category.items,
    );

    await _runMutation(
      successMessage: 'Category updated.',
      operation: () =>
          ref.read(catalogRepositoryProvider).updateCategory(updated),
    );
  }

  Future<void> _deactivateCategory(
    BuildContext context,
    MenuCategory category,
  ) async {
    if (!category.active) {
      return;
    }

    final confirmed = await _confirm(
      context,
      title: 'Hide ${category.name}?',
      message:
          'The category and its items will stop appearing on the public menu. '
          'You can reactivate the category later by editing it.',
    );
    if (!confirmed || !mounted) {
      return;
    }

    await _runMutation(
      successMessage: 'Category hidden from the public menu.',
      operation: () =>
          ref.read(catalogRepositoryProvider).deactivateCategory(category),
    );
  }

  Future<void> _createItem(
    BuildContext context,
    List<MenuCategory> categories,
    MenuCategory category,
  ) async {
    final draft = await showDialog<_ItemDraft>(
      context: context,
      builder: (context) => _ItemEditorDialog(
        categories: categories,
        initialCategoryId: category.id,
      ),
    );
    if (draft == null || !mounted) {
      return;
    }

    await _runMutation(
      successMessage: 'Menu item created.',
      operation: () => ref
          .read(catalogRepositoryProvider)
          .createItem(
            categoryId: draft.categoryId,
            name: draft.name,
            description: draft.description,
            priceMinor: draft.priceMinor,
            currency: draft.currency,
            sortOrder: draft.sortOrder,
            active: draft.active,
          ),
    );
  }

  Future<void> _editItem(
    BuildContext context,
    List<MenuCategory> categories,
    MenuItem item,
  ) async {
    final draft = await showDialog<_ItemDraft>(
      context: context,
      builder: (context) => _ItemEditorDialog(
        categories: categories,
        item: item,
        initialCategoryId: item.categoryId,
      ),
    );
    if (draft == null || !mounted) {
      return;
    }

    final updated = MenuItem(
      id: item.id,
      categoryId: draft.categoryId,
      name: draft.name,
      description: draft.description,
      price: Money(amountMinor: draft.priceMinor, currency: draft.currency),
      sortOrder: draft.sortOrder,
      active: draft.active,
      version: item.version,
    );

    await _runMutation(
      successMessage: 'Menu item updated.',
      operation: () => ref.read(catalogRepositoryProvider).updateItem(updated),
    );
  }

  Future<void> _deactivateItem(BuildContext context, MenuItem item) async {
    if (!item.active) {
      return;
    }

    final confirmed = await _confirm(
      context,
      title: 'Hide ${item.name}?',
      message:
          'This item will stop appearing on the public menu. '
          'You can reactivate it later by editing it.',
    );
    if (!confirmed || !mounted) {
      return;
    }

    await _runMutation(
      successMessage: 'Menu item hidden from the public menu.',
      operation: () => ref.read(catalogRepositoryProvider).deactivateItem(item),
    );
  }

  Future<void> _runMutation({
    required String successMessage,
    required Future<Object?> Function() operation,
  }) async {
    setState(() => _mutating = true);

    try {
      await operation();
      ref.invalidate(catalogProvider);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(successMessage)));
    } on CatalogMutationException catch (error) {
      ref.invalidate(catalogProvider);
      if (!mounted) {
        return;
      }
      final message = error.isConflict
          ? '${error.message} The catalog has been refreshed.'
          : error.message;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) {
        setState(() => _mutating = false);
      }
    }
  }

  Future<bool> _confirm(
    BuildContext context, {
    required String title,
    required String message,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Hide'),
              ),
            ],
          ),
        ) ??
        false;
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.category,
    required this.disabled,
    required this.onEdit,
    required this.onAddItem,
    required this.onDeactivate,
    required this.onEditItem,
    required this.onDeactivateItem,
  });

  final MenuCategory category;
  final bool disabled;
  final VoidCallback onEdit;
  final VoidCallback onAddItem;
  final VoidCallback onDeactivate;
  final ValueChanged<MenuItem> onEditItem;
  final ValueChanged<MenuItem> onDeactivateItem;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: <Widget>[
          ListTile(
            title: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    category.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                _StateChip(active: category.active),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '${category.slug} • order ${category.sortOrder} • v${category.version}',
              ),
            ),
            trailing: PopupMenuButton<_CategoryAction>(
              enabled: !disabled,
              onSelected: (action) {
                switch (action) {
                  case _CategoryAction.addItem:
                    onAddItem();
                  case _CategoryAction.edit:
                    onEdit();
                  case _CategoryAction.deactivate:
                    onDeactivate();
                }
              },
              itemBuilder: (context) => <PopupMenuEntry<_CategoryAction>>[
                const PopupMenuItem<_CategoryAction>(
                  value: _CategoryAction.addItem,
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.add),
                    title: Text('Add item'),
                  ),
                ),
                const PopupMenuItem<_CategoryAction>(
                  value: _CategoryAction.edit,
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.edit_outlined),
                    title: Text('Edit category'),
                  ),
                ),
                if (category.active)
                  const PopupMenuItem<_CategoryAction>(
                    value: _CategoryAction.deactivate,
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.visibility_off_outlined),
                      title: Text('Hide category'),
                    ),
                  ),
              ],
            ),
          ),
          if (category.items.isEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 4, 16, 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('No menu items yet.'),
              ),
            )
          else
            ...category.items.map(
              (item) => Column(
                children: <Widget>[
                  const Divider(height: 1),
                  ListTile(
                    title: Row(
                      children: <Widget>[
                        Expanded(child: Text(item.name)),
                        _StateChip(active: item.active, compact: true),
                      ],
                    ),
                    subtitle: Text(
                      '${item.description}\n'
                      '${_formatMoney(item.price)} • order ${item.sortOrder} • v${item.version}',
                    ),
                    isThreeLine: true,
                    trailing: PopupMenuButton<_ItemAction>(
                      enabled: !disabled,
                      onSelected: (action) {
                        switch (action) {
                          case _ItemAction.edit:
                            onEditItem(item);
                          case _ItemAction.deactivate:
                            onDeactivateItem(item);
                        }
                      },
                      itemBuilder: (context) => <PopupMenuEntry<_ItemAction>>[
                        const PopupMenuItem<_ItemAction>(
                          value: _ItemAction.edit,
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(Icons.edit_outlined),
                            title: Text('Edit item'),
                          ),
                        ),
                        if (item.active)
                          const PopupMenuItem<_ItemAction>(
                            value: _ItemAction.deactivate,
                            child: ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(Icons.visibility_off_outlined),
                              title: Text('Hide item'),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _StateChip extends StatelessWidget {
  const _StateChip({required this.active, this.compact = false});

  final bool active;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Chip(
      visualDensity: compact ? VisualDensity.compact : null,
      avatar: Icon(
        active ? Icons.visibility_outlined : Icons.visibility_off_outlined,
        size: 16,
      ),
      label: Text(active ? 'Public' : 'Hidden'),
    );
  }
}

class _CategoryEditorDialog extends StatefulWidget {
  const _CategoryEditorDialog({this.category});

  final MenuCategory? category;

  @override
  State<_CategoryEditorDialog> createState() => _CategoryEditorDialogState();
}

class _CategoryEditorDialogState extends State<_CategoryEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _slugController;
  late final TextEditingController _sortController;
  late bool _active;

  bool get _editing => widget.category != null;

  @override
  void initState() {
    super.initState();
    final category = widget.category;
    _nameController = TextEditingController(text: category?.name ?? '');
    _slugController = TextEditingController(text: category?.slug ?? '');
    _sortController = TextEditingController(
      text: (category?.sortOrder ?? 10).toString(),
    );
    _active = category?.active ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _slugController.dispose();
    _sortController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_editing ? 'Edit category' : 'New category'),
      content: SizedBox(
        width: 460,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextFormField(
                  controller: _nameController,
                  autofocus: true,
                  decoration: const InputDecoration(labelText: 'Name'),
                  textInputAction: TextInputAction.next,
                  validator: (value) =>
                      _required(value, 'Enter a category name.'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _slugController,
                  decoration: InputDecoration(
                    labelText: 'Slug',
                    helperText:
                        'Lowercase URL-style identifier, for example coffee',
                    suffixIcon: IconButton(
                      tooltip: 'Generate from name',
                      onPressed: () {
                        _slugController.text = _slugify(_nameController.text);
                      },
                      icon: const Icon(Icons.auto_fix_high_outlined),
                    ),
                  ),
                  validator: (value) {
                    final required = _required(value, 'Enter a slug.');
                    if (required != null) {
                      return required;
                    }
                    if (!RegExp(
                      r'^[a-z0-9]+(?:-[a-z0-9]+)*$',
                    ).hasMatch(value!)) {
                      return 'Use lowercase letters, numbers and single hyphens only.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _sortController,
                  decoration: const InputDecoration(labelText: 'Display order'),
                  keyboardType: TextInputType.number,
                  validator: _nonNegativeInteger,
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Visible on public menu'),
                  value: _active,
                  onChanged: (value) => setState(() => _active = value),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(_editing ? 'Save' : 'Create'),
        ),
      ],
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    Navigator.of(context).pop(
      _CategoryDraft(
        slug: _slugController.text.trim(),
        name: _nameController.text.trim(),
        sortOrder: int.parse(_sortController.text.trim()),
        active: _active,
      ),
    );
  }
}

class _ItemEditorDialog extends StatefulWidget {
  const _ItemEditorDialog({
    required this.categories,
    required this.initialCategoryId,
    this.item,
  });

  final List<MenuCategory> categories;
  final String initialCategoryId;
  final MenuItem? item;

  @override
  State<_ItemEditorDialog> createState() => _ItemEditorDialogState();
}

class _ItemEditorDialogState extends State<_ItemEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;
  late final TextEditingController _currencyController;
  late final TextEditingController _sortController;
  late String _categoryId;
  late bool _active;

  bool get _editing => widget.item != null;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _nameController = TextEditingController(text: item?.name ?? '');
    _descriptionController = TextEditingController(
      text: item?.description ?? '',
    );
    _priceController = TextEditingController(
      text: item == null ? '' : _minorUnitsToInput(item.price.amountMinor),
    );
    _currencyController = TextEditingController(
      text: item?.price.currency ?? 'LKR',
    );
    _sortController = TextEditingController(
      text: (item?.sortOrder ?? 10).toString(),
    );
    _categoryId = item?.categoryId ?? widget.initialCategoryId;
    _active = item?.active ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _currencyController.dispose();
    _sortController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_editing ? 'Edit menu item' : 'New menu item'),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                DropdownButtonFormField<String>(
                  initialValue: _categoryId,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: widget.categories
                      .map(
                        (category) => DropdownMenuItem<String>(
                          value: category.id,
                          child: Text(category.name),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _categoryId = value);
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nameController,
                  autofocus: true,
                  decoration: const InputDecoration(labelText: 'Name'),
                  textInputAction: TextInputAction.next,
                  validator: (value) => _required(value, 'Enter an item name.'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _priceController,
                        decoration: const InputDecoration(
                          labelText: 'Price',
                          hintText: '550.00',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (value) => _parseMinorUnits(value) == null
                            ? 'Enter a valid amount with up to 2 decimals.'
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _currencyController,
                        decoration: const InputDecoration(
                          labelText: 'Currency',
                        ),
                        textCapitalization: TextCapitalization.characters,
                        validator: (value) {
                          final normalized = value?.trim().toUpperCase() ?? '';
                          if (!RegExp(r'^[A-Z]{3}$').hasMatch(normalized)) {
                            return 'Use 3 letters.';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _sortController,
                  decoration: const InputDecoration(labelText: 'Display order'),
                  keyboardType: TextInputType.number,
                  validator: _nonNegativeInteger,
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Visible on public menu'),
                  value: _active,
                  onChanged: (value) => setState(() => _active = value),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(_editing ? 'Save' : 'Create'),
        ),
      ],
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final priceMinor = _parseMinorUnits(_priceController.text)!;
    Navigator.of(context).pop(
      _ItemDraft(
        categoryId: _categoryId,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        priceMinor: priceMinor,
        currency: _currencyController.text.trim().toUpperCase(),
        sortOrder: int.parse(_sortController.text.trim()),
        active: _active,
      ),
    );
  }
}

class _CatalogError extends StatelessWidget {
  const _CatalogError({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final message = error is CatalogMutationException
        ? (error as CatalogMutationException).message
        : 'Could not load the administrator catalog.';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.cloud_off_outlined, size: 42),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _EmptyCatalog extends StatelessWidget {
  const _EmptyCatalog();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(32),
      children: const <Widget>[
        SizedBox(height: 120),
        Icon(Icons.restaurant_menu_outlined, size: 52),
        SizedBox(height: 16),
        Text(
          'No menu categories yet. Use the Category button to create one.',
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _AccountMenu extends ConsumerWidget {
  const _AccountMenu({required this.identity});

  final AdminIdentity identity;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<_AccountAction>(
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
    );
  }
}

class _CategoryDraft {
  const _CategoryDraft({
    required this.slug,
    required this.name,
    required this.sortOrder,
    required this.active,
  });

  final String slug;
  final String name;
  final int sortOrder;
  final bool active;
}

class _ItemDraft {
  const _ItemDraft({
    required this.categoryId,
    required this.name,
    required this.description,
    required this.priceMinor,
    required this.currency,
    required this.sortOrder,
    required this.active,
  });

  final String categoryId;
  final String name;
  final String description;
  final int priceMinor;
  final String currency;
  final int sortOrder;
  final bool active;
}

enum _CategoryAction { addItem, edit, deactivate }

enum _ItemAction { edit, deactivate }

enum _AccountAction { signOut }

String? _required(String? value, String message) {
  return value == null || value.trim().isEmpty ? message : null;
}

String? _nonNegativeInteger(String? value) {
  final parsed = int.tryParse(value?.trim() ?? '');
  if (parsed == null || parsed < 0) {
    return 'Enter 0 or a positive whole number.';
  }
  return null;
}

String _slugify(String value) {
  return value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
}

int? _parseMinorUnits(String? value) {
  final normalized = value?.trim().replaceAll(',', '') ?? '';
  final match = RegExp(r'^(\d+)(?:\.(\d{1,2}))?$').firstMatch(normalized);
  if (match == null) {
    return null;
  }

  final whole = int.parse(match.group(1)!);
  final fraction = (match.group(2) ?? '').padRight(2, '0');
  return (whole * 100) + (fraction.isEmpty ? 0 : int.parse(fraction));
}

String _minorUnitsToInput(int amountMinor) {
  final whole = amountMinor ~/ 100;
  final fraction = (amountMinor % 100).toString().padLeft(2, '0');
  return '$whole.$fraction';
}

String _formatMoney(Money money) {
  return '${money.currency} ${_minorUnitsToInput(money.amountMinor)}';
}
