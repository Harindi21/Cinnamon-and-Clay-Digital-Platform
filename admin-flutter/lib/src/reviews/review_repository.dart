import 'package:cinnamon_clay_admin/src/core/api_client.dart';
import 'package:cinnamon_clay_admin/src/reviews/review_models.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  return ReviewRepository(ref.watch(adminApiClientProvider));
});

final reviewsProvider = FutureProvider<List<AdminReview>>((ref) async {
  return ref.watch(reviewRepositoryProvider).fetchReviews();
});

class ReviewRepository {
  ReviewRepository(this._dio);

  final Dio _dio;

  Future<List<AdminReview>> fetchReviews() async {
    return _guard(() async {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/v1/admin/reviews',
      );
      final data = response.data;
      if (data == null) {
        throw const ReviewMutationException(
          message: 'Review API returned no response body.',
        );
      }

      return (data['reviews'] as List<dynamic>)
          .map((review) => AdminReview.fromJson(review as Map<String, dynamic>))
          .toList(growable: false);
    });
  }

  Future<AdminReview> create({
    required String authorName,
    required String body,
    required int rating,
    required ReviewStatus status,
    required int sortOrder,
  }) async {
    return _guard(() async {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/v1/admin/reviews',
        data: <String, dynamic>{
          'authorName': authorName,
          'body': body,
          'rating': rating,
          'status': status.apiValue,
          'sortOrder': sortOrder,
        },
      );
      return AdminReview.fromJson(_requireBody(response));
    });
  }

  Future<AdminReview> update(AdminReview review) async {
    return _guard(() async {
      final response = await _dio.put<Map<String, dynamic>>(
        '/api/v1/admin/reviews/${review.id}',
        data: <String, dynamic>{
          'authorName': review.authorName,
          'body': review.body,
          'rating': review.rating,
          'status': review.status.apiValue,
          'sortOrder': review.sortOrder,
          'version': review.version,
        },
      );
      return AdminReview.fromJson(_requireBody(response));
    });
  }

  Future<void> hide(AdminReview review) async {
    await _guard(() async {
      await _dio.delete<void>(
        '/api/v1/admin/reviews/${review.id}',
        queryParameters: <String, dynamic>{'version': review.version},
      );
    });
  }

  Map<String, dynamic> _requireBody(Response<Map<String, dynamic>> response) {
    final data = response.data;
    if (data == null) {
      throw const ReviewMutationException(
        message: 'Review API returned no response body.',
      );
    }
    return data;
  }

  Future<T> _guard<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } on ReviewMutationException {
      rethrow;
    } on DioException catch (error) {
      final data = error.response?.data;
      String? detail;
      if (data is Map<String, dynamic>) {
        detail = data['detail'] as String?;
      }
      throw ReviewMutationException(
        message: detail ?? 'The review change could not be completed.',
        statusCode: error.response?.statusCode,
      );
    }
  }
}
