import 'package:meta/meta.dart';

/// Base type for every event published on the cross-mini-app event bus.
///
/// Each concrete event carries a stable [topic] string the shell uses for
/// routing, observability and permission checks. Events MUST be immutable
/// value objects so subscribers can safely share references across isolates.
@immutable
abstract class AppEvent {
  /// Creates a const [AppEvent].
  const AppEvent();

  /// Stable, human-readable topic identifier. Convention:
  /// `mini_app_id.event_name` (e.g. `taxi.trip_completed`).
  String get topic;
}
