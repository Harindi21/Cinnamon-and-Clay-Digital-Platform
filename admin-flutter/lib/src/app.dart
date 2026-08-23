import 'package:cinnamon_clay_admin/src/auth/auth_gate.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

final GoRouter _router = GoRouter(
  routes: <RouteBase>[
    GoRoute(path: '/', builder: (context, state) => const AuthGate()),
  ],
);

class CinnamonClayAdminApp extends StatelessWidget {
  const CinnamonClayAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Cinnamon & Clay Admin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF5C3A21)),
        useMaterial3: true,
      ),
      routerConfig: _router,
    );
  }
}
