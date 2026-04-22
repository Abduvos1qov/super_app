import 'package:mini_app_sdk/mini_app_sdk.dart';
import 'package:permission_handler/permission_handler.dart' as ph;

/// Translates between [MiniAppPermission] / [PermissionStatus] exposed by the
/// shell SDK and the concrete enums from the `permission_handler` plugin.
///
/// The mapper is intentionally static and exhaustive so that every new
/// [MiniAppPermission] is a compile-time error until its mapping is added.
final class PermissionMapper {
  const PermissionMapper._();

  /// Returns `true` when [permission] maps to an OS-level permission that the
  /// plugin can resolve. App-level gates (payments, biometrics) return
  /// `false` so callers can route them to the relevant service instead.
  static bool isOsLevel(MiniAppPermission permission) {
    return switch (permission) {
      MiniAppPermission.payments || MiniAppPermission.biometrics => false,
      _ => true,
    };
  }

  /// Maps a [MiniAppPermission] to the underlying plugin permission.
  ///
  /// Throws [UnsupportedError] for permissions that are not OS-level and must
  /// be brokered by an app-level service instead:
  ///
  /// * [MiniAppPermission.payments] is an app-level capability gate, not an
  ///   OS permission; the payments service enforces it.
  /// * [MiniAppPermission.biometrics] is handled via `local_auth` (or an
  ///   equivalent package), not `permission_handler`.
  static ph.Permission toPlugin(MiniAppPermission permission) {
    return switch (permission) {
      MiniAppPermission.location => ph.Permission.location,
      MiniAppPermission.locationBackground => ph.Permission.locationAlways,
      MiniAppPermission.camera => ph.Permission.camera,
      MiniAppPermission.microphone => ph.Permission.microphone,
      MiniAppPermission.contacts => ph.Permission.contacts,
      MiniAppPermission.photos => ph.Permission.photos,
      MiniAppPermission.storage => ph.Permission.storage,
      MiniAppPermission.payments => throw UnsupportedError(
          'MiniAppPermission.payments is an app-level capability gate and '
          'cannot be resolved through permission_handler.',
        ),
      MiniAppPermission.notifications => ph.Permission.notification,
      MiniAppPermission.biometrics => throw UnsupportedError(
          'MiniAppPermission.biometrics is handled by local_auth, not '
          'permission_handler.',
        ),
      MiniAppPermission.calendar => ph.Permission.calendarFullAccess,
      MiniAppPermission.bluetooth => ph.Permission.bluetooth,
    };
  }

  /// Maps a plugin [ph.PermissionStatus] to the shell-facing
  /// [PermissionStatus] enum.
  ///
  /// `limited` (iOS "selected photos") and `provisional` (iOS notifications)
  /// are both treated as [PermissionStatus.granted] because the mini-app
  /// contract only distinguishes "may call the capability or not" — partial
  /// access is still access.
  static PermissionStatus fromPlugin(ph.PermissionStatus status) {
    return switch (status) {
      ph.PermissionStatus.granted => PermissionStatus.granted,
      ph.PermissionStatus.denied => PermissionStatus.denied,
      ph.PermissionStatus.restricted => PermissionStatus.restricted,
      ph.PermissionStatus.limited => PermissionStatus.granted,
      ph.PermissionStatus.permanentlyDenied =>
        PermissionStatus.permanentlyDenied,
      ph.PermissionStatus.provisional => PermissionStatus.granted,
    };
  }
}
