import 'package:flutter_test/flutter_test.dart';
import 'package:mini_app_sdk/mini_app_sdk.dart';
import 'package:mocktail/mocktail.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:permissions/permissions.dart';

class _MockPresenter extends Mock implements PermissionRationalePresenter {}

class _FakePermission extends Fake implements ph.Permission {}

void main() {
  setUpAll(() {
    registerFallbackValue(MiniAppPermission.camera);
  });

  group('DefaultPermissionBroker.check', () {
    test('maps a plugin granted status through to the SDK enum', () async {
      final broker = DefaultPermissionBroker(
        statusReader: (_) async => ph.PermissionStatus.granted,
        statusRequester: (_) async => ph.PermissionStatus.granted,
      );

      final status = await broker.check(MiniAppPermission.camera);

      expect(status, equals(PermissionStatus.granted));
    });

    test('returns notDetermined for payments (app-level gate)', () async {
      final broker = DefaultPermissionBroker(
        statusReader: (_) async =>
            fail('statusReader should not be called for payments'),
        statusRequester: (_) async =>
            fail('statusRequester should not be called for payments'),
      );

      final status = await broker.check(MiniAppPermission.payments);

      expect(status, equals(PermissionStatus.notDetermined));
    });

    test('returns notDetermined for biometrics (handled by local_auth)',
        () async {
      final broker = DefaultPermissionBroker(
        statusReader: (_) async =>
            fail('statusReader should not be called for biometrics'),
        statusRequester: (_) async =>
            fail('statusRequester should not be called for biometrics'),
      );

      final status = await broker.check(MiniAppPermission.biometrics);

      expect(status, equals(PermissionStatus.notDetermined));
    });
  });

  group('DefaultPermissionBroker.request', () {
    test('returns granted immediately without prompting when already granted',
        () async {
      var requesterCalls = 0;
      final broker = DefaultPermissionBroker(
        statusReader: (_) async => ph.PermissionStatus.granted,
        statusRequester: (_) async {
          requesterCalls++;
          return ph.PermissionStatus.granted;
        },
      );

      final status = await broker.request(
        MiniAppPermission.camera,
        rationale: 'Scan QR codes',
      );

      expect(status, equals(PermissionStatus.granted));
      expect(requesterCalls, equals(0));
    });

    test('returns restricted without prompting when restricted', () async {
      var requesterCalls = 0;
      final broker = DefaultPermissionBroker(
        statusReader: (_) async => ph.PermissionStatus.restricted,
        statusRequester: (_) async {
          requesterCalls++;
          return ph.PermissionStatus.granted;
        },
      );

      final status = await broker.request(
        MiniAppPermission.camera,
        rationale: 'Scan QR codes',
      );

      expect(status, equals(PermissionStatus.restricted));
      expect(requesterCalls, equals(0));
    });

    test(
        'returns permanentlyDenied and delegates to presenter without '
        'prompting the OS', () async {
      final presenter = _MockPresenter();
      when(
        () => presenter.showPermanentlyDeniedRationale(any(), any()),
      ).thenAnswer((_) async {});

      var requesterCalls = 0;
      final broker = DefaultPermissionBroker(
        rationalePresenter: presenter,
        statusReader: (_) async => ph.PermissionStatus.permanentlyDenied,
        statusRequester: (_) async {
          requesterCalls++;
          return ph.PermissionStatus.granted;
        },
      );

      final status = await broker.request(
        MiniAppPermission.location,
        rationale: 'Show nearby drivers',
      );

      expect(status, equals(PermissionStatus.permanentlyDenied));
      expect(requesterCalls, equals(0));
      verify(
        () => presenter.showPermanentlyDeniedRationale(
          MiniAppPermission.location,
          'Show nearby drivers',
        ),
      ).called(1);
    });

    test('skips the OS request when the user dismisses the rationale',
        () async {
      final presenter = _MockPresenter();
      when(
        () => presenter.showRationaleForRequest(any(), any()),
      ).thenAnswer((_) async => false);

      var requesterCalls = 0;
      final broker = DefaultPermissionBroker(
        rationalePresenter: presenter,
        statusReader: (_) async => ph.PermissionStatus.denied,
        statusRequester: (_) async {
          requesterCalls++;
          return ph.PermissionStatus.granted;
        },
      );

      final status = await broker.request(
        MiniAppPermission.camera,
        rationale: 'Scan QR codes',
      );

      expect(status, equals(PermissionStatus.denied));
      expect(requesterCalls, equals(0));
      verify(
        () => presenter.showRationaleForRequest(
          MiniAppPermission.camera,
          'Scan QR codes',
        ),
      ).called(1);
    });

    test(
        'proceeds with the OS request and returns the mapped result when '
        'the user confirms the rationale', () async {
      final presenter = _MockPresenter();
      when(
        () => presenter.showRationaleForRequest(any(), any()),
      ).thenAnswer((_) async => true);

      var requesterCalls = 0;
      final broker = DefaultPermissionBroker(
        rationalePresenter: presenter,
        statusReader: (_) async => ph.PermissionStatus.denied,
        statusRequester: (_) async {
          requesterCalls++;
          return ph.PermissionStatus.granted;
        },
      );

      final status = await broker.request(
        MiniAppPermission.camera,
        rationale: 'Scan QR codes',
      );

      expect(status, equals(PermissionStatus.granted));
      expect(requesterCalls, equals(1));
    });

    test(
        'issues the OS request without presenter interaction when none is '
        'wired', () async {
      var requesterCalls = 0;
      final broker = DefaultPermissionBroker(
        statusReader: (_) async => ph.PermissionStatus.denied,
        statusRequester: (_) async {
          requesterCalls++;
          return ph.PermissionStatus.granted;
        },
      );

      final status = await broker.request(
        MiniAppPermission.camera,
        rationale: 'Scan QR codes',
      );

      expect(status, equals(PermissionStatus.granted));
      expect(requesterCalls, equals(1));
    });

    test('returns notDetermined for payments without touching the plugin',
        () async {
      final broker = DefaultPermissionBroker(
        statusReader: (_) async =>
            fail('statusReader should not be called for payments'),
        statusRequester: (_) async =>
            fail('statusRequester should not be called for payments'),
      );

      final status = await broker.request(
        MiniAppPermission.payments,
        rationale: 'Pay for ride',
      );

      expect(status, equals(PermissionStatus.notDetermined));
    });

    test('returns notDetermined for biometrics without touching the plugin',
        () async {
      final broker = DefaultPermissionBroker(
        statusReader: (_) async =>
            fail('statusReader should not be called for biometrics'),
        statusRequester: (_) async =>
            fail('statusRequester should not be called for biometrics'),
      );

      final status = await broker.request(
        MiniAppPermission.biometrics,
        rationale: 'Authenticate',
      );

      expect(status, equals(PermissionStatus.notDetermined));
    });

    test('treats limited plugin status as granted on the SDK boundary',
        () async {
      final broker = DefaultPermissionBroker(
        statusReader: (_) async => ph.PermissionStatus.denied,
        statusRequester: (_) async => ph.PermissionStatus.limited,
      );

      final status = await broker.request(
        MiniAppPermission.photos,
        rationale: 'Select receipt photo',
      );

      expect(status, equals(PermissionStatus.granted));
    });
  });

  // Ensure the Fake is registered so mocktail's any() matchers can be used
  // when extending these tests with custom plugin types.
  group('Fakes', () {
    setUpAll(() {
      registerFallbackValue(_FakePermission());
    });

    test('registration does not explode', () {
      expect(_FakePermission(), isA<ph.Permission>());
    });
  });
}
