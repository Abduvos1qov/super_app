import 'package:core/core.dart';
import 'package:dio/dio.dart';
import 'package:mini_app_sdk/mini_app_sdk.dart';

import 'package:networking/src/api_client.dart';

/// Concrete [NetworkGateway] on top of [ApiClient]. Translates Dio failures
/// into typed [AppError] variants:
///
/// | Dio failure                                    | AppError      |
/// |------------------------------------------------|---------------|
/// | `connectionTimeout` / `sendTimeout` / `receiveTimeout` | `NetworkError` |
/// | `connectionError`                              | `NetworkError` |
/// | `badResponse` with status `401` / `403`         | `AuthError`    |
/// | `badResponse` with status `4xx` (other)         | `ValidationError` |
/// | `badResponse` with status `5xx`                 | `ServerError`  |
/// | `cancel`                                       | `UnknownError` |
/// | `badCertificate` / `unknown`                   | `NetworkError` |
/// | Any non-Dio exception                           | `UnknownError` |
class NetworkGatewayImpl implements NetworkGateway {
  /// Creates a gateway backed by the supplied [ApiClient].
  NetworkGatewayImpl(this._client);

  final ApiClient _client;

  @override
  Future<Result<T, AppError>> get<T>(
    String path, {
    required T Function(Object? json) decode,
    Map<String, String>? headers,
    Map<String, Object?>? query,
  }) =>
      _send<T>(
        () => _client.dio.get<Object?>(
          path,
          queryParameters: query,
          options: Options(headers: headers),
        ),
        decode,
      );

  @override
  Future<Result<T, AppError>> post<T>(
    String path, {
    required T Function(Object? json) decode,
    Object? body,
    Map<String, String>? headers,
    Map<String, Object?>? query,
  }) =>
      _send<T>(
        () => _client.dio.post<Object?>(
          path,
          data: body,
          queryParameters: query,
          options: Options(headers: headers),
        ),
        decode,
      );

  @override
  Future<Result<T, AppError>> put<T>(
    String path, {
    required T Function(Object? json) decode,
    Object? body,
    Map<String, String>? headers,
    Map<String, Object?>? query,
  }) =>
      _send<T>(
        () => _client.dio.put<Object?>(
          path,
          data: body,
          queryParameters: query,
          options: Options(headers: headers),
        ),
        decode,
      );

  @override
  Future<Result<T, AppError>> delete<T>(
    String path, {
    required T Function(Object? json) decode,
    Object? body,
    Map<String, String>? headers,
    Map<String, Object?>? query,
  }) =>
      _send<T>(
        () => _client.dio.delete<Object?>(
          path,
          data: body,
          queryParameters: query,
          options: Options(headers: headers),
        ),
        decode,
      );

  Future<Result<T, AppError>> _send<T>(
    Future<Response<Object?>> Function() request,
    T Function(Object? json) decode,
  ) async {
    try {
      final response = await request();
      return Ok<T, AppError>(decode(response.data));
    } on DioException catch (err, stackTrace) {
      return Err<T, AppError>(_mapDioError(err, stackTrace));
    } on FormatException catch (err) {
      return Err<T, AppError>(
        ValidationError(
          message: 'Failed to decode response: ${err.message}',
          cause: err,
        ),
      );
    }
  }

  AppError _mapDioError(DioException err, StackTrace stackTrace) {
    final status = err.response?.statusCode ?? 0;
    final message = err.message ?? err.error?.toString() ?? 'Network error';

    return switch (err.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout =>
        NetworkError(message: 'Request timed out', cause: err),
      DioExceptionType.connectionError ||
      DioExceptionType.badCertificate ||
      DioExceptionType.unknown =>
        NetworkError(message: message, cause: err),
      DioExceptionType.cancel =>
        UnknownError(message: 'Request was cancelled', cause: err),
      DioExceptionType.badResponse => _mapStatus(status, err),
    };
  }

  AppError _mapStatus(int status, DioException err) {
    if (status == 401) {
      return AuthError(
        message: 'Unauthorized',
        kind: AuthErrorKind.expiredToken,
        cause: err,
      );
    }
    if (status == 403) {
      return AuthError(
        message: 'Forbidden',
        kind: AuthErrorKind.forbidden,
        cause: err,
      );
    }
    if (status >= 500) {
      return ServerError(
        message: 'Server error ($status)',
        statusCode: status,
        cause: err,
      );
    }
    if (status >= 400) {
      return ValidationError(
        message: 'Request rejected ($status)',
        cause: err,
      );
    }
    return UnknownError(
      message: 'Unexpected response ($status)',
      cause: err,
    );
  }
}
