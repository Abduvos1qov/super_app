import 'package:shared_models/shared_models.dart';
import 'package:test/test.dart';

void main() {
  group('User JSON round-trip', () {
    test('Rider survives serialization', () {
      const rider = User.rider(
        id: 'r1',
        phone: '+998900000000',
        displayName: 'Demo Rider',
        avatarUrl: 'https://example.test/a.png',
      );
      final decoded = User.fromJson(rider.toJson());
      expect(decoded, equals(rider));
    });

    test('Driver survives serialization', () {
      const driver = User.driver(
        id: 'd1',
        phone: '+998900000001',
        displayName: 'Demo Driver',
        licenseNumber: 'AA1234BB',
        rating: 4.8,
      );
      final decoded = User.fromJson(driver.toJson());
      expect(decoded, equals(driver));
    });

    test('Admin with unknown role decodes safely', () {
      final decoded = User.fromJson(<String, dynamic>{
        'type': 'admin',
        'id': 'a1',
        'email': 'ops@example.test',
        'role': 'nonexistent_role',
      });
      expect(decoded, isA<Admin>());
      expect((decoded as Admin).role, equals(AdminRole.unknown));
    });

    test('pattern match reaches all variants', () {
      String label(User u) => switch (u) {
            Rider() => 'rider',
            Driver() => 'driver',
            Admin() => 'admin',
          };
      expect(label(const User.rider(id: '', phone: '', displayName: '')), 'rider');
      expect(
        label(const User.driver(id: '', phone: '', displayName: '', licenseNumber: '')),
        'driver',
      );
      expect(label(const User.admin(id: '', email: '')), 'admin');
    });
  });
}
