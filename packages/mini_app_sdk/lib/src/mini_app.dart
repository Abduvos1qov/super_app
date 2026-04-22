import 'package:flutter/widgets.dart';

import 'package:mini_app_sdk/src/context/mini_app_context.dart';
import 'package:mini_app_sdk/src/manifest/mini_app_manifest.dart';
import 'package:mini_app_sdk/src/mini_app_route.dart';

/// Base contract every mini-app implements to plug into the super-app shell.
///
/// A mini-app is a self-contained vertical (ride-hailing, food, delivery,
/// payments, …) that the shell discovers through its [manifest], registers
/// routes for, and drives through a lifecycle. Implementations MUST be
/// stateless at the class level — per-session state lives in providers
/// scoped to the mini-app's routes.
abstract class MiniApp {
  /// Base const constructor.
  const MiniApp();

  /// Static metadata describing this mini-app.
  MiniAppManifest get manifest;

  /// Called once when the mini-app is first registered on the device. Use
  /// for one-time migrations (e.g. creating a scoped database). Default is
  /// no-op.
  Future<void> onInstall(MiniAppContext context) async {}

  /// Called when the shell is booting and the mini-app should prime any
  /// caches or background subscriptions it owns. Default is no-op.
  Future<void> onBootstrap(MiniAppContext context) async {}

  /// Called when the mini-app becomes the foregrounded vertical. Default is
  /// no-op.
  Future<void> onActivate(MiniAppContext context) async {}

  /// Called when another mini-app is activated. Release expensive resources
  /// (location tracking, websockets) here. Default is no-op.
  Future<void> onDeactivate(MiniAppContext context) async {}

  /// Called once before the mini-app is removed from the device. Clean up
  /// persistent state. Default is no-op.
  Future<void> onUninstall(MiniAppContext context) async {}

  /// Routes this mini-app contributes to the shell's router. The shell
  /// mounts them under the mini-app's own path namespace.
  List<MiniAppRoute> routes(MiniAppContext context);

  /// Builds the launcher tile rendered on the super-app home screen.
  Widget buildLauncherTile(BuildContext context, MiniAppContext miniAppContext);
}
