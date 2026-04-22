import 'dart:async';

import 'package:deep_links/src/deep_link_parser.dart';
import 'package:meta/meta.dart';
import 'package:mini_app_sdk/mini_app_sdk.dart';

/// Default [DeepLinkDispatcher] implementation backed by broadcast streams.
///
/// The shell owns the instance and calls [submit] whenever the platform link
/// source (e.g. `app_links`, `uni_links`, initial-link lookup, a debug
/// override) delivers a [Uri]. The dispatcher parses it with [parser] and,
/// if the URI resolves to a known mini-app, fans the result out to every
/// subscriber of [linksFor] for that mini-app id.
///
/// URIs that do not parse are dropped silently — never routed, never thrown.
/// This is intentional: deep links originate from untrusted sources (SMS,
/// clipboard, deeplink ads) and must fail closed.
@visibleForTesting
class DefaultDeepLinkDispatcher implements DeepLinkDispatcher {
  /// Creates a dispatcher that uses [parser] to resolve incoming URIs.
  DefaultDeepLinkDispatcher({required this.parser});

  /// The parser used to validate and structure incoming URIs.
  final DeepLinkParser parser;

  final Map<String, StreamController<DeepLink>> _controllers =
      <String, StreamController<DeepLink>>{};

  bool _disposed = false;

  /// Whether [dispose] has already been invoked on this dispatcher.
  bool get isDisposed => _disposed;

  /// Feeds a platform-delivered [uri] into the dispatcher.
  ///
  /// If [uri] matches a configured scheme/host and resolves to a known
  /// mini-app with active subscribers, the corresponding [DeepLink] is
  /// pushed onto its stream. Otherwise the call is a no-op.
  void submit(Uri uri) {
    if (_disposed) {
      return;
    }
    final link = parser.parse(uri);
    if (link == null) {
      return;
    }
    final controller = _controllers[link.miniAppId];
    if (controller == null || controller.isClosed) {
      return;
    }
    controller.add(link);
  }

  @override
  Stream<DeepLink> linksFor(String miniAppId) {
    if (_disposed) {
      return const Stream<DeepLink>.empty();
    }
    final controller = _controllers.putIfAbsent(
      miniAppId,
      StreamController<DeepLink>.broadcast,
    );
    return controller.stream;
  }

  /// Closes every per-mini-app controller and marks the dispatcher disposed.
  ///
  /// After disposal:
  /// * [submit] becomes a no-op.
  /// * [linksFor] returns an empty stream.
  /// * Existing subscribers receive `onDone`.
  /// * Calling [dispose] a second time is safe and idempotent.
  Future<void> dispose() async {
    if (_disposed) {
      return;
    }
    _disposed = true;
    final controllers = List<StreamController<DeepLink>>.from(
      _controllers.values,
    );
    _controllers.clear();
    for (final controller in controllers) {
      await controller.close();
    }
  }
}
