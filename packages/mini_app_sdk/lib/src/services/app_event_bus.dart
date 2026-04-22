import 'package:mini_app_sdk/src/events/app_event.dart';

/// Shell-side, type-filtered event bus used for cross-mini-app choreography.
///
/// Mini-apps publish [AppEvent] subclasses to announce side effects (e.g.
/// `TripCompletedEvent`, `OrderPlacedEvent`) and subscribe to events from
/// other verticals. The shell may mediate delivery for permission checks or
/// rate limiting.
abstract class AppEventBus {
  /// Publishes [event] to all matching subscribers.
  void publish<T extends AppEvent>(T event);

  /// Returns a stream of events of type [T] (including subclasses).
  Stream<T> on<T extends AppEvent>();
}
