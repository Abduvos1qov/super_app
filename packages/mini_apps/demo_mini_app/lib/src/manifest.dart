import 'package:mini_app_sdk/mini_app_sdk.dart';

/// Manifest describing the reference demo mini-app.
///
/// Kept as a top-level `const` so the shell's registration step can include
/// it in compile-time structures (e.g. a `const` registry list).
const demoMiniAppManifest = MiniAppManifest(
  id: 'com.superapp.demo',
  name: 'Demo',
  version: '0.1.0',
  category: MiniAppCategory.utilities,
  iconAssetPath: 'packages/demo_mini_app/assets/icon.svg',
);
