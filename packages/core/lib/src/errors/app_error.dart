import 'package:meta/meta.dart';

/// Sealed hierarchy of all recoverable errors surfaced by services and
/// business logic. UI layers match on these variants to render appropriate
/// feedback (retry prompts, inline validation, generic fallbacks).
@immutable
sealed class AppError {
  const AppError({required this.message, this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => '$runtimeType(message: $message)';
}

final class NetworkError extends AppError {
  const NetworkError({required super.message, super.cause});
}

final class AuthError extends AppError {
  const AuthError({required super.message, this.kind = AuthErrorKind.unknown, super.cause});

  final AuthErrorKind kind;
}

enum AuthErrorKind { invalidCredentials, expiredToken, forbidden, unknown }

final class ValidationError extends AppError {
  const ValidationError({required super.message, this.field, super.cause});

  final String? field;
}

final class ServerError extends AppError {
  const ServerError({required super.message, required this.statusCode, super.cause});

  final int statusCode;
}

final class UnknownError extends AppError {
  const UnknownError({required super.message, super.cause});
}
