import 'package:meta/meta.dart';
import 'package:mini_app_sdk/mini_app_sdk.dart';

/// A strongly-typed feature-flag descriptor.
///
/// Wraps a [FeatureFlagService.jsonFlag] lookup so callers can declare the
/// key, default, and decoder once at the top of a file and evaluate the flag
/// as a one-liner at call sites. Works for any `T`, including `bool` and
/// `String` flags that benefit from a compile-time name.
///
/// ```dart
/// bool _decodeBool(Object? raw) => raw is bool ? raw : false;
///
/// const showWalletTab = TypedFlag<bool>(
///   key: 'ui.wallet_tab_enabled',
///   fallback: false,
///   decode: _decodeBool,
/// );
///
/// if (showWalletTab.read(featureFlags)) {
///   // show tab
/// }
/// ```
@immutable
class TypedFlag<T> {
  /// Creates a typed flag descriptor.
  const TypedFlag({
    required this.key,
    required this.fallback,
    required this.decode,
  });

  /// The flag key stored in the underlying [FeatureFlagService].
  final String key;

  /// The value returned when [key] is missing or when [decode] throws.
  final T fallback;

  /// Converts the raw JSON value produced by the service into a `T`.
  /// Implementations should be defensive and accept `Object?`.
  final T Function(Object? raw) decode;

  /// Evaluates the flag against [service].
  T read(FeatureFlagService service) =>
      service.jsonFlag<T>(key, decode: decode, fallback: fallback);

  @override
  String toString() => 'TypedFlag<$T>(key: $key)';
}
