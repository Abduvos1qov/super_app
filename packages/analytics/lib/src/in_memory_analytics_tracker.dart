import 'package:meta/meta.dart';
import 'package:mini_app_sdk/mini_app_sdk.dart';

/// A deterministic [AnalyticsTracker] for tests.
///
/// Records every call into [events] and [userProperties] so assertions can
/// verify analytics behaviour without mocks. [flush] simply increments
/// [flushCount]. Call [clear] between tests to reset state.
class InMemoryAnalyticsTracker implements AnalyticsTracker {
  /// Events recorded in call order.
  final List<TrackedEvent> events = <TrackedEvent>[];

  /// The current sticky user properties. Setting a key to `null` removes it,
  /// matching the contract documented on [AnalyticsTracker.setUserProperty].
  final Map<String, Object?> userProperties = <String, Object?>{};

  /// The number of times [flush] has been invoked.
  int flushCount = 0;

  @override
  void track(String event, {Map<String, Object?> props = const {}}) {
    events.add(TrackedEvent(event, Map<String, Object?>.of(props)));
  }

  @override
  void setUserProperty(String key, Object? value) {
    if (value == null) {
      userProperties.remove(key);
    } else {
      userProperties[key] = value;
    }
  }

  @override
  Future<void> flush() async {
    flushCount++;
  }

  /// Resets every recorded interaction. Typically called in `setUp`.
  void clear() {
    events.clear();
    userProperties.clear();
    flushCount = 0;
  }
}

/// An immutable record of a single [AnalyticsTracker.track] call.
@immutable
class TrackedEvent {
  /// Creates a tracked event with the given [name] and [props].
  const TrackedEvent(this.name, this.props);

  /// The event name passed to `track`.
  final String name;

  /// A defensive copy of the properties passed to `track`.
  final Map<String, Object?> props;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! TrackedEvent) return false;
    if (other.name != name) return false;
    if (other.props.length != props.length) return false;
    for (final entry in props.entries) {
      if (!other.props.containsKey(entry.key)) return false;
      if (other.props[entry.key] != entry.value) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(name, props.length);

  @override
  String toString() => 'TrackedEvent($name, $props)';
}
