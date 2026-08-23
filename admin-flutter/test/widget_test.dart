import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cinnamon_clay_admin/src/app.dart';
import 'package:cinnamon_clay_admin/src/catalog/catalog_models.dart';
import 'package:cinnamon_clay_admin/src/catalog/catalog_repository.dart';

void main() {
  testWidgets('app starts on catalog page', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          catalogProvider.overrideWith((ref) async => const <MenuCategory>[]),
        ],
        child: const CinnamonClayAdminApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Catalog'), findsOneWidget);
  });
}
