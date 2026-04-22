import 'package:mini_app_sdk/mini_app_sdk.dart';

/// Manifest for the wallet mini-app.
const walletMiniAppManifest = MiniAppManifest(
  id: 'com.superapp.wallet',
  name: 'Wallet',
  version: '0.1.0',
  category: MiniAppCategory.payments,
  iconAssetPath: 'packages/wallet_mini_app/assets/icon.svg',
);
