class Money {
  const Money({required this.amountMinor, required this.currency});

  final int amountMinor;
  final String currency;

  factory Money.fromAdminJson(Map<String, dynamic> json) => Money(
    amountMinor: json['priceMinor'] as int,
    currency: json['currency'] as String,
  );
}

class MenuItem {
  const MenuItem({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.description,
    required this.price,
    required this.sortOrder,
    required this.active,
    required this.version,
  });

  final String id;
  final String categoryId;
  final String name;
  final String description;
  final Money price;
  final int sortOrder;
  final bool active;
  final int version;

  factory MenuItem.fromAdminJson(Map<String, dynamic> json) => MenuItem(
    id: json['id'] as String,
    categoryId: json['categoryId'] as String,
    name: json['name'] as String,
    description: json['description'] as String,
    price: Money.fromAdminJson(json),
    sortOrder: json['sortOrder'] as int,
    active: json['active'] as bool,
    version: json['version'] as int,
  );
}

class MenuCategory {
  const MenuCategory({
    required this.id,
    required this.slug,
    required this.name,
    required this.sortOrder,
    required this.active,
    required this.version,
    required this.items,
  });

  final String id;
  final String slug;
  final String name;
  final int sortOrder;
  final bool active;
  final int version;
  final List<MenuItem> items;

  factory MenuCategory.fromAdminJson(Map<String, dynamic> json) => MenuCategory(
    id: json['id'] as String,
    slug: json['slug'] as String,
    name: json['name'] as String,
    sortOrder: json['sortOrder'] as int,
    active: json['active'] as bool,
    version: json['version'] as int,
    items: (json['items'] as List<dynamic>)
        .map((item) => MenuItem.fromAdminJson(item as Map<String, dynamic>))
        .toList(growable: false),
  );
}

class CatalogMutationException implements Exception {
  const CatalogMutationException({
    required this.message,
    this.statusCode,
    this.problemType,
  });

  final String message;
  final int? statusCode;
  final String? problemType;

  bool get isConflict => statusCode == 409;

  @override
  String toString() => message;
}
