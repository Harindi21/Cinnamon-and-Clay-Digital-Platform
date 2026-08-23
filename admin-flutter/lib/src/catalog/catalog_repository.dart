import 'package:cinnamon_clay_admin/src/catalog/catalog_models.dart';
import 'package:cinnamon_clay_admin/src/core/api_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final catalogRepositoryProvider = Provider<CatalogRepository>((ref) {
  return CatalogRepository(ref.watch(adminApiClientProvider));
});

final catalogProvider = FutureProvider<List<MenuCategory>>((ref) async {
  return ref.watch(catalogRepositoryProvider).fetchMenu();
});

class CatalogRepository {
  CatalogRepository(this._dio);

  final Dio _dio;

  Future<List<MenuCategory>> fetchMenu() async {
    return _guard(() async {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/v1/admin/catalog',
      );
      final data = response.data;
      if (data == null) {
        throw const CatalogMutationException(
          message: 'Catalog API returned no response body.',
        );
      }

      return (data['categories'] as List<dynamic>)
          .map(
            (category) =>
                MenuCategory.fromAdminJson(category as Map<String, dynamic>),
          )
          .toList(growable: false);
    });
  }

  Future<MenuCategory> createCategory({
    required String slug,
    required String name,
    required int sortOrder,
    required bool active,
  }) async {
    return _guard(() async {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/v1/admin/catalog/categories',
        data: <String, dynamic>{
          'slug': slug,
          'name': name,
          'sortOrder': sortOrder,
          'active': active,
        },
      );
      return MenuCategory.fromAdminJson(_requireBody(response));
    });
  }

  Future<MenuCategory> updateCategory(MenuCategory category) async {
    return _guard(() async {
      final response = await _dio.put<Map<String, dynamic>>(
        '/api/v1/admin/catalog/categories/${category.id}',
        data: <String, dynamic>{
          'slug': category.slug,
          'name': category.name,
          'sortOrder': category.sortOrder,
          'active': category.active,
          'version': category.version,
        },
      );
      return MenuCategory.fromAdminJson(_requireBody(response));
    });
  }

  Future<void> deactivateCategory(MenuCategory category) async {
    await _guard(() async {
      await _dio.delete<void>(
        '/api/v1/admin/catalog/categories/${category.id}',
        queryParameters: <String, dynamic>{'version': category.version},
      );
    });
  }

  Future<MenuItem> createItem({
    required String categoryId,
    required String name,
    required String description,
    required int priceMinor,
    required String currency,
    required int sortOrder,
    required bool active,
  }) async {
    return _guard(() async {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/v1/admin/catalog/categories/$categoryId/items',
        data: <String, dynamic>{
          'name': name,
          'description': description,
          'priceMinor': priceMinor,
          'currency': currency,
          'sortOrder': sortOrder,
          'active': active,
        },
      );
      return MenuItem.fromAdminJson(_requireBody(response));
    });
  }

  Future<MenuItem> updateItem(MenuItem item) async {
    return _guard(() async {
      final response = await _dio.put<Map<String, dynamic>>(
        '/api/v1/admin/catalog/items/${item.id}',
        data: <String, dynamic>{
          'categoryId': item.categoryId,
          'name': item.name,
          'description': item.description,
          'priceMinor': item.price.amountMinor,
          'currency': item.price.currency,
          'sortOrder': item.sortOrder,
          'active': item.active,
          'version': item.version,
        },
      );
      return MenuItem.fromAdminJson(_requireBody(response));
    });
  }

  Future<void> deactivateItem(MenuItem item) async {
    await _guard(() async {
      await _dio.delete<void>(
        '/api/v1/admin/catalog/items/${item.id}',
        queryParameters: <String, dynamic>{'version': item.version},
      );
    });
  }

  Map<String, dynamic> _requireBody(Response<Map<String, dynamic>> response) {
    final data = response.data;
    if (data == null) {
      throw const CatalogMutationException(
        message: 'Catalog API returned no response body.',
      );
    }
    return data;
  }

  Future<T> _guard<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } on CatalogMutationException {
      rethrow;
    } on DioException catch (error) {
      final data = error.response?.data;
      String? detail;
      String? type;

      if (data is Map<String, dynamic>) {
        detail = data['detail'] as String?;
        type = data['type'] as String?;
      }

      throw CatalogMutationException(
        message: detail ?? 'The catalog change could not be completed.',
        statusCode: error.response?.statusCode,
        problemType: type,
      );
    }
  }
}
