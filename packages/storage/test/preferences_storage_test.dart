import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:storage/storage.dart';

void main() {
  group('InMemoryPreferencesStorage', () {
    late InMemoryPreferencesStorage sut;

    setUp(() {
      sut = InMemoryPreferencesStorage();
    });

    group('String', () {
      test('round-trips a value', () async {
        await sut.writeString('name', 'Abdulbosit');
        final result = await sut.readString('name');
        expect(result.valueOrThrow, equals('Abdulbosit'));
      });

      test('returns null for absent key', () async {
        final result = await sut.readString('missing');
        expect(result.valueOrThrow, isNull);
      });

      test('reading a non-string value as string yields ValidationError', () async {
        await sut.writeInt('count', 42);
        final result = await sut.readString('count');
        expect(result, isA<Err<String?, AppError>>());
        expect((result as Err<String?, AppError>).error, isA<ValidationError>());
      });
    });

    group('bool', () {
      test('round-trips true and false', () async {
        await sut.writeBool('flag', true);
        expect((await sut.readBool('flag')).valueOrThrow, isTrue);
        await sut.writeBool('flag', false);
        expect((await sut.readBool('flag')).valueOrThrow, isFalse);
      });
    });

    group('int', () {
      test('round-trips a value', () async {
        await sut.writeInt('count', 7);
        expect((await sut.readInt('count')).valueOrThrow, equals(7));
      });
    });

    group('double', () {
      test('round-trips a value', () async {
        await sut.writeDouble('ratio', 3.14);
        expect((await sut.readDouble('ratio')).valueOrThrow, closeTo(3.14, 1e-9));
      });
    });

    group('StringList', () {
      test('round-trips a list', () async {
        await sut.writeStringList('tags', const ['a', 'b', 'c']);
        final result = await sut.readStringList('tags');
        expect(result.valueOrThrow, equals(['a', 'b', 'c']));
      });

      test('returns null for absent key', () async {
        final result = await sut.readStringList('missing');
        expect(result.valueOrThrow, isNull);
      });
    });

    group('JSON', () {
      test('round-trips a map', () async {
        const payload = <String, Object?>{'id': 'u-1', 'age': 29, 'active': true};
        await sut.writeJson('user', payload);
        final result = await sut.readJson('user');
        expect(result.valueOrThrow, equals(payload));
      });

      test('returns null for absent key', () async {
        final result = await sut.readJson('missing');
        expect(result.valueOrThrow, isNull);
      });

      test('malformed JSON string yields ValidationError', () async {
        await sut.writeString('user', '{not-json');
        final result = await sut.readJson('user');
        expect(result, isA<Err<Map<String, Object?>?, AppError>>());
        expect(
          (result as Err<Map<String, Object?>?, AppError>).error,
          isA<ValidationError>(),
        );
      });

      test('wrong-type stored value yields ValidationError', () async {
        await sut.writeInt('user', 1);
        final result = await sut.readJson('user');
        expect(result, isA<Err<Map<String, Object?>?, AppError>>());
      });
    });

    test('delete removes a single key', () async {
      await sut.writeString('a', '1');
      await sut.writeString('b', '2');
      await sut.delete('a');
      expect((await sut.readString('a')).valueOrThrow, isNull);
      expect((await sut.readString('b')).valueOrThrow, equals('2'));
    });

    test('clear removes every key', () async {
      await sut.writeString('a', '1');
      await sut.writeInt('b', 2);
      await sut.clear();
      expect(sut.snapshot, isEmpty);
    });

    test('keys reflects all stored keys', () async {
      await sut.writeString('x', '1');
      await sut.writeString('y', '2');
      final keys = (await sut.keys()).valueOrThrow;
      expect(keys, containsAll(<String>['x', 'y']));
    });
  });
}
