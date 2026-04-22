import 'package:meta/meta.dart';
import 'package:mini_app_sdk/src/manifest/mini_app_category.dart';
import 'package:mini_app_sdk/src/manifest/mini_app_permission.dart';
import 'package:mini_app_sdk/src/manifest/mini_app_visibility.dart';

/// Static metadata describing a mini-app.
///
/// The shell reads the manifest at registration time to render launcher tiles,
/// build the routing table, gate visibility, and validate compatibility with
/// the host version. Every field is immutable and safe to share across
/// isolates.
@immutable
class MiniAppManifest {
  /// Creates a manifest for a mini-app.
  const MiniAppManifest({
    required this.id,
    required this.name,
    required this.version,
    required this.category,
    required this.iconAssetPath,
    this.minShellVersion,
    this.requiredPermissions = const {},
    this.visibility = const MiniAppVisibility.always(),
  });

  /// Stable identifier used for deep links, analytics and routing. Must be
  /// unique across the super-app. Convention: `reverse.dns.style`.
  final String id;

  /// Human-readable display name shown in the launcher and navigation.
  final String name;

  /// Semver string of the mini-app's own release (not the shell).
  final String version;

  /// Coarse-grained category used for launcher grouping and analytics.
  final MiniAppCategory category;

  /// Path to the launcher icon asset, resolved relative to the mini-app's
  /// own asset bundle.
  final String iconAssetPath;

  /// Minimum shell version this mini-app is compatible with. When the host
  /// is older the shell refuses to activate the mini-app.
  final String? minShellVersion;

  /// Permissions the mini-app intends to request during its lifetime. The
  /// shell uses this to surface an upfront disclosure and to scope runtime
  /// permission brokering.
  final Set<MiniAppPermission> requiredPermissions;

  /// Declarative rule governing when the mini-app appears in the launcher.
  final MiniAppVisibility visibility;
}
