import 'package:core/core.dart';

/// Thin, transport-agnostic HTTP facade injected into mini-apps.
///
/// The shell owns the underlying HTTP client, attaches auth/retry/logging
/// interceptors, and scopes requests to the calling mini-app. Mini-apps never
/// import `dio` (or any HTTP package) directly.
///
/// Every method returns a [Result] instead of throwing; transport, auth and
/// server failures are surfaced as typed [AppError] variants.
abstract class NetworkGateway {
  /// Performs a `GET` request against [path] and decodes the response body
  /// via [decode].
  ///
  /// [path] is joined with the shell's configured base URL unless it is a
  /// fully-qualified URL. [query] entries are URL-encoded.
  Future<Result<T, AppError>> get<T>(
    String path, {
    required T Function(Object? json) decode,
    Map<String, String>? headers,
    Map<String, Object?>? query,
  });

  /// Performs a `POST` request with an optional JSON [body].
  Future<Result<T, AppError>> post<T>(
    String path, {
    required T Function(Object? json) decode,
    Object? body,
    Map<String, String>? headers,
    Map<String, Object?>? query,
  });

  /// Performs a `PUT` request with an optional JSON [body].
  Future<Result<T, AppError>> put<T>(
    String path, {
    required T Function(Object? json) decode,
    Object? body,
    Map<String, String>? headers,
    Map<String, Object?>? query,
  });

  /// Performs a `DELETE` request.
  Future<Result<T, AppError>> delete<T>(
    String path, {
    required T Function(Object? json) decode,
    Object? body,
    Map<String, String>? headers,
    Map<String, Object?>? query,
  });
}
