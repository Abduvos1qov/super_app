import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shared_ui/shared_ui.dart';

import 'package:super_app/providers/platform_providers.dart';
import 'package:super_app/router/app_router.dart';

/// Root widget for the super-app shell.
///
/// Triggers `SessionController.bootstrap` exactly once at startup (via
/// the private `_startupBootstrapProvider`) and wires the shell's `GoRouter`
/// into `MaterialApp.router`. The provider container owns the underlying
/// `AppBootstrap`, which disposes cleanly when Riverpod tears down.
class SuperApp extends ConsumerWidget {
  /// Creates the super-app root widget.
  const SuperApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Kick off session restoration as a side effect. We only care that it
    // runs; the resulting state is observed through `sessionStateProvider`
    // elsewhere in the tree.
    ref.watch(_startupBootstrapProvider);

    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'Super App',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}

/// Fires `DefaultSessionController.bootstrap` exactly once per provider
/// container. Declared private so nothing else in the tree can observe it
/// and accidentally re-run the restore path.
final _startupBootstrapProvider = FutureProvider<void>((ref) async {
  final bootstrap = ref.watch(appBootstrapProvider);
  await bootstrap.sessionController.bootstrap();
});
