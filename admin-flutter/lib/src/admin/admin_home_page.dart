import 'package:cinnamon_clay_admin/src/audit/audit_page.dart';
import 'package:cinnamon_clay_admin/src/auth/auth_models.dart';
import 'package:cinnamon_clay_admin/src/catalog/catalog_page.dart';
import 'package:cinnamon_clay_admin/src/media/media_page.dart';
import 'package:cinnamon_clay_admin/src/reviews/reviews_page.dart';
import 'package:cinnamon_clay_admin/src/site_settings/site_settings_page.dart';
import 'package:flutter/material.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({required this.identity, super.key});

  final AdminIdentity identity;

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: <Widget>[
          CatalogPage(identity: widget.identity),
          SiteSettingsPage(identity: widget.identity),
          MediaPage(identity: widget.identity),
          ReviewsPage(identity: widget.identity),
          if (widget.identity.hasRole('admin'))
            _index == 4
                ? AuditPage(identity: widget.identity)
                : const SizedBox.shrink(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: <NavigationDestination>[
          const NavigationDestination(
            icon: Icon(Icons.restaurant_menu_outlined),
            selectedIcon: Icon(Icons.restaurant_menu),
            label: 'Catalog',
          ),
          const NavigationDestination(
            icon: Icon(Icons.storefront_outlined),
            selectedIcon: Icon(Icons.storefront),
            label: 'Site',
          ),
          const NavigationDestination(
            icon: Icon(Icons.photo_library_outlined),
            selectedIcon: Icon(Icons.photo_library),
            label: 'Media',
          ),
          const NavigationDestination(
            icon: Icon(Icons.rate_review_outlined),
            selectedIcon: Icon(Icons.rate_review),
            label: 'Reviews',
          ),
          if (widget.identity.hasRole('admin'))
            const NavigationDestination(
              icon: Icon(Icons.history_outlined),
              selectedIcon: Icon(Icons.history),
              label: 'Audit',
            ),
        ],
      ),
    );
  }
}
