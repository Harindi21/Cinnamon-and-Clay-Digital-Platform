import 'package:cinnamon_clay_admin/src/app.dart';
import 'package:cinnamon_clay_admin/src/core/environment.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  validateAdminEnvironmentOrThrow();
  runApp(const ProviderScope(child: CinnamonClayAdminApp()));
}
