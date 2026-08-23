import 'package:cinnamon_clay_admin/src/core/api_client.dart';
import 'package:cinnamon_clay_admin/src/site_settings/site_settings_models.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final siteSettingsRepositoryProvider = Provider<SiteSettingsRepository>((ref) {
  return SiteSettingsRepository(ref.watch(adminApiClientProvider));
});

final siteSettingsProvider = FutureProvider<SiteSettingsSnapshot>((ref) async {
  return ref.watch(siteSettingsRepositoryProvider).fetch();
});

class SiteSettingsRepository {
  SiteSettingsRepository(this._dio);

  final Dio _dio;

  Future<SiteSettingsSnapshot> fetch() async {
    return _guard(() async {
      final responses = await Future.wait<Response<Map<String, dynamic>>>([
        _dio.get<Map<String, dynamic>>('/api/v1/admin/content'),
        _dio.get<Map<String, dynamic>>('/api/v1/admin/contact'),
      ]);
      final content = _requireBody(responses[0]);
      final contact = _requireBody(responses[1]);

      return SiteSettingsSnapshot(
        site: AdminSiteProfile.fromJson(content['site'] as Map<String, dynamic>),
        paragraphs: _list(content, 'paragraphs', AdminAboutParagraph.fromJson),
        features: _list(content, 'features', AdminSiteFeature.fromJson),
        contact: AdminContactProfile.fromJson(
          contact['profile'] as Map<String, dynamic>,
        ),
        hours: _list(contact, 'hours', AdminOpeningHour.fromJson),
        socialLinks: _list(contact, 'socialLinks', AdminSocialLink.fromJson),
      );
    });
  }

  Future<AdminSiteProfile> updateSite({
    required AdminSiteProfile current,
    required String brandName,
    required String tagline,
    required String heroNote,
    required String menuNote,
    required String aboutTitle,
  }) async {
    return _guard(() async {
      final response = await _dio.put<Map<String, dynamic>>(
        '/api/v1/admin/content/site',
        data: <String, dynamic>{
          'brandName': brandName,
          'tagline': tagline,
          'heroNote': heroNote,
          'menuNote': menuNote,
          'aboutTitle': aboutTitle,
          'version': current.version,
        },
      );
      return AdminSiteProfile.fromJson(_requireBody(response));
    });
  }

  Future<AdminAboutParagraph> createParagraph({
    required String body,
    required int sortOrder,
    required bool active,
  }) async {
    return _guard(() async {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/v1/admin/content/paragraphs',
        data: <String, dynamic>{
          'body': body,
          'sortOrder': sortOrder,
          'active': active,
        },
      );
      return AdminAboutParagraph.fromJson(_requireBody(response));
    });
  }

  Future<AdminAboutParagraph> updateParagraph({
    required AdminAboutParagraph current,
    required String body,
    required int sortOrder,
    required bool active,
  }) async {
    return _guard(() async {
      final response = await _dio.put<Map<String, dynamic>>(
        '/api/v1/admin/content/paragraphs/${current.id}',
        data: <String, dynamic>{
          'body': body,
          'sortOrder': sortOrder,
          'active': active,
          'version': current.version,
        },
      );
      return AdminAboutParagraph.fromJson(_requireBody(response));
    });
  }

  Future<void> deactivateParagraph(AdminAboutParagraph paragraph) async {
    await _deleteVersioned(
      '/api/v1/admin/content/paragraphs/${paragraph.id}',
      paragraph.version,
    );
  }

  Future<AdminSiteFeature> createFeature({
    required String icon,
    required String title,
    required String text,
    required int sortOrder,
    required bool active,
  }) async {
    return _guard(() async {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/v1/admin/content/features',
        data: <String, dynamic>{
          'icon': icon,
          'title': title,
          'text': text,
          'sortOrder': sortOrder,
          'active': active,
        },
      );
      return AdminSiteFeature.fromJson(_requireBody(response));
    });
  }

  Future<AdminSiteFeature> updateFeature({
    required AdminSiteFeature current,
    required String icon,
    required String title,
    required String text,
    required int sortOrder,
    required bool active,
  }) async {
    return _guard(() async {
      final response = await _dio.put<Map<String, dynamic>>(
        '/api/v1/admin/content/features/${current.id}',
        data: <String, dynamic>{
          'icon': icon,
          'title': title,
          'text': text,
          'sortOrder': sortOrder,
          'active': active,
          'version': current.version,
        },
      );
      return AdminSiteFeature.fromJson(_requireBody(response));
    });
  }

  Future<void> deactivateFeature(AdminSiteFeature feature) async {
    await _deleteVersioned(
      '/api/v1/admin/content/features/${feature.id}',
      feature.version,
    );
  }

  Future<AdminContactProfile> updateContact({
    required AdminContactProfile current,
    required String address,
    required String phone,
    required String email,
    required String mapEmbedUrl,
    required bool whatsappEnabled,
    required String? whatsappNumber,
    required String whatsappPrefill,
  }) async {
    return _guard(() async {
      final response = await _dio.put<Map<String, dynamic>>(
        '/api/v1/admin/contact/profile',
        data: <String, dynamic>{
          'address': address,
          'phone': phone,
          'email': email,
          'mapEmbedUrl': mapEmbedUrl,
          'whatsappEnabled': whatsappEnabled,
          'whatsappNumber': whatsappNumber,
          'whatsappPrefill': whatsappPrefill,
          'version': current.version,
        },
      );
      return AdminContactProfile.fromJson(_requireBody(response));
    });
  }

  Future<AdminOpeningHour> createHour({
    required String dayLabel,
    required String timeLabel,
    required int sortOrder,
    required bool active,
  }) async {
    return _guard(() async {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/v1/admin/contact/hours',
        data: <String, dynamic>{
          'dayLabel': dayLabel,
          'timeLabel': timeLabel,
          'sortOrder': sortOrder,
          'active': active,
        },
      );
      return AdminOpeningHour.fromJson(_requireBody(response));
    });
  }

  Future<AdminOpeningHour> updateHour({
    required AdminOpeningHour current,
    required String dayLabel,
    required String timeLabel,
    required int sortOrder,
    required bool active,
  }) async {
    return _guard(() async {
      final response = await _dio.put<Map<String, dynamic>>(
        '/api/v1/admin/contact/hours/${current.id}',
        data: <String, dynamic>{
          'dayLabel': dayLabel,
          'timeLabel': timeLabel,
          'sortOrder': sortOrder,
          'active': active,
          'version': current.version,
        },
      );
      return AdminOpeningHour.fromJson(_requireBody(response));
    });
  }

  Future<void> deactivateHour(AdminOpeningHour hour) async {
    await _deleteVersioned(
      '/api/v1/admin/contact/hours/${hour.id}',
      hour.version,
    );
  }

  Future<AdminSocialLink> createSocialLink({
    required String platform,
    required String url,
    required int sortOrder,
    required bool active,
  }) async {
    return _guard(() async {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/v1/admin/contact/social-links',
        data: <String, dynamic>{
          'platform': platform,
          'url': url,
          'sortOrder': sortOrder,
          'active': active,
        },
      );
      return AdminSocialLink.fromJson(_requireBody(response));
    });
  }

  Future<AdminSocialLink> updateSocialLink({
    required AdminSocialLink current,
    required String platform,
    required String url,
    required int sortOrder,
    required bool active,
  }) async {
    return _guard(() async {
      final response = await _dio.put<Map<String, dynamic>>(
        '/api/v1/admin/contact/social-links/${current.id}',
        data: <String, dynamic>{
          'platform': platform,
          'url': url,
          'sortOrder': sortOrder,
          'active': active,
          'version': current.version,
        },
      );
      return AdminSocialLink.fromJson(_requireBody(response));
    });
  }

  Future<void> deactivateSocialLink(AdminSocialLink link) async {
    await _deleteVersioned(
      '/api/v1/admin/contact/social-links/${link.id}',
      link.version,
    );
  }

  Future<void> _deleteVersioned(String path, int version) async {
    await _guard(() async {
      await _dio.delete<void>(
        path,
        queryParameters: <String, dynamic>{'version': version},
      );
    });
  }

  Map<String, dynamic> _requireBody(Response<Map<String, dynamic>> response) {
    final data = response.data;
    if (data == null) {
      throw const SiteSettingsMutationException(
        message: 'Site settings API returned no response body.',
      );
    }
    return data;
  }

  List<T> _list<T>(
    Map<String, dynamic> source,
    String key,
    T Function(Map<String, dynamic>) parse,
  ) {
    return (source[key] as List<dynamic>)
        .map((item) => parse(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<T> _guard<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } on SiteSettingsMutationException {
      rethrow;
    } on DioException catch (error) {
      final data = error.response?.data;
      String? detail;
      if (data is Map<String, dynamic>) {
        detail = data['detail'] as String?;
      }
      throw SiteSettingsMutationException(
        message: detail ?? 'The site settings change could not be completed.',
        statusCode: error.response?.statusCode,
      );
    }
  }
}
