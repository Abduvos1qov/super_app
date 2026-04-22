import 'package:core/core.dart';
import 'package:mini_app_sdk/mini_app_sdk.dart';

/// An [AnalyticsTracker] that forwards every event to an [AppLogger].
///
/// Intended for local development, debug builds, and as a sanity layer
/// alongside real vendor trackers in production (wrapped in a
/// `FanoutAnalyticsTracker`). Does no batching and issues no network calls,
/// so [flush] is a no-op.
class LoggingAnalyticsTracker implements AnalyticsTracker {
  /// Creates a tracker that logs through [logger]. When omitted, a default
  /// [AppLogger] tagged `analytics` is used.
  LoggingAnalyticsTracker({AppLogger? logger})
      : _logger = logger ?? AppLogger(tag: 'analytics');

  final AppLogger _logger;
  final Map<String, Object?> _userProperties = <String, Object?>{};

  /// The sticky user properties accumulated so far. Exposed as an unmodifiable
  /// snapshot so callers (e.g. tests) can inspect state without mutating it.
  Map<String, Object?> get userPropertiesSnapshot =>
      Map<String, Object?>.unmodifiable(_userProperties);

  @override
  void track(String event, {Map<String, Object?> props = const {}}) {
    _logger.info('event=$event props=${_format(props)}');
  }

  @override
  void setUserProperty(String key, Object? value) {
    if (value == null) {
      _userProperties.remove(key);
    } else {
      _userProperties[key] = value;
    }
    _logger.debug('userProperty[$key]=$value');
  }

  @override
  Future<void> flush() async {
    // Logging is synchronous; nothing to flush.
  }

  String _format(Map<String, Object?> props) => props.isEmpty ? '{}' : '$props';
}
