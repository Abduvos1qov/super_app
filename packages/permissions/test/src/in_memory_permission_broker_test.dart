import 'package:flutter_test/flutter_test.dart';
import 'package:mini_app_sdk/mini_app_sdk.dart';
import 'package:permissions/permissions.dart';

void main() {
  group('InMemoryPermissionBroker', () {
    late InMemoryPermissionBroker sut;

    setUp(() {
      sut = InMemoryPermissionBroker();
    });

    group('check', () {
      test('returns notDetermined when no status has been set', () async {
        final status = await sut.check(MiniAppPermission.camera);
        expect(status, equals(PermissionStatus.notDetermined));
      });

      test('returns the configured status', () async {
        sut.setStatus(MiniAppPermission.camera, PermissionStatus.granted);
        final status = await sut.check(MiniAppPermission.camera);
        expect(status, equals(PermissionStatus.granted));
      });

      test('reports distinct statuses per permission', () async {
        sut
          ..setStatus(MiniAppPermission.camera, PermissionStatus.granted)
          ..setStatus(MiniAppPermission.location, PermissionStatus.denied);

        expect(
          await sut.check(MiniAppPermission.camera),
          equals(PermissionStatus.granted),
        );
        expect(
          await sut.check(MiniAppPermission.location),
          equals(PermissionStatus.denied),
        );
      });
    });

    group('request', () {
      test('defaults to granted when no response has been configured',
          () async {
        final status = await sut.request(
          MiniAppPermission.camera,
          rationale: 'Scan QR codes',
        );
        expect(status, equals(PermissionStatus.granted));
      });

      test('returns the configured response', () async {
        sut.setRequestResponse(
          MiniAppPermission.location,
          PermissionStatus.denied,
        );
        final status = await sut.request(
          MiniAppPermission.location,
          rationale: 'Show nearby drivers',
        );
        expect(status, equals(PermissionStatus.denied));
      });

      test('updates the cached status so subsequent check reflects it',
          () async {
        sut.setRequestResponse(
          MiniAppPermission.microphone,
          PermissionStatus.permanentlyDenied,
        );

        await sut.request(
          MiniAppPermission.microphone,
          rationale: 'Record voice notes',
        );

        expect(
          await sut.check(MiniAppPermission.microphone),
          equals(PermissionStatus.permanentlyDenied),
        );
      });

      test('logs every invocation with its rationale in order', () async {
        await sut.request(
          MiniAppPermission.camera,
          rationale: 'Scan QR codes',
        );
        await sut.request(
          MiniAppPermission.location,
          rationale: 'Find drivers',
        );

        expect(sut.requestLog, hasLength(2));
        expect(
          sut.requestLog,
          equals(const <PermissionRequestLogEntry>[
            PermissionRequestLogEntry(
              MiniAppPermission.camera,
              'Scan QR codes',
            ),
            PermissionRequestLogEntry(
              MiniAppPermission.location,
              'Find drivers',
            ),
          ]),
        );
      });

      test('requestLog is unmodifiable', () async {
        await sut.request(
          MiniAppPermission.camera,
          rationale: 'Scan QR codes',
        );

        expect(
          () => sut.requestLog.add(
            const PermissionRequestLogEntry(
              MiniAppPermission.photos,
              'x',
            ),
          ),
          throwsA(isA<UnsupportedError>()),
        );
      });
    });

    group('reset', () {
      test('clears statuses, responses and the request log', () async {
        sut
          ..setStatus(MiniAppPermission.camera, PermissionStatus.granted)
          ..setRequestResponse(
            MiniAppPermission.location,
            PermissionStatus.denied,
          );
        await sut.request(
          MiniAppPermission.camera,
          rationale: 'Scan',
        );

        sut.reset();

        expect(
          await sut.check(MiniAppPermission.camera),
          equals(PermissionStatus.notDetermined),
        );
        expect(sut.requestLog, isEmpty);
      });
    });
  });

  group('PermissionRequestLogEntry', () {
    test('equality is based on permission and rationale', () {
      const a = PermissionRequestLogEntry(
        MiniAppPermission.camera,
        'Scan QR codes',
      );
      const b = PermissionRequestLogEntry(
        MiniAppPermission.camera,
        'Scan QR codes',
      );
      const c = PermissionRequestLogEntry(
        MiniAppPermission.camera,
        'Different copy',
      );

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });
  });
}
