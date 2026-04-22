/// Shell-side analytics facade exposed to mini-apps.
///
/// The shell owns the underlying analytics SDKs (product analytics, crash
/// reporting, attribution) and fans events out. Mini-apps never import an
/// analytics SDK directly.
abstract class AnalyticsTracker {
  /// Records an event with arbitrary string-keyed properties.
  ///
  /// [event] should follow `snake_case` and be stable across releases.
  /// [props] values are limited to JSON primitives; complex objects must be
  /// serialised by the caller.
  void track(String event, {Map<String, Object?> props = const {}});

  /// Sets a sticky property on the current user profile. Pass `null` to
  /// clear the property.
  void setUserProperty(String key, Object? value);

  /// Forces buffered events to be sent immediately. Useful before a critical
  /// user action (checkout confirmation, sign-out).
  Future<void> flush();
}
