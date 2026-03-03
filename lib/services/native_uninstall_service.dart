import 'package:flutter/services.dart';

class NativeUninstallService {
  static const MethodChannel _channel = MethodChannel('bock.store/native');

  static Future<void> uninstallApp(String packageName) async {
    await _channel.invokeMethod('uninstallApp', {"packageName": packageName});
  }

  static Future<bool> isAppInstalled(String packageName) async {
    final result = await _channel.invokeMethod('isAppInstalled', {
      "packageName": packageName,
    });

    return result == true;
  }
}
