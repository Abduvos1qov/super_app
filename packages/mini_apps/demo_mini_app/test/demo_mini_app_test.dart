import 'package:demo_mini_app/demo_mini_app.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_app_sdk/mini_app_sdk.dart';

import 'helpers/fake_mini_app_context.dart';

void main() {
  group('DemoMiniApp', () {
    late DemoMiniApp sut;
    late MiniAppContext context;

    setUp(() {
      sut = const DemoMiniApp();
      context = FakeMiniAppContext();
    });

    test('manifest exposes the stable reverse-dns id', () {
      expect(sut.manifest.id, equals('com.superapp.demo'));
    });

    test('manifest has the expected name, version and category', () {
      expect(sut.manifest.name, equals('Demo'));
      expect(sut.manifest.version, equals('0.1.0'));
      expect(sut.manifest.category, equals(MiniAppCategory.utilities));
    });

    test('manifest defaults to always-visible', () {
      expect(
        sut.manifest.visibility,
        equals(const MiniAppVisibility.always()),
      );
    });

    test('manifest declares no required permissions', () {
      expect(sut.manifest.requiredPermissions, isEmpty);
    });

    test('routes() returns a single root route named demo-home', () {
      final routes = sut.routes(context);

      expect(routes, hasLength(1));
      expect(routes.single.path, equals('/'));
      expect(routes.single.name, equals('demo-home'));
      expect(routes.single.children, isEmpty);
    });

    test('lifecycle hooks default to no-op futures', () async {
      await expectLater(sut.onInstall(context), completes);
      await expectLater(sut.onBootstrap(context), completes);
      await expectLater(sut.onActivate(context), completes);
      await expectLater(sut.onDeactivate(context), completes);
      await expectLater(sut.onUninstall(context), completes);
    });
  });

  group('demoMiniAppManifest', () {
    test('is a const value that matches DemoMiniApp.manifest', () {
      expect(
        identical(demoMiniAppManifest, const DemoMiniApp().manifest),
        isTrue,
      );
    });
  });
}
