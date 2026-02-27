import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;

class ApiConfig {
  static String get baseUrl {
    if (kIsWeb) {
      return "http://localhost:3000";
    }

    if (Platform.isAndroid) {
      const emulatorHost = "10.0.2.2";

      const realDeviceHost = "192.168.1.14";

      const bool useRealDevice = true;

      final host = useRealDevice ? realDeviceHost : emulatorHost;
      return "http://$host:3000";
    }

    return "http://localhost:3000";
  }
}
