// lib/viewmodels/paymob_view_model.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontendemart/services/InitPaymobResponse_service.dart';

enum PaymobState { idle, loading, success, rejected, pending, error }

class PaymobViewModel extends ChangeNotifier {
  final PaymobApi api;
  static const _channel = MethodChannel('paymob_sdk_flutter');

  PaymobState _state = PaymobState.idle;
  String? _error;
  String? _lastRawResult; // "Successfull" | "Rejected" | "Pending"

  PaymobState get state => _state;
  String? get error => _error;
  String? get lastRawResult => _lastRawResult;

  PaymobViewModel({required this.api});

  void _setState(PaymobState s, {String? err, String? raw}) {
    _state = s;
    _error = err;
    _lastRawResult = raw;
    notifyListeners();
  }

  /// 1) Crée l'intention via backend
  /// 2) Ouvre le SDK natif (MethodChannel)
  /// 3) Retourne "Successfull" | "Rejected" | "Pending"
  Future<String> payWithCard({
    required int userId,
    required int userLocationId,
    required double total,
    required List<Map<String, dynamic>> items,
    String? additionalNotes,
    double deliveryFees = 0,
    double discountAmount = 0,
    int? userPromoCodeId,
    String? promoCode,                      // 👈 AJOUTÉ
    required DateTime deliveryStartTime,
    required DateTime deliveryEndTime,
    String? appName,
    Color? buttonBackgroundColor,
    Color? buttonTextColor,
    bool? saveCardDefault,
    bool? showSaveCard,
  }) async {
    _setState(PaymobState.loading);
    try {
      // 1) init intention (invoicePaymentMethodId ≠ 1 pour carte, ex: 2)
      final init = await api.initPaymobMobileV2(
        userId: userId,
        userLocationId: userLocationId,
        invoicePaymentMethodId: 2,
        total: total,
        deliveryFees: deliveryFees,
        discountAmount: discountAmount,
        additionalNotes: additionalNotes,
        items: items,
        deliveryStartTime: deliveryStartTime.toIso8601String(),
        deliveryEndTime: deliveryEndTime.toIso8601String(),
        userPromoCodeId: userPromoCodeId,
        promoCode: promoCode,               // 👈 PROPAGE AU BACK
      );

      // 2) Ouvrir le SDK Paymob (bridge natif)
      final result = await _channel.invokeMethod<String>('payWithPaymob', {
        "publicKey": init.publicKey,
        "clientSecret": init.clientSecret,
        "appName": appName,
        "buttonBackgroundColor": buttonBackgroundColor?.value,
        "buttonTextColor": buttonTextColor?.value,
        "saveCardDefault": saveCardDefault,
        "showSaveCard": showSaveCard,
      }) ?? 'Unknown';

      // 3) Mapper l'état lisible
      switch (result) {
        case 'Successfull':
          _setState(PaymobState.success, raw: result);
          break;
        case 'Rejected':
          _setState(PaymobState.rejected, raw: result);
          break;
        case 'Pending':
          _setState(PaymobState.pending, raw: result);
          break;
        default:
          _setState(PaymobState.error, err: 'Unknown response', raw: result);
      }

      return result;
    } on PlatformException catch (e) {
      _setState(PaymobState.error, err: e.message);
      rethrow;
    } catch (e) {
      _setState(PaymobState.error, err: e.toString());
      rethrow;
    }
  }

  void reset() => _setState(PaymobState.idle);
}
