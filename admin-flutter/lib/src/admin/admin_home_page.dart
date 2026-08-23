import 'package:cinnamon_clay_admin/src/auth/auth_models.dart';
import 'package:cinnamon_clay_admin/src/catalog/catalog_page.dart';
import 'package:cinnamon_clay_admin/src/reviews/reviews_page.dart';
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
          ReviewsPage(identity: widget.identity),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const <NavigationDestination>[
          NavigationDestination(
            icon: Icon(Icons.restaurant_menu_outlined),
            selectedIcon: Icon(Icons.restaurant_menu),
            label: 'Catalog',
          ),
          NavigationDestination(
            icon: Icon(Icons.rate_review_outlined),
            selectedIcon: Icon(Icons.rate_review),
            label: 'Reviews',
          ),
        ],
      ),
    );
  }
}
