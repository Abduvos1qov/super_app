import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_app_registry/mini_app_registry.dart';
import 'package:mini_app_sdk/mini_app_sdk.dart';
import 'package:shared_models/shared_models.dart';

/// Minimal [MiniApp] implementation used for registry tests. Only the
/// manifest is exercised; the other overrides are no-op stubs.
class _FakeMiniApp extends MiniApp {
  const _FakeMiniApp(this._manifest);

  final MiniAppManifest _manifest;

  @override
  MiniAppManifest get manifest => _manifest;

  @override
  List<MiniAppRoute> routes(MiniAppContext context) => const <MiniAppRoute>[];

  @override
  Widget buildLauncherTile(
    BuildContext context,
    MiniAppContext miniAppContext,
  ) =>
      const SizedBox.shrink();
}

class _FakeFeatureFlagService implements FeatureFlagService {
  _FakeFeatureFlagService([Map<String, bool>? flags])
      : _flags = <String, bool>{...?flags};

  final Map<String, bool> _flags;

  @override
  bool boolFlag(String key, {bool fallback = false}) =>
      _flags[key] ?? fallback;

  @override
  String stringFlag(String key, {String fallback = ''}) =>
      throw UnimplementedError();

  @override
  T jsonFlag<T>(
    String key, {
    required T Function(Object? json) decode,
    required T fallback,
  }) =>
      throw UnimplementedError();

  @override
  Stream<void> changes() => const Stream<void>.empty();
}

MiniAppManifest _manifest(
  String id, {
  MiniAppVisibility visibility = const MiniAppVisibility.always(),
}) {
  return MiniAppManifest(
    id: id,
    name: id,
    version: '1.0.0',
    category: MiniAppCategory.transport,
    iconAssetPath: 'assets/icon.png',
    visibility: visibility,
  );
}

void main() {
  group('MiniAppRegistry', () {
    late _FakeFeatureFlagService flags;

    setUp(() {
      flags = _FakeFeatureFlagService();
    });

    test('byId returns the matching mini-app', () {
      const registry = MiniAppRegistry(<MiniApp>[
        _FakeMiniApp(
          MiniAppManifest(
            id: 'taxi',
            name: 'Taxi',
            version: '1.0.0',
            category: MiniAppCategory.transport,
            iconAssetPath: 'assets/icon.png',
          ),
        ),
        _FakeMiniApp(
          MiniAppManifest(
            id: 'food',
            name: 'Food',
            version: '1.0.0',
            category: MiniAppCategory.food,
            iconAssetPath: 'assets/icon.png',
          ),
        ),
      ]);

      final app = registry.byId('food');
      expect(app, isNotNull);
      expect(app?.manifest.id, equals('food'));
    });

    test('byId returns null when no mini-app matches', () {
      final registry = MiniAppRegistry(<MiniApp>[
        _FakeMiniApp(_manifest('taxi')),
      ]);
      expect(registry.byId('missing'), isNull);
    });

    test('all exposes an unmodifiable view of the registered mini-apps', () {
      final registry = MiniAppRegistry(<MiniApp>[
        _FakeMiniApp(_manifest('taxi')),
      ]);
      expect(
        () => registry.all.add(_FakeMiniApp(_manifest('injected'))),
        throwsUnsupportedError,
      );
    });

    test('allVisible filters out a mini-app whose feature flag is off', () {
      final registry = MiniAppRegistry(<MiniApp>[
        _FakeMiniApp(_manifest('taxi')),
        _FakeMiniApp(
          _manifest(
            'beta',
            visibility: const MiniAppVisibility.featureFlag('beta_enabled'),
          ),
        ),
      ]);

      final visible = registry.allVisible(
        session: const SessionAnonymous(),
        featureFlags: flags,
      );

      expect(visible.map((a) => a.manifest.id), equals(<String>['taxi']));
    });

    test('allVisible filters multiple mini-apps against session + flags', () {
      flags = _FakeFeatureFlagService({'beta_enabled': true});
      final registry = MiniAppRegistry(<MiniApp>[
        _FakeMiniApp(_manifest('taxi')),
        _FakeMiniApp(
          _manifest(
            'beta',
            visibility: const MiniAppVisibility.featureFlag('beta_enabled'),
          ),
        ),
        _FakeMiniApp(
          _manifest(
            'admin_tools',
            visibility: const MiniAppVisibility.roleBased(<String>{'admin'}),
          ),
        ),
        _FakeMiniApp(
          _manifest(
            'payouts',
            visibility:
                const MiniAppVisibility.kycRequired(KycLevel.enhanced),
          ),
        ),
      ]);

      const session = SessionAuthenticated(
        User(
          id: 'u1',
          phone: '+998901234567',
          displayName: 'Consumer',
          kycLevel: KycLevel.verified,
        ),
      );

      final visible = registry.allVisible(
        session: session,
        featureFlags: flags,
      );

      expect(
        visible.map((a) => a.manifest.id),
        equals(<String>['taxi', 'beta']),
      );
    });

    test('allVisible on an empty registry returns an empty list', () {
      const registry = MiniAppRegistry(<MiniApp>[]);
      expect(
        registry.allVisible(
          session: const SessionAnonymous(),
          featureFlags: flags,
        ),
        isEmpty,
      );
    });

    test('allVisible preserves the registration order', () {
      final registry = MiniAppRegistry(<MiniApp>[
        _FakeMiniApp(_manifest('a')),
        _FakeMiniApp(_manifest('b')),
        _FakeMiniApp(_manifest('c')),
      ]);

      final visible = registry.allVisible(
        session: const SessionAnonymous(),
        featureFlags: flags,
      );

      expect(
        visible.map((a) => a.manifest.id).toList(),
        equals(<String>['a', 'b', 'c']),
      );
    });
  });
}
