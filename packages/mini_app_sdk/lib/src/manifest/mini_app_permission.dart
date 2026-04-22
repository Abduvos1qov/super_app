/// Coarse-grained permission a mini-app may request from the shell.
///
/// The shell translates these into the underlying OS permission prompts
/// (iOS / Android / Web). Mini-apps never call platform channels directly;
/// they go through `PermissionBroker`.
enum MiniAppPermission {
  /// Foreground GPS access.
  location,

  /// Continuous location tracking while the mini-app is backgrounded.
  locationBackground,

  /// Camera capture for scans, photos or live video.
  camera,

  /// Microphone access (voice notes, calls).
  microphone,

  /// Address book access.
  contacts,

  /// Photo library read/write.
  photos,

  /// Shared file storage (downloads, documents).
  storage,

  /// Ability to initiate payments on behalf of the user.
  payments,

  /// Permission to show local / push notifications.
  notifications,

  /// Face ID, Touch ID, fingerprint or device passcode.
  biometrics,

  /// Calendar read/write for bookings, reminders.
  calendar,

  /// Bluetooth scanning / pairing (e.g. for scooters, POS devices).
  bluetooth,
}
