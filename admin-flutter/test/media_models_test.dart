import 'package:cinnamon_clay_admin/src/media/media_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses versioned media metadata and dimensions', () {
    final asset = AdminMediaAsset.fromJson(<String, dynamic>{
      'id': 'media-1',
      'originalFilename': 'hero.png',
      'contentType': 'image/png',
      'sizeBytes': 2048,
      'purpose': 'HERO',
      'altText': 'Cafe interior',
      'caption': 'Morning light',
      'focalXPercent': 35,
      'focalYPercent': 62,
      'sortOrder': 10,
      'active': true,
      'widthPixels': 1600,
      'heightPixels': 900,
      'checksumSha256':
          'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
      'version': 4,
      'createdAt': '2026-08-23T10:00:00Z',
      'updatedAt': '2026-08-23T11:00:00Z',
      'contentUrl': '/api/v1/media/media-1/content',
    });

    expect(asset.purpose, MediaPurpose.hero);
    expect(asset.dimensionsLabel, '1600 x 900 px');
    expect(asset.caption, 'Morning light');
    expect(asset.focalPointLabel, '35% x · 62% y');
    expect(asset.sizeLabel, '2 KB');
    expect(asset.version, 4);
    expect(asset.checksumSha256, hasLength(64));
  });

  test('media conflict exposes refresh signal', () {
    const error = MediaMutationException(
      message: 'stale',
      statusCode: 409,
      isConflict: true,
    );

    expect(error.isConflict, isTrue);
    expect(error.toString(), 'stale');
  });

  test('purpose values match backend contract', () {
    expect(MediaPurpose.hero.apiValue, 'HERO');
    expect(MediaPurpose.about.apiValue, 'ABOUT');
    expect(MediaPurpose.gallery.apiValue, 'GALLERY');
  });

  test('unknown purpose fails fast instead of becoming gallery', () {
    expect(
      () => MediaPurpose.fromApi('UNKNOWN'),
      throwsA(isA<FormatException>()),
    );
  });
  test('new media metadata defaults remain backward compatible', () {
    final asset = AdminMediaAsset.fromJson(<String, dynamic>{
      'id': 'media-legacy',
      'purpose': 'GALLERY',
    });

    expect(asset.caption, isEmpty);
    expect(asset.focalXPercent, 50);
    expect(asset.focalYPercent, 50);
  });
}
