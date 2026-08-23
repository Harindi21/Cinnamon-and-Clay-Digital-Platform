import 'package:cinnamon_clay_admin/src/catalog/catalog_models.dart';
import 'package:cinnamon_clay_admin/src/core/api_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final catalogRepositoryProvider = Provider<CatalogRepository>((ref) {
  return CatalogRepository(ref.watch(apiClientProvider));
});

final catalogProvider = FutureProvider<List<MenuCategory>>((ref) async {
  return ref.watch(catalogRepositoryProvider).fetchMenu();
});

class CatalogRepository {
  CatalogRepository(this._dio);

  final Dio _dio;

  Future<List<MenuCategory>> fetchMenu() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/catalog/menu',
    );
    final data = response.data;
    if (data == null) {
      throw StateError('Catalog API returned no body');
    }

    return (data['categories'] as List<dynamic>)
        .map(
          (category) => MenuCategory.fromJson(category as Map<String, dynamic>),
        )
        .toList(growable: false);
  }
}
