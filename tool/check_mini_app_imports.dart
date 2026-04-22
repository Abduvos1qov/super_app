// A pure Dart CLI (and reusable library) that enforces the mini-app
// import graph described in `CLAUDE.md` and `ARCHITECTURE.md`.
//
// Mini-app packages (under `packages/mini_apps/`) may depend on:
//   - `core`, `shared_models`, `shared_ui`, `mini_app_sdk`
//   - Flutter + generic third-party packages (freezed, meta, intl, ...)
//
// They MUST NOT depend on any platform service package (auth, networking,
// payments, storage, analytics, feature_flags, notifications, deep_links,
// permissions, event_bus, mini_app_registry) nor on vendor SDKs that belong
// behind those services (dio, flutter_secure_storage, permission_handler, ...).
//
// Usage (from repo root):
//   dart run tool/check_mini_app_imports.dart
//
// Exit codes:
//   0 — clean
//   1 — at least one violation was reported
//   2 — configuration problem (e.g. root dir missing)
//
// The public function [analyzeMiniApps] is intended for unit tests.

import 'dart:async';
import 'dart:io';

/// Internal package names that a mini-app is allowed to depend on.
const Set<String> kAllowedInternalDeps = <String>{
  'core',
  'shared_models',
  'shared_ui',
  'mini_app_sdk',
};

/// Third-party packages that MUST NOT appear inside a mini-app. These belong
/// behind a platform-service abstraction (see `mini_app_sdk`).
const Set<String> kBannedThirdParty = <String>{
  'dio',
  'http',
  'flutter_secure_storage',
  'shared_preferences',
  'permission_handler',
  'firebase_messaging',
  'firebase_remote_config',
  'firebase_analytics',
  'geolocator',
  'app_links',
  'uni_links',
};

/// Known internal packages that are NOT in the allow-list. Importing any of
/// these from a mini-app is always a violation.
///
/// Kept explicit (rather than "everything not in the allow-list") so the error
/// message can be unambiguous even when a typo is involved.
const Set<String> kBannedInternalDeps = <String>{
  'analytics',
  'auth',
  'deep_links',
  'event_bus',
  'feature_flags',
  'mini_app_registry',
  'networking',
  'notifications',
  'payments',
  'permissions',
  'storage',
};

/// A single violation discovered in a mini-app package.
class ImportViolation {
  const ImportViolation({
    required this.packageName,
    required this.file,
    required this.line,
    required this.offendingPackage,
    required this.reason,
    required this.kind,
  });

  /// The mini-app that contains the violation, e.g. `demo_mini_app`.
  final String packageName;

  /// Absolute or repo-relative path of the file where the violation lives.
  /// For `pubspec.yaml` violations this points at the pubspec itself.
  final String file;

  /// 1-based line number; `0` when not applicable (e.g. pubspec entry without
  /// a recoverable line — currently always resolved).
  final int line;

  /// The disallowed package name (e.g. `auth`, `dio`).
  final String offendingPackage;

  /// Why this import is forbidden.
  final String reason;

  /// Distinguishes dart-import violations from pubspec-dependency violations.
  final ImportViolationKind kind;

  /// Formats the violation for stderr. Matches the spec in the task brief.
  String format() {
    final buffer = StringBuffer('[ERROR] $file')
      ..write(line > 0 ? ':$line' : '')
      ..write('\n  ')
      ..write(reason)
      ..write('\n  Allowed internal deps: ')
      ..write(kAllowedInternalDeps.join(', '))
      ..write('.')
      ..write('\n  Access platform services through MiniAppContext instead.');
    return buffer.toString();
  }
}

/// Whether a violation was found in a pubspec or in a `.dart` file.
enum ImportViolationKind { pubspec, dartImport }

/// Aggregated result of a scan.
class ImportGraphReport {
  ImportGraphReport({
    required this.scannedPackages,
    required this.violations,
  });

  final List<String> scannedPackages;
  final List<ImportViolation> violations;

  bool get isClean => violations.isEmpty;
}

/// Scans every package beneath `<rootDir>/packages/mini_apps/` and returns
/// a report describing the violations (if any).
///
/// - [rootDir] must point at a super-app monorepo root (i.e. it must contain
///   a `packages/mini_apps/` directory).
/// - Returns an empty violation list when there are no mini-apps to scan.
ImportGraphReport analyzeMiniApps(String rootDir) {
  final miniAppsDir = Directory('$rootDir/packages/mini_apps');
  if (!miniAppsDir.existsSync()) {
    return ImportGraphReport(scannedPackages: const [], violations: const []);
  }

  final violations = <ImportViolation>[];
  final scanned = <String>[];

  for (final entity in miniAppsDir.listSync()) {
    if (entity is! Directory) continue;
    final pubspec = File('${entity.path}/pubspec.yaml');
    if (!pubspec.existsSync()) continue;

    final packageName = _readPackageName(pubspec) ?? _basename(entity.path);
    scanned.add(packageName);

    violations.addAll(_checkPubspec(pubspec, packageName));

    final libDir = Directory('${entity.path}/lib');
    if (libDir.existsSync()) {
      violations.addAll(_checkDartSources(libDir, packageName));
    }
  }

  scanned.sort();
  return ImportGraphReport(scannedPackages: scanned, violations: violations);
}

/// Parses the dependency section of a pubspec.yaml with a minimal regex-based
/// reader. We intentionally avoid adding `package:yaml` as a dependency just
/// for this tool.
List<ImportViolation> _checkPubspec(File pubspec, String packageName) {
  final lines = pubspec.readAsLinesSync();
  final violations = <ImportViolation>[];

  var inDependencies = false;
  for (var i = 0; i < lines.length; i++) {
    final raw = lines[i];
    final stripped = raw.trimRight();

    if (stripped.isEmpty || stripped.trimLeft().startsWith('#')) continue;

    // A top-level key starts at column 0 and ends with ':'.
    if (!stripped.startsWith(' ') && !stripped.startsWith('\t')) {
      inDependencies = stripped == 'dependencies:';
      continue;
    }

    if (!inDependencies) continue;

    // Dependency entries look like `  package_name:` (2-space indent) and may
    // optionally inline a constraint (`  package_name: ^1.2.3`).
    final match = RegExp(r'^\s{2}([a-zA-Z_][a-zA-Z0-9_]*)\s*:').firstMatch(raw);
    if (match == null) continue;

    final dep = match.group(1);
    if (dep == null) continue;
    if (dep == 'flutter' || dep == 'flutter_localizations') continue;
    if (dep == packageName) continue; // self-reference, ignored

    final lineNumber = i + 1;

    if (kBannedInternalDeps.contains(dep)) {
      violations.add(
        ImportViolation(
          packageName: packageName,
          file: pubspec.path,
          line: lineNumber,
          offendingPackage: dep,
          kind: ImportViolationKind.pubspec,
          reason: "declares dependency on '$dep' which is a platform-service "
              'package and must not appear in a mini-app pubspec.',
        ),
      );
      continue;
    }

    if (kBannedThirdParty.contains(dep)) {
      violations.add(
        ImportViolation(
          packageName: packageName,
          file: pubspec.path,
          line: lineNumber,
          offendingPackage: dep,
          kind: ImportViolationKind.pubspec,
          reason: "declares dependency on '$dep' which is a vendor SDK "
              'reserved for platform-service packages.',
        ),
      );
      continue;
    }

    // Any other internal package (i.e. a package from this workspace that is
    // neither whitelisted nor flagged above) is also rejected, to future-proof
    // the check as new services are added.
    if (_looksInternal(dep) && !kAllowedInternalDeps.contains(dep)) {
      violations.add(
        ImportViolation(
          packageName: packageName,
          file: pubspec.path,
          line: lineNumber,
          offendingPackage: dep,
          kind: ImportViolationKind.pubspec,
          reason: "declares dependency on '$dep' which is not in the mini-app "
              'dependency allow-list.',
        ),
      );
    }
  }

  return violations;
}

List<ImportViolation> _checkDartSources(Directory libDir, String packageName) {
  final violations = <ImportViolation>[];
  final importRegex = RegExp(
    r'''^\s*import\s+['"]package:([a-zA-Z_][a-zA-Z0-9_]*)/''',
  );

  for (final entity in libDir.listSync(recursive: true, followLinks: false)) {
    if (entity is! File) continue;
    if (!entity.path.endsWith('.dart')) continue;
    // Skip generated files — they are not hand-written and their imports are
    // authored by codegen, not by mini-app authors.
    final basename = _basename(entity.path);
    if (basename.endsWith('.g.dart') ||
        basename.endsWith('.freezed.dart') ||
        basename.endsWith('.gr.dart')) {
      continue;
    }

    final lines = entity.readAsLinesSync();
    for (var i = 0; i < lines.length; i++) {
      final match = importRegex.firstMatch(lines[i]);
      if (match == null) continue;
      final importedPackage = match.group(1);
      if (importedPackage == null) continue;
      if (importedPackage == packageName) continue; // self-import is fine
      if (kAllowedInternalDeps.contains(importedPackage)) continue;
      if (_isFlutterOrDartSdk(importedPackage)) continue;
      if (_isNeutralThirdParty(importedPackage)) continue;

      final lineNumber = i + 1;

      if (kBannedInternalDeps.contains(importedPackage)) {
        violations.add(
          ImportViolation(
            packageName: packageName,
            file: entity.path,
            line: lineNumber,
            offendingPackage: importedPackage,
            kind: ImportViolationKind.dartImport,
            reason: "imports 'package:$importedPackage/...' which is a "
                'platform-service package and is not allowed in mini-apps.',
          ),
        );
        continue;
      }

      if (kBannedThirdParty.contains(importedPackage)) {
        violations.add(
          ImportViolation(
            packageName: packageName,
            file: entity.path,
            line: lineNumber,
            offendingPackage: importedPackage,
            kind: ImportViolationKind.dartImport,
            reason: "imports 'package:$importedPackage/...' which is a vendor "
                'SDK reserved for platform-service packages.',
          ),
        );
        continue;
      }

      if (_looksInternal(importedPackage)) {
        violations.add(
          ImportViolation(
            packageName: packageName,
            file: entity.path,
            line: lineNumber,
            offendingPackage: importedPackage,
            kind: ImportViolationKind.dartImport,
            reason: "imports 'package:$importedPackage/...' which is not on "
                'the mini-app allow-list.',
          ),
        );
      }
    }
  }

  return violations;
}

String? _readPackageName(File pubspec) {
  final match = RegExp(r'^name:\s*([a-zA-Z_][a-zA-Z0-9_]*)\s*$', multiLine: true)
      .firstMatch(pubspec.readAsStringSync());
  return match?.group(1);
}

bool _isFlutterOrDartSdk(String pkg) {
  return pkg == 'flutter' ||
      pkg == 'flutter_test' ||
      pkg == 'flutter_localizations' ||
      pkg == 'flutter_web_plugins' ||
      pkg == 'sky_engine';
}

/// A very small curated list of "obviously neutral" third-party deps that
/// mini-apps commonly use. Anything not listed here and not Flutter is treated
/// as internal-looking (and hence rejected unless whitelisted) — but only when
/// the package name matches our "internal-looking" heuristic below.
bool _isNeutralThirdParty(String pkg) {
  const neutral = <String>{
    'meta',
    'collection',
    'equatable',
    'freezed_annotation',
    'json_annotation',
    'intl',
    'path',
    'logging',
  };
  return neutral.contains(pkg);
}

/// Crude heuristic: a package whose name contains no dot / slash / dash and is
/// not a well-known neutral third-party is treated as "possibly internal".
/// Combined with the explicit allow-list above, this catches both known
/// platform-service packages and future ones that haven't been added to the
/// banned set yet.
bool _looksInternal(String pkg) {
  if (_isFlutterOrDartSdk(pkg)) return false;
  if (_isNeutralThirdParty(pkg)) return false;
  // pub.dev packages sometimes use underscores too, so this is not definitive,
  // but combined with the explicit allow-list it is enough to catch local
  // monorepo packages.
  return !pkg.contains('.');
}

String _basename(String path) {
  final idx = path.lastIndexOf('/');
  return idx == -1 ? path : path.substring(idx + 1);
}

/// CLI entry point.
Future<void> main(List<String> args) async {
  final rootDir = args.isNotEmpty ? args.first : Directory.current.path;
  final miniAppsDir = Directory('$rootDir/packages/mini_apps');
  if (!miniAppsDir.existsSync()) {
    stderr.writeln(
      '[FATAL] Mini-apps directory not found: ${miniAppsDir.path}\n'
      '  Run this from the repo root or pass the root as the first argument.',
    );
    exitCode = 2;
    return;
  }

  final report = analyzeMiniApps(rootDir);

  if (report.isClean) {
    stdout.writeln(
      '✓ Mini-app import graph clean '
      '(${report.scannedPackages.length} mini-app(s) checked: '
      '${report.scannedPackages.join(', ')})',
    );
    exitCode = 0;
    return;
  }

  for (final v in report.violations) {
    stderr.writeln(v.format());
  }
  stderr.writeln(
    '\n${report.violations.length} violation(s) across '
    '${report.scannedPackages.length} mini-app(s).',
  );
  exitCode = 1;
}
