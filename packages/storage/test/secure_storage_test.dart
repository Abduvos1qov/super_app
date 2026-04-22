import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:storage/storage.dart';

void main() {
  group('InMemorySecureStorage', () {
    late InMemorySecureStorage sut;

    setUp(() {
      sut = InMemorySecureStorage();
    });

    test('read returns null when key is absent', () async {
      final result = await sut.read('missing');
      expect(result, isA<Ok<String?, AppError>>());
      expect(result.valueOrThrow, isNull);
    });

    test('write then read round-trips the value', () async {
      final writeResult = await sut.write('token', 'secret-xyz');
      expect(writeResult, isA<Ok<void, AppError>>());

      final readResult = await sut.read('token');
      expect(readResult.valueOrThrow, equals('secret-xyz'));
    });

    test('write overwrites an existing value', () async {
      await sut.write('token', 'first');
      await sut.write('token', 'second');
      final result = await sut.read('token');
      expect(result.valueOrThrow, equals('second'));
    });

    test('delete removes the value', () async {
      await sut.write('token', 'secret');
      await sut.delete('token');
      final result = await sut.read('token');
      expect(result.valueOrThrow, isNull);
    });

    test('delete on absent key is a no-op', () async {
      final result = await sut.delete('never-existed');
      expect(result, isA<Ok<void, AppError>>());
    });

    test('clear removes every key', () async {
      await sut.write('a', '1');
      await sut.write('b', '2');
      await sut.clear();
      expect(sut.snapshot, isEmpty);
    });
  });
}
