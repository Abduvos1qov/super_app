import 'package:logger/logger.dart';

/// Thin wrapper over `package:logger` that standardises levels across the
/// monorepo. Services, notifiers, and pure logic should log through this —
/// never `print` or `debugPrint` in non-test code.
class AppLogger {
  AppLogger({required String tag, Logger? logger})
      : _tag = tag,
        _logger = logger ?? Logger(printer: PrettyPrinter(methodCount: 0));

  final String _tag;
  final Logger _logger;

  void trace(String message, {Object? error, StackTrace? stackTrace}) =>
      _logger.t('[$_tag] $message', error: error, stackTrace: stackTrace);

  void debug(String message, {Object? error, StackTrace? stackTrace}) =>
      _logger.d('[$_tag] $message', error: error, stackTrace: stackTrace);

  void info(String message, {Object? error, StackTrace? stackTrace}) =>
      _logger.i('[$_tag] $message', error: error, stackTrace: stackTrace);

  void warning(String message, {Object? error, StackTrace? stackTrace}) =>
      _logger.w('[$_tag] $message', error: error, stackTrace: stackTrace);

  void error(String message, {Object? error, StackTrace? stackTrace}) =>
      _logger.e('[$_tag] $message', error: error, stackTrace: stackTrace);
}
