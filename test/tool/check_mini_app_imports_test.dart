import 'dart:io';

import 'package:test/test.dart';

import '../../tool/check_mini_app_imports.dart';

/// Each scenario builds a throwaway repo skeleton under [Directory.systemTemp]
/// and asserts what `analyzeMiniApps` reports. Nothing touches the real
/// monorepo packages — that way these tests are deterministic and do not
/// break when `packages/mini_apps/` gains new entries.
void main() {
  late Directory workDir;

  setUp(() {
    workDir = Directory.systemTemp.createTempSync('mini_app_imports_test_');
  });

  tearDown(() {
    if (workDir.existsSync()) {
      workDir.deleteSync(recursive: true);
    }
  });

  group('analyzeMiniApps', () {
    test('returns clean report for a well-formed mini-app', () {
      _writeMiniApp(
        rootDir: workDir.path,
        name: 'good_mini_app',
        pubspec: _validPubspec('good_mini_app'),
        sources: {
          'lib/good_mini_app.dart': '''
import 'package:core/core.dart';
import 'package:mini_app_sdk/mini_app_sdk.dart';
import 'package:shared_ui/shared_ui.dart';
import 'package:flutter/material.dart';
''',
          'lib/src/home.dart': '''
import 'package:good_mini_app/good_mini_app.dart';
import 'package:flutter/widgets.dart';
''',
        },
      );

      final report = analyzeMiniApps(workDir.path);

      expect(report.scannedPackages, equals(<String>['good_mini_app']));
      expect(report.violations, isEmpty);
      expect(report.isClean, isTrue);
    });

    test('detects a banned internal import inside a dart file', () {
      _writeMiniApp(
        rootDir: workDir.path,
        name: 'bad_internal_mini_app',
        pubspec: _validPubspec('bad_internal_mini_app'),
        sources: {
          'lib/src/home.dart': '''
import 'package:core/core.dart';
import 'package:auth/auth.dart'; // forbidden
''',
        },
      );

      final report = analyzeMiniApps(workDir.path);

      expect(report.violations, hasLength(1));
      final v = report.violations.single;
      expect(v.offendingPackage, 'auth');
      expect(v.kind, ImportViolationKind.dartImport);
      expect(v.line, 2);
      expect(v.file, endsWith('lib/src/home.dart'));
      expect(
        v.format(),
        contains(
          "imports 'package:auth/...' which is a platform-service package",
        ),
      );
    });

    test('detects a banned third-party vendor SDK import', () {
      _writeMiniApp(
        rootDir: workDir.path,
        name: 'bad_vendor_mini_app',
        pubspec: _validPubspec('bad_vendor_mini_app'),
        sources: {
          'lib/src/client.dart': '''
import 'package:dio/dio.dart';
''',
        },
      );

      final report = analyzeMiniApps(workDir.path);

      expect(report.violations, hasLength(1));
      final v = report.violations.single;
      expect(v.offendingPackage, 'dio');
      expect(v.kind, ImportViolationKind.dartImport);
      expect(v.reason, contains('vendor SDK'));
    });

    test('detects a banned dependency declared in pubspec.yaml', () {
      _writeMiniApp(
        rootDir: workDir.path,
        name: 'bad_pubspec_mini_app',
        pubspec: '''
name: bad_pubspec_mini_app
publish_to: none
version: 0.1.0
resolution: workspace

environment:
  sdk: ^3.6.0
  flutter: ">=3.27.0"

dependencies:
  core: any
  flutter:
    sdk: flutter
  mini_app_sdk: any
  shared_ui: any
  payments: any         # forbidden
  permission_handler: ^11.0.0  # also forbidden

dev_dependencies:
  flutter_test:
    sdk: flutter
''',
        sources: {
          'lib/bad_pubspec_mini_app.dart': '''
import 'package:core/core.dart';
''',
        },
      );

      final report = analyzeMiniApps(workDir.path);

      final pubspecViolations = report.violations.where(
        (v) => v.kind == ImportViolationKind.pubspec,
      );
      final offenders =
          pubspecViolations.map((v) => v.offendingPackage).toSet();

      expect(
        offenders,
        containsAll(<String>{'payments', 'permission_handler'}),
      );
      // no false positives on allowed deps
      expect(offenders, isNot(contains('core')));
      expect(offenders, isNot(contains('mini_app_sdk')));
      expect(offenders, isNot(contains('shared_ui')));
    });

    test('ignores generated files (*.g.dart, *.freezed.dart)', () {
      _writeMiniApp(
        rootDir: workDir.path,
        name: 'gen_mini_app',
        pubspec: _validPubspec('gen_mini_app'),
        sources: {
          // Pretend build_runner produced a file that happens to import a
          // banned package — we should NOT flag it, because authors don't
          // write these files by hand.
          'lib/src/model.freezed.dart': '''
import 'package:auth/auth.dart';
''',
          'lib/src/home.dart': '''
import 'package:core/core.dart';
''',
        },
      );

      final report = analyzeMiniApps(workDir.path);

      expect(report.violations, isEmpty);
    });

    test('returns empty report when packages/mini_apps does not exist', () {
      // Fresh temp dir; no packages/mini_apps subtree.
      final report = analyzeMiniApps(workDir.path);
      expect(report.scannedPackages, isEmpty);
      expect(report.violations, isEmpty);
    });

    test('flags unknown internal packages not on the allow-list', () {
      _writeMiniApp(
        rootDir: workDir.path,
        name: 'future_service_mini_app',
        pubspec: _validPubspec('future_service_mini_app'),
        sources: {
          // Pretend someone added a brand-new platform service named
          // `maps_gateway` that hasn't been added to the banned list.
          'lib/src/home.dart': '''
import 'package:maps_gateway/maps_gateway.dart';
''',
        },
      );

      final report = analyzeMiniApps(workDir.path);

      expect(report.violations, hasLength(1));
      expect(report.violations.single.offendingPackage, 'maps_gateway');
    });
  });
}

// ---------------------------------------------------------------------------
// Test helpers
// ---------------------------------------------------------------------------

/// A minimal, valid mini-app pubspec — used as the baseline for most tests.
String _validPubspec(String name) => '''
name: $name
publish_to: none
version: 0.1.0
resolution: workspace

environment:
  sdk: ^3.6.0
  flutter: ">=3.27.0"

dependencies:
  core: any
  flutter:
    sdk: flutter
  meta: ^1.15.0
  mini_app_sdk: any
  shared_models: any
  shared_ui: any

dev_dependencies:
  flutter_test:
    sdk: flutter
''';

void _writeMiniApp({
  required String rootDir,
  required String name,
  required String pubspec,
  required Map<String, String> sources,
}) {
  final pkgPath = '$rootDir/packages/mini_apps/$name';
  Directory(pkgPath).createSync(recursive: true);
  File('$pkgPath/pubspec.yaml').writeAsStringSync(pubspec);

  sources.forEach((relative, contents) {
    final file = File('$pkgPath/$relative');
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(contents);
  });
}
