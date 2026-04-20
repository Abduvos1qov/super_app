import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'token_storage.g.dart';

/// Minimal contract for storing the auth bearer token. Secure-storage
/// implementation lands in a follow-up; for now a process-local fallback
/// lets the skeleton compile and tests inject their own.
abstract class TokenStorage {
  Future<String?> read();
  Future<void> write(String token);
  Future<void> clear();
}

class InMemoryTokenStorage implements TokenStorage {
  String? _token;

  @override
  Future<String?> read() async => _token;

  @override
  Future<void> write(String token) async => _token = token;

  @override
  Future<void> clear() async => _token = null;
}

@Riverpod(keepAlive: true)
TokenStorage tokenStorage(Ref ref) => InMemoryTokenStorage();
