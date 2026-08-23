import 'package:cinnamon_clay_admin/src/auth/auth_controller.dart';
import 'package:cinnamon_clay_admin/src/auth/auth_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LoginPage extends ConsumerWidget {
  const LoginPage({this.error, super.key});

  final Object? error;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final message = _messageFor(error);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const CircleAvatar(
                        radius: 34,
                        child: Icon(Icons.local_cafe_outlined, size: 34),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Cinnamon & Clay',
                        style: Theme.of(context).textTheme.headlineMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Administration',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Sign in with an authorized staff account to manage cafe content and operations.',
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      if (message != null) ...<Widget>[
                        const SizedBox(height: 20),
                        Semantics(
                          liveRegion: true,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.errorContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              message,
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onErrorContainer,
                              ),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () => ref
                              .read(authControllerProvider.notifier)
                              .signIn(),
                          icon: const Icon(Icons.login),
                          label: const Text('Sign in'),
                        ),
                      ),
                      if (error != null) ...<Widget>[
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () => ref
                              .read(authControllerProvider.notifier)
                              .retryRestore(),
                          child: const Text('Retry saved session'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String? _messageFor(Object? error) {
    if (error == null) {
      return null;
    }
    if (error is AuthException) {
      return error.message;
    }
    return 'Authentication is temporarily unavailable. Please try again.';
  }
}
