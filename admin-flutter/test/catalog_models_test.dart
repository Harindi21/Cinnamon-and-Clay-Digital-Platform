import 'package:cinnamon_clay_admin/src/catalog/catalog_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses versioned administrator catalog records', () {
    final category = MenuCategory.fromAdminJson(<String, dynamic>{
      'id': 'category-1',
      'slug': 'coffee',
      'name': 'Coffee',
      'sortOrder': 10,
      'active': true,
      'version': 3,
      'items': <Map<String, dynamic>>[
        <String, dynamic>{
          'id': 'item-1',
          'categoryId': 'category-1',
          'name': 'Espresso',
          'description': 'Double shot',
          'priceMinor': 55000,
          'currency': 'LKR',
          'sortOrder': 10,
          'active': false,
          'version': 7,
        },
      ],
    });

    expect(category.slug, 'coffee');
    expect(category.version, 3);
    expect(category.items.single.price.amountMinor, 55000);
    expect(category.items.single.active, isFalse);
    expect(category.items.single.version, 7);
  });

  test('catalog conflict exposes retry signal', () {
    const error = CatalogMutationException(
      message: 'Changed elsewhere',
      statusCode: 409,
      problemType: 'urn:cinnamon-clay:problem:conflict',
    );

    expect(error.isConflict, isTrue);
    expect(error.toString(), 'Changed elsewhere');
  });
}
