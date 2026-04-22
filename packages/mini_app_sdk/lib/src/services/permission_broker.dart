import 'package:mini_app_sdk/src/manifest/mini_app_permission.dart';

/// Current status of an OS-level permission, normalised across platforms.
enum PermissionStatus {
  /// The permission has been granted.
  granted,

  /// The permission has been denied but can still be requested again.
  denied,

  /// The permission has been permanently denied; only the system Settings
  /// app can re-enable it.
  permanentlyDenied,

  /// The permission is restricted by parental controls or device policy.
  restricted,

  /// The permission status is not yet determined.
  notDetermined,
}

/// Shell-side permission facade exposed to mini-apps.
///
/// The shell owns the underlying platform permission plugins, presents the
/// system prompts, and enforces the rationale requirement. Mini-apps never
/// call platform channels directly.
abstract class PermissionBroker {
  /// Returns the current status of [permission] without prompting the user.
  Future<PermissionStatus> check(MiniAppPermission permission);

  /// Requests [permission] from the user, preceded by an in-app rationale.
  ///
  /// [rationale] is a short, human-readable string shown before the OS
  /// prompt so the user understands why the mini-app needs the capability.
  Future<PermissionStatus> request(
    MiniAppPermission permission, {
    required String rationale,
  });
}
