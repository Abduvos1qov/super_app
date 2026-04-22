import 'dart:async';

import 'package:core/core.dart';
import 'package:mini_app_sdk/mini_app_sdk.dart';

/// An [AnalyticsTracker] that relays every call to a list of underlying
/// trackers.
///
/// Behaviour is intentionally best-effort: if one tracker throws (for
/// example, a misconfigured vendor SDK), the exception is logged and the
/// remaining trackers still receive the event. This keeps a flaky vendor
/// from breaking analytics for everyone else.
///
/// [flush] waits for every tracker's future to complete and swallows
/// per-tracker failures the same way.
class FanoutAnalyticsTracker implements AnalyticsTracker {
  /// Creates a fan-out tracker that dispatches to [trackers] in order.
  ///
  /// When [logger] is omitted, a default [AppLogger] tagged
  /// `analytics.fanout` records per-tracker failures.
  FanoutAnalyticsTracker(
    List<AnalyticsTracker> trackers, {
    AppLogger? logger,
  })  : _trackers = List<AnalyticsTracker>.unmodifiable(trackers),
        _logger = logger ?? AppLogger(tag: 'analytics.fanout');

  final List<AnalyticsTracker> _trackers;
  final AppLogger _logger;

  /// The underlying trackers in dispatch order.
  List<AnalyticsTracker> get trackers => _trackers;

  @override
  void track(String event, {Map<String, Object?> props = const {}}) {
    for (final tracker in _trackers) {
      try {
        tracker.track(event, props: props);
      } on Object catch (error, stackTrace) {
        _logger.error(
          'tracker ${tracker.runtimeType} threw while tracking "$event"',
          error: error,
          stackTrace: stackTrace,
        );
      }
    }
  }

  @override
  void setUserProperty(String key, Object? value) {
    for (final tracker in _trackers) {
      try {
        tracker.setUserProperty(key, value);
      } on Object catch (error, stackTrace) {
        _logger.error(
          'tracker ${tracker.runtimeType} threw while setting "$key"',
          error: error,
          stackTrace: stackTrace,
        );
      }
    }
  }

  @override
  Future<void> flush() async {
    final futures = _trackers.map((tracker) async {
      try {
        await tracker.flush();
      } on Object catch (error, stackTrace) {
        _logger.error(
          'tracker ${tracker.runtimeType} threw during flush',
          error: error,
          stackTrace: stackTrace,
        );
      }
    });
    await Future.wait(futures);
  }
}
