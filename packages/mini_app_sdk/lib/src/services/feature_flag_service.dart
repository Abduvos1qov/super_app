/// Shell-side feature-flag facade exposed to mini-apps.
///
/// The shell owns the underlying flag backend (Remote Config, LaunchDarkly,
/// etc.) and resolves values against the current session and device. Flags
/// are evaluated synchronously from an in-memory snapshot that the shell
/// refreshes out-of-band.
abstract class FeatureFlagService {
  /// Resolves a boolean flag. Returns [fallback] when the key is missing.
  bool boolFlag(String key, {bool fallback = false});

  /// Resolves a string flag. Returns [fallback] when the key is missing.
  String stringFlag(String key, {String fallback = ''});

  /// Resolves a JSON-structured flag, decoded via [decode].
  ///
  /// Returns [fallback] when the key is missing or when [decode] throws.
  T jsonFlag<T>(
    String key, {
    required T Function(Object? json) decode,
    required T fallback,
  });

  /// Emits a void event each time the underlying flag snapshot changes, so
  /// callers can re-evaluate.
  Stream<void> changes();
}
