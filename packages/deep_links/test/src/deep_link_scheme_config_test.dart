import 'package:deep_links/deep_links.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DeepLinkSchemeConfig', () {
    test('defaults to the superapp scheme and no HTTPS hosts', () {
      const config = DeepLinkSchemeConfig();

      expect(config.allowedSchemes, equals({'superapp'}));
      expect(config.allowedHttpsHosts, isEmpty);
    });

    test('retains custom schemes and hosts passed at construction', () {
      const config = DeepLinkSchemeConfig(
        allowedSchemes: {'superapp', 'internal'},
        allowedHttpsHosts: {'super.app', 'links.super.app'},
      );

      expect(
        config.allowedSchemes,
        equals({'superapp', 'internal'}),
      );
      expect(
        config.allowedHttpsHosts,
        equals({'super.app', 'links.super.app'}),
      );
    });
  });
}
