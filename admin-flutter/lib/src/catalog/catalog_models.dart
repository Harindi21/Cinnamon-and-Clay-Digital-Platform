class Money {
  const Money({required this.amountMinor, required this.currency});

  final int amountMinor;
  final String currency;

  factory Money.fromJson(Map<String, dynamic> json) => Money(
    amountMinor: json['amountMinor'] as int,
    currency: json['currency'] as String,
  );
}

class MenuItem {
  const MenuItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
  });

  final String id;
  final String name;
  final String description;
  final Money price;

  factory MenuItem.fromJson(Map<String, dynamic> json) => MenuItem(
    id: json['id'] as String,
    name: json['name'] as String,
    description: json['description'] as String,
    price: Money.fromJson(json['price'] as Map<String, dynamic>),
  );
}

class MenuCategory {
  const MenuCategory({
    required this.id,
    required this.name,
    required this.items,
  });

  final String id;
  final String name;
  final List<MenuItem> items;

  factory MenuCategory.fromJson(Map<String, dynamic> json) => MenuCategory(
    id: json['id'] as String,
    name: json['name'] as String,
    items: (json['items'] as List<dynamic>)
        .map((item) => MenuItem.fromJson(item as Map<String, dynamic>))
        .toList(growable: false),
  );
}
