// lib/bridge/paymob_sdk_bridge.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PaymobSdkBridge {
  static const methodChannel = MethodChannel('paymob_sdk_flutter');

  /// Appelle le SDK natif avec publicKey + clientSecret
  static Future<String> payWithPaymob({
    required String publicKey,
    required String clientSecret,
    String? appName,
    Color? buttonBackgroundColor,
    Color? buttonTextColor,
    bool? saveCardDefault,
    bool? showSaveCard,
  }) async {
    try {
      final result = await methodChannel.invokeMethod<String>('payWithPaymob', {
        "publicKey": publicKey,
        "clientSecret": clientSecret,
        "appName": appName,
        "buttonBackgroundColor": buttonBackgroundColor?.value,
        "buttonTextColor": buttonTextColor?.value,
        "saveCardDefault": saveCardDefault,
        "showSaveCard": showSaveCard,
      });
      return result ?? 'Unknown';
    } on PlatformException catch (e) {
      throw Exception("Native SDK error: ${e.message}");
    }
  }
}
