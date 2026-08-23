import 'package:cinnamon_clay_admin/src/auth/auth_controller.dart';
import 'package:cinnamon_clay_admin/src/auth/login_page.dart';
import 'package:cinnamon_clay_admin/src/admin/admin_home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);

    return auth.when(
      loading: () => const _AuthLoadingPage(),
      error: (error, stackTrace) => LoginPage(error: error),
      data: (state) {
        final identity = state.identity;
        if (identity == null) {
          return const LoginPage();
        }
        return AdminHomePage(identity: identity);
      },
    );
  }
}

class _AuthLoadingPage extends StatelessWidget {
  const _AuthLoadingPage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Checking administrator session...'),
          ],
        ),
      ),
    );
  }
}
