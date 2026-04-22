import 'dart:async';

import 'package:meta/meta.dart';
import 'package:mini_app_sdk/mini_app_sdk.dart';

/// Default [AppEventBus] implementation based on a single broadcast
/// [StreamController].
///
/// - Type-safe: `on<T extends AppEvent>()` filters by runtime type.
/// - Memory-safe: subscriptions are managed by callers (they hold the
///   [StreamSubscription] and cancel in dispose).
/// - Topic-aware: subscribers receive the full [AppEvent] instance so they
///   can branch on `event.topic` if a single type is reused across topics.
@visibleForTesting
class StreamAppEventBus implements AppEventBus {
  /// Creates a fresh bus backed by a broadcast [StreamController].
  StreamAppEventBus() : _controller = StreamController<AppEvent>.broadcast();

  final StreamController<AppEvent> _controller;

  /// Whether [dispose] has already been invoked on this bus.
  bool get isDisposed => _controller.isClosed;

  @override
  void publish<T extends AppEvent>(T event) {
    if (_controller.isClosed) {
      return;
    }
    _controller.add(event);
  }

  @override
  Stream<T> on<T extends AppEvent>() {
    return _controller.stream.where((event) => event is T).cast<T>();
  }

  /// Closes the underlying stream. Call from shell teardown.
  ///
  /// After disposal:
  /// * Subsequent [publish] calls become no-ops (no exception).
  /// * Existing subscribers receive `onDone`.
  /// * Calling [dispose] a second time is safe and idempotent.
  Future<void> dispose() async {
    if (_controller.isClosed) {
      return;
    }
    await _controller.close();
  }
}
