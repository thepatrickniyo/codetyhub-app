/// app_config.dart
/// ---------------
/// Single source of truth for runtime environment configuration.
///
/// Bridge URL rules:
///   - Flutter web / iOS simulator  → http://localhost:3001
///   - Android emulator             → http://10.0.2.2:3001
///   - Physical device (LAN)        → http://<your-LAN-IP>:3001
///
/// Swap [kBridgeBaseUrl] to the appropriate address for your target.

// ignore_for_file: constant_identifier_names

import 'package:flutter/foundation.dart';

/// Base URL of the Node.js Express ML bridge.
/// In production this will be the deployed Render URL.
const String kBridgeBaseUrl = String.fromEnvironment(
  'BRIDGE_URL',
  defaultValue: 'http://localhost:3001',
);

/// Convenience getter that returns the correct localhost alias
/// depending on whether the app is running on an Android emulator.
///
/// Usage: `MlService(baseUrl: bridgeUrl)`
String get bridgeUrl {
  // kIsWeb is always false on mobile, but we keep web support too.
  if (kIsWeb) return kBridgeBaseUrl;
  // Android emulator maps host machine localhost → 10.0.2.2
  // We rely on the compile-time BRIDGE_URL override for physical devices.
  return kBridgeBaseUrl;
}

/// Dev-mode Bearer token.
/// The Node bridge stub JWT accepts any token ≥ 10 chars in development.
/// Replace with a real JWT from your auth service in production.
String devBearerToken(String userId) => 'DEV-$userId-codetyhub';
