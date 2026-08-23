import 'dart:typed_data';

import 'package:cinnamon_clay_admin/src/core/api_client.dart';
import 'package:cinnamon_clay_admin/src/media/media_models.dart';
import 'package:dio/dio.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final mediaRepositoryProvider = Provider<MediaRepository>((ref) {
  return MediaRepository(ref.watch(adminApiClientProvider));
});

final mediaProvider = FutureProvider<MediaSnapshot>((ref) async {
  return ref.watch(mediaRepositoryProvider).fetch();
});

final mediaContentProvider = FutureProvider.family<Uint8List, ({String id, int version})>((ref, key) async {
  return ref.watch(mediaRepositoryProvider).fetchContent(key.id);
});

class MediaRepository {
  MediaRepository(this._dio);

  final Dio _dio;

  Future<MediaSnapshot> fetch() async {
    return _guard(() async {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/v1/admin/media',
      );
      final body = _requireBody(response);
      final assets = (body['assets'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(AdminMediaAsset.fromJson)
          .toList(growable: false);
      return MediaSnapshot(assets);
    });
  }

  Future<Uint8List> fetchContent(String id) async {
    return _guard(() async {
      final response = await _dio.get<List<int>>(
        '/api/v1/admin/media/$id/content',
        options: Options(responseType: ResponseType.bytes),
      );
      final bytes = response.data;
      if (bytes == null) {
        throw const MediaMutationException(
          message: 'Media API returned no image content.',
        );
      }
      return Uint8List.fromList(bytes);
    });
  }

  Future<AdminMediaAsset> upload({
    required XFile file,
    required MediaDraft draft,
    ProgressCallback? onSendProgress,
  }) async {
    return _guard(() async {
      final bytes = await file.readAsBytes();
      final formData = FormData.fromMap(<String, dynamic>{
        'file': MultipartFile.fromBytes(bytes, filename: file.name),
        'purpose': draft.purpose.apiValue,
        'altText': draft.altText,
        'sortOrder': draft.sortOrder.toString(),
        'active': draft.active.toString(),
      });
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/v1/admin/media',
        data: formData,
        options: Options(contentType: Headers.multipartFormDataContentType),
        onSendProgress: onSendProgress,
      );
      return AdminMediaAsset.fromJson(_requireBody(response));
    });
  }

  Future<AdminMediaAsset> updateMetadata({
    required AdminMediaAsset current,
    required MediaDraft draft,
  }) async {
    return _guard(() async {
      final response = await _dio.put<Map<String, dynamic>>(
        '/api/v1/admin/media/${current.id}',
        data: <String, dynamic>{
          'purpose': draft.purpose.apiValue,
          'altText': draft.altText,
          'sortOrder': draft.sortOrder,
          'active': draft.active,
          'version': current.version,
        },
      );
      return AdminMediaAsset.fromJson(_requireBody(response));
    });
  }

  Future<AdminMediaAsset> replaceContent({
    required AdminMediaAsset current,
    required XFile file,
    ProgressCallback? onSendProgress,
  }) async {
    return _guard(() async {
      final bytes = await file.readAsBytes();
      final formData = FormData.fromMap(<String, dynamic>{
        'file': MultipartFile.fromBytes(bytes, filename: file.name),
        'version': current.version.toString(),
      });
      final response = await _dio.put<Map<String, dynamic>>(
        '/api/v1/admin/media/${current.id}/content',
        data: formData,
        options: Options(contentType: Headers.multipartFormDataContentType),
        onSendProgress: onSendProgress,
      );
      return AdminMediaAsset.fromJson(_requireBody(response));
    });
  }

  Future<void> deactivate(AdminMediaAsset asset) async {
    await _guard(() async {
      await _dio.delete<void>(
        '/api/v1/admin/media/${asset.id}',
        queryParameters: <String, dynamic>{'version': asset.version},
      );
    });
  }

  Future<OrphanReport> findOrphans() async {
    return _guard(() async {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/v1/admin/media/orphans',
      );
      return OrphanReport.fromJson(_requireBody(response));
    });
  }

  Future<OrphanCleanupResult> cleanupOrphans() async {
    return _guard(() async {
      final response = await _dio.delete<Map<String, dynamic>>(
        '/api/v1/admin/media/orphans',
      );
      return OrphanCleanupResult.fromJson(_requireBody(response));
    });
  }

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on MediaMutationException {
      rethrow;
    } on DioException catch (error) {
      final status = error.response?.statusCode;
      final data = error.response?.data;
      String message = 'The media request could not be completed.';
      if (data is Map<String, dynamic>) {
        final detail = data['detail'];
        if (detail is String && detail.trim().isNotEmpty) {
          message = detail;
        }
      } else if (data is Map) {
        final detail = data['detail'];
        if (detail is String && detail.trim().isNotEmpty) {
          message = detail;
        }
      }
      throw MediaMutationException(
        message: message,
        statusCode: status,
        isConflict: status == 409,
      );
    }
  }

  Map<String, dynamic> _requireBody(Response<Map<String, dynamic>> response) {
    final data = response.data;
    if (data == null) {
      throw const MediaMutationException(
        message: 'Media API returned no response body.',
      );
    }
    return data;
  }
}
