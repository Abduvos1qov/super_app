import 'package:shared_models/shared_models.dart';
import 'package:test/test.dart';

void main() {
  group('User', () {
    group('defaults', () {
      test('assigns {consumer} as default role set', () {
        const user = User(
          id: 'u1',
          phone: '+998900000000',
          displayName: 'Demo',
        );
        expect(user.roles, equals(<AccountRole>{AccountRole.consumer}));
      });

      test('assigns KycLevel.none by default', () {
        const user = User(
          id: 'u1',
          phone: '+998900000000',
          displayName: 'Demo',
        );
        expect(user.kycLevel, equals(KycLevel.none));
      });

      test('assigns isActive false by default', () {
        const user = User(
          id: 'u1',
          phone: '+998900000000',
          displayName: 'Demo',
        );
        expect(user.isActive, isFalse);
      });
    });

    group('JSON round-trip', () {
      test('survives serialization with all fields populated', () {
        const user = User(
          id: 'u1',
          phone: '+998900000000',
          displayName: 'Demo User',
          email: 'demo@example.test',
          avatarUrl: 'https://example.test/a.png',
          roles: <AccountRole>{AccountRole.consumer, AccountRole.operator},
          kycLevel: KycLevel.verified,
          isActive: true,
        );
        final decoded = User.fromJson(user.toJson());
        expect(decoded, equals(user));
      });

      test('survives serialization with only required fields', () {
        const user = User(
          id: 'u2',
          phone: '+998911111111',
          displayName: 'Minimal',
        );
        final decoded = User.fromJson(user.toJson());
        expect(decoded, equals(user));
      });
    });

    group('backend forward-compatibility', () {
      test('decodes an unknown role to AccountRole.unknown', () {
        final decoded = User.fromJson(<String, dynamic>{
          'id': 'u3',
          'phone': '+998922222222',
          'display_name': 'Future Role',
          'roles': <String>['consumer', 'galactic_pilot'],
          'kyc_level': 'basic',
          'is_active': true,
        });
        expect(
          decoded.roles,
          equals(<AccountRole>{AccountRole.consumer, AccountRole.unknown}),
        );
      });

      test('decodes an unknown kycLevel to KycLevel.unknown', () {
        final decoded = User.fromJson(<String, dynamic>{
          'id': 'u4',
          'phone': '+998933333333',
          'display_name': 'Future KYC',
          'roles': <String>['consumer'],
          'kyc_level': 'quantum_verified',
          'is_active': false,
        });
        expect(decoded.kycLevel, equals(KycLevel.unknown));
      });
    });

    group('copyWith', () {
      test('updates a single field without mutating the rest', () {
        const original = User(
          id: 'u5',
          phone: '+998944444444',
          displayName: 'Original',
          kycLevel: KycLevel.basic,
        );
        final updated = original.copyWith(displayName: 'Updated');
        expect(updated.displayName, equals('Updated'));
        expect(updated.id, equals(original.id));
        expect(updated.phone, equals(original.phone));
        expect(updated.kycLevel, equals(KycLevel.basic));
      });

      test('replaces the roles set entirely', () {
        const original = User(
          id: 'u6',
          phone: '+998955555555',
          displayName: 'Role Swap',
        );
        final updated = original.copyWith(
          roles: const <AccountRole>{AccountRole.operator, AccountRole.admin},
        );
        expect(
          updated.roles,
          equals(<AccountRole>{AccountRole.operator, AccountRole.admin}),
        );
      });
    });
  });
}
