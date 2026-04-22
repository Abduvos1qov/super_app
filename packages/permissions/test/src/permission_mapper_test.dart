import 'package:flutter_test/flutter_test.dart';
import 'package:mini_app_sdk/mini_app_sdk.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:permissions/permissions.dart';

void main() {
  group('PermissionMapper.toPlugin', () {
    test('maps location to plugin.location', () {
      expect(
        PermissionMapper.toPlugin(MiniAppPermission.location),
        equals(ph.Permission.location),
      );
    });

    test('maps locationBackground to plugin.locationAlways', () {
      expect(
        PermissionMapper.toPlugin(MiniAppPermission.locationBackground),
        equals(ph.Permission.locationAlways),
      );
    });

    test('maps camera to plugin.camera', () {
      expect(
        PermissionMapper.toPlugin(MiniAppPermission.camera),
        equals(ph.Permission.camera),
      );
    });

    test('maps microphone to plugin.microphone', () {
      expect(
        PermissionMapper.toPlugin(MiniAppPermission.microphone),
        equals(ph.Permission.microphone),
      );
    });

    test('maps contacts to plugin.contacts', () {
      expect(
        PermissionMapper.toPlugin(MiniAppPermission.contacts),
        equals(ph.Permission.contacts),
      );
    });

    test('maps photos to plugin.photos', () {
      expect(
        PermissionMapper.toPlugin(MiniAppPermission.photos),
        equals(ph.Permission.photos),
      );
    });

    test('maps storage to plugin.storage', () {
      expect(
        PermissionMapper.toPlugin(MiniAppPermission.storage),
        equals(ph.Permission.storage),
      );
    });

    test('maps notifications to plugin.notification', () {
      expect(
        PermissionMapper.toPlugin(MiniAppPermission.notifications),
        equals(ph.Permission.notification),
      );
    });

    test('maps calendar to plugin.calendarFullAccess', () {
      expect(
        PermissionMapper.toPlugin(MiniAppPermission.calendar),
        equals(ph.Permission.calendarFullAccess),
      );
    });

    test('maps bluetooth to plugin.bluetooth', () {
      expect(
        PermissionMapper.toPlugin(MiniAppPermission.bluetooth),
        equals(ph.Permission.bluetooth),
      );
    });

    test('throws UnsupportedError for payments (app-level gate)', () {
      expect(
        () => PermissionMapper.toPlugin(MiniAppPermission.payments),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('throws UnsupportedError for biometrics (handled by local_auth)', () {
      expect(
        () => PermissionMapper.toPlugin(MiniAppPermission.biometrics),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('covers every MiniAppPermission except app-level gates', () {
      const appLevel = <MiniAppPermission>{
        MiniAppPermission.payments,
        MiniAppPermission.biometrics,
      };
      for (final permission in MiniAppPermission.values) {
        if (appLevel.contains(permission)) continue;
        expect(
          () => PermissionMapper.toPlugin(permission),
          returnsNormally,
          reason: 'toPlugin should support $permission',
        );
      }
    });
  });

  group('PermissionMapper.fromPlugin', () {
    test('maps granted to granted', () {
      expect(
        PermissionMapper.fromPlugin(ph.PermissionStatus.granted),
        equals(PermissionStatus.granted),
      );
    });

    test('maps denied to denied', () {
      expect(
        PermissionMapper.fromPlugin(ph.PermissionStatus.denied),
        equals(PermissionStatus.denied),
      );
    });

    test('maps restricted to restricted', () {
      expect(
        PermissionMapper.fromPlugin(ph.PermissionStatus.restricted),
        equals(PermissionStatus.restricted),
      );
    });

    test('treats limited as granted (iOS selected-photos)', () {
      expect(
        PermissionMapper.fromPlugin(ph.PermissionStatus.limited),
        equals(PermissionStatus.granted),
      );
    });

    test('maps permanentlyDenied to permanentlyDenied', () {
      expect(
        PermissionMapper.fromPlugin(ph.PermissionStatus.permanentlyDenied),
        equals(PermissionStatus.permanentlyDenied),
      );
    });

    test('treats provisional as granted (iOS notifications)', () {
      expect(
        PermissionMapper.fromPlugin(ph.PermissionStatus.provisional),
        equals(PermissionStatus.granted),
      );
    });

    test('covers every plugin PermissionStatus value', () {
      for (final status in ph.PermissionStatus.values) {
        expect(
          () => PermissionMapper.fromPlugin(status),
          returnsNormally,
          reason: 'fromPlugin should handle $status',
        );
      }
    });
  });
}
