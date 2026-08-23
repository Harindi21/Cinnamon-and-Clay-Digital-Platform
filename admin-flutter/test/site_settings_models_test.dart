import 'package:cinnamon_clay_admin/src/site_settings/site_settings_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses versioned site profile', () {
    final profile = AdminSiteProfile.fromJson(<String, dynamic>{
      'id': '30000000-0000-0000-0000-000000000001',
      'brandName': 'Cinnamon & Clay',
      'tagline': 'Slow coffee.',
      'heroNote': 'Colombo',
      'menuNote': 'Prices in LKR',
      'aboutTitle': 'Our little story',
      'version': 3,
    });

    expect(profile.brandName, 'Cinnamon & Clay');
    expect(profile.version, 3);
  });

  test('parses nullable WhatsApp number', () {
    final profile = AdminContactProfile.fromJson(<String, dynamic>{
      'id': '40000000-0000-0000-0000-000000000001',
      'address': 'Colombo',
      'phone': '+94 77 123 4567',
      'email': 'hello@example.com',
      'mapEmbedUrl': 'https://example.com/map',
      'whatsappEnabled': false,
      'whatsappNumber': null,
      'whatsappPrefill': '',
      'version': 1,
    });

    expect(profile.whatsappNumber, isNull);
    expect(profile.whatsappEnabled, isFalse);
  });

  test('site settings conflict is identifiable', () {
    const error = SiteSettingsMutationException(
      message: 'stale',
      statusCode: 409,
    );

    expect(error.isConflict, isTrue);
  });
}
