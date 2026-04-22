import 'package:meta/meta.dart';

/// Immutable snapshot of the demo mini-app's trivial internal state.
///
/// Kept deliberately small so this package also serves as a template for
/// other mini-apps: new verticals should model their state as a `@immutable`
/// class with `copyWith` and value equality rather than holding loose fields
/// on a `ChangeNotifier`.
@immutable
class DemoState {
  /// Creates a [DemoState].
  const DemoState({this.tapCount = 0});

  /// Initial state used by `DemoController` before any user interaction.
  static const DemoState initial = DemoState();

  /// Number of times the user has pressed the counter action on the demo
  /// screen.
  final int tapCount;

  /// Returns a copy of this state with the provided fields replaced.
  DemoState copyWith({int? tapCount}) =>
      DemoState(tapCount: tapCount ?? this.tapCount);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DemoState && other.tapCount == tapCount;

  @override
  int get hashCode => tapCount.hashCode;

  @override
  String toString() => 'DemoState(tapCount: $tapCount)';
}
