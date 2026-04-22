import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:storage/storage.dart';

class _User {
  const _User({required this.id, required this.name});

  factory _User.fromJson(Object? json) {
    if (json case final Map<String, Object?> map
        when map['id'] is String && map['name'] is String) {
      return _User(id: map['id']! as String, name: map['name']! as String);
    }
    throw const FormatException('not a _User');
  }

  final String id;
  final String name;

  Map<String, Object?> toJson() => <String, Object?>{'id': id, 'name': name};
}

void main() {
  group('ScopedStorage', () {
    late InMemoryPreferencesStorage backend;

    setUp(() {
      backend = InMemoryPreferencesStorage();
    });

    test('write then read round-trips a decoded value', () async {
      final scope = ScopedStorage(miniAppId: 'taxi', backend: backend);
      const user = _User(id: 'u-1', name: 'Abdulbosit');

      await scope.write('user', user.toJson());

      final result = await scope.read('user', decode: _User.fromJson);
      expect(result.valueOrThrow?.id, equals('u-1'));
      expect(result.valueOrThrow?.name, equals('Abdulbosit'));
    });

    test('read returns null when key is absent', () async {
      final scope = ScopedStorage(miniAppId: 'taxi', backend: backend);
      final result = await scope.read('missing', decode: (_) => 0);
      expect(result.valueOrThrow, isNull);
    });

    test('scopes are isolated: mini-app B cannot read A keys', () async {
      final a = ScopedStorage(miniAppId: 'taxi', backend: backend);
      final b = ScopedStorage(miniAppId: 'delivery', backend: backend);

      await a.write('x', 'value-a');

      final fromB = await b.read<String>('x', decode: (json) => json! as String);
      expect(fromB.valueOrThrow, isNull);

      final fromA = await a.read<String>('x', decode: (json) => json! as String);
      expect(fromA.valueOrThrow, equals('value-a'));
    });

    test('delete only removes key within the calling scope', () async {
      final a = ScopedStorage(miniAppId: 'taxi', backend: backend);
      final b = ScopedStorage(miniAppId: 'delivery', backend: backend);

      await a.write('x', 'va');
      await b.write('x', 'vb');

      await a.delete('x');

      expect((await a.read<String>('x', decode: (j) => j! as String)).valueOrThrow, isNull);
      expect((await b.read<String>('x', decode: (j) => j! as String)).valueOrThrow, equals('vb'));
    });

    test('clear only clears keys in the calling scope', () async {
      final a = ScopedStorage(miniAppId: 'taxi', backend: backend);
      final b = ScopedStorage(miniAppId: 'delivery', backend: backend);

      await a.write('x', 1);
      await a.write('y', 2);
      await b.write('x', 99);

      await a.clear();

      expect((await a.read<int>('x', decode: (j) => j! as int)).valueOrThrow, isNull);
      expect((await a.read<int>('y', decode: (j) => j! as int)).valueOrThrow, isNull);
      expect((await b.read<int>('x', decode: (j) => j! as int)).valueOrThrow, equals(99));
    });

    test('decode failure surfaces as ValidationError', () async {
      final scope = ScopedStorage(miniAppId: 'taxi', backend: backend);
      await scope.write('user', <String, Object?>{'wrong': true});

      final result = await scope.read('user', decode: _User.fromJson);
      expect(result, isA<Err<_User?, AppError>>());
      expect((result as Err<_User?, AppError>).error, isA<ValidationError>());
    });

    test('malformed JSON blob surfaces as ValidationError', () async {
      final scope = ScopedStorage(miniAppId: 'taxi', backend: backend);
      // Bypass scope to plant a malformed blob under the scoped key.
      await backend.writeString('taxi.user', '{not-json');

      final result = await scope.read('user', decode: _User.fromJson);
      expect(result, isA<Err<_User?, AppError>>());
      expect((result as Err<_User?, AppError>).error, isA<ValidationError>());
    });

    test('non-encodable value is rejected with ValidationError', () async {
      final scope = ScopedStorage(miniAppId: 'taxi', backend: backend);
      final result = await scope.write('bad', Object());
      expect(result, isA<Err<void, AppError>>());
      expect((result as Err<void, AppError>).error, isA<ValidationError>());
    });
  });

  group('ScopedSecureStorage', () {
    late InMemorySecureStorage backend;

    setUp(() {
      backend = InMemorySecureStorage();
    });

    test('write then read round-trips a decoded value', () async {
      final scope = ScopedSecureStorage(miniAppId: 'wallet', backend: backend);
      await scope.write('token', 'secret-xyz');
      final result = await scope.read<String>('token', decode: (j) => j! as String);
      expect(result.valueOrThrow, equals('secret-xyz'));
    });

    test('scopes are isolated across mini-apps', () async {
      final a = ScopedSecureStorage(miniAppId: 'wallet', backend: backend);
      final b = ScopedSecureStorage(miniAppId: 'taxi', backend: backend);

      await a.write('token', 'tok-a');
      final fromB = await b.read<String>('token', decode: (j) => j! as String);
      expect(fromB.valueOrThrow, isNull);
    });

    test('clear wipes only this scope', () async {
      final a = ScopedSecureStorage(miniAppId: 'wallet', backend: backend);
      final b = ScopedSecureStorage(miniAppId: 'taxi', backend: backend);

      await a.write('t1', 'a1');
      await a.write('t2', 'a2');
      await b.write('t1', 'b1');

      await a.clear();

      expect((await a.read<String>('t1', decode: (j) => j! as String)).valueOrThrow, isNull);
      expect((await a.read<String>('t2', decode: (j) => j! as String)).valueOrThrow, isNull);
      expect(
        (await b.read<String>('t1', decode: (j) => j! as String)).valueOrThrow,
        equals('b1'),
      );
    });

    test('delete drops the key from the scope index', () async {
      final scope = ScopedSecureStorage(miniAppId: 'wallet', backend: backend);
      await scope.write('t', 'v');
      await scope.delete('t');
      final result = await scope.read<String>('t', decode: (j) => j! as String);
      expect(result.valueOrThrow, isNull);
    });
  });
}
