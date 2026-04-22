/// Registry that holds the compile-time list of mini-apps the shell ships
/// with, and filters them by the visibility rules declared in each manifest.
///
/// This package pairs with `mini_app_sdk`: the SDK defines the shapes
/// (`MiniApp`, `MiniAppManifest`, `MiniAppVisibility`), this package holds
/// the host-side logic that interprets them.
library;

export 'src/mini_app_registry.dart';
export 'src/visibility_evaluator.dart';
