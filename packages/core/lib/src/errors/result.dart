import 'package:meta/meta.dart';

/// A fallible outcome. Prefer this over throwing from services and pure
/// business logic so call sites must acknowledge failure at compile time.
@immutable
sealed class Result<T, E> {
  const Result();

  bool get isOk => this is Ok<T, E>;
  bool get isErr => this is Err<T, E>;

  /// Returns the value or throws [StateError] if this is an [Err]. Only use
  /// in tests — production code should pattern-match instead.
  T get valueOrThrow => switch (this) {
        Ok<T, E>(:final value) => value,
        Err<T, E>(:final error) => throw StateError('Result is Err: $error'),
      };

  Result<R, E> map<R>(R Function(T value) f) => switch (this) {
        Ok<T, E>(:final value) => Ok<R, E>(f(value)),
        Err<T, E>(:final error) => Err<R, E>(error),
      };

  Result<T, F> mapErr<F>(F Function(E error) f) => switch (this) {
        Ok<T, E>(:final value) => Ok<T, F>(value),
        Err<T, E>(:final error) => Err<T, F>(f(error)),
      };

  R fold<R>({required R Function(T value) onOk, required R Function(E error) onErr}) =>
      switch (this) {
        Ok<T, E>(:final value) => onOk(value),
        Err<T, E>(:final error) => onErr(error),
      };
}

final class Ok<T, E> extends Result<T, E> {
  const Ok(this.value);

  final T value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Ok<T, E> && other.value == value;

  @override
  int get hashCode => Object.hash('Ok', value);

  @override
  String toString() => 'Ok($value)';
}

final class Err<T, E> extends Result<T, E> {
  const Err(this.error);

  final E error;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Err<T, E> && other.error == error;

  @override
  int get hashCode => Object.hash('Err', error);

  @override
  String toString() => 'Err($error)';
}
