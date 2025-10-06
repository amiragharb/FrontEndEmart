// lib/services/paymob_api.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class InitPaymobResponse {
  final int orderId;
  final String orderNumber;
  final String status; // ex: "PENDING_PAYMENT"
  final String publicKey;
  final String clientSecret;

  InitPaymobResponse({
    required this.orderId,
    required this.orderNumber,
    required this.status,
    required this.publicKey,
    required this.clientSecret,
  });

  factory InitPaymobResponse.fromJson(Map<String, dynamic> json) {
    int _toInt(dynamic v) {
      if (v is int) return v;
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    String _toStr(dynamic v) => (v ?? '').toString();

    return InitPaymobResponse(
      orderId: _toInt(json['orderId'] ?? json['OrderID']),
      orderNumber: _toStr(json['orderNumber'] ?? json['OrderNumber']),
      status: _toStr(json['status']),
      publicKey: _toStr(json['publicKey']),
      clientSecret: _toStr(json['clientSecret']),
    );
  }
}

class PaymobApi {
  final String baseUrl; // ex: https://api.example.com
  final http.Client _client;

  PaymobApi(this.baseUrl, [http.Client? client])
      : _client = client ?? http.Client();

  /// Appelle ton endpoint Nest qui exécute OrdersService.initPaymobMobileV2
  ///
  /// Si tu utilises la route protégée par JWT:
  ///   - endpoint: $baseUrl/orders/paymob/mobile-init
  ///   - passe le bearerToken (sinon 401)
  ///
  /// Si tu utilises la route non protégée:
  ///   - endpoint: $baseUrl/orders/paymob/init
  ///   - tu peux omettre bearerToken
  Future<InitPaymobResponse> initPaymobMobileV2({
    required int userId,
    required int userLocationId,
    required int invoicePaymentMethodId, // ≠ 1 pour carte
    required double total,
    double deliveryFees = 0,
    double discountAmount = 0,
    String? additionalNotes,
    List<Map<String, dynamic>> items = const [],
    String? deliveryStartTime,
    String? deliveryEndTime,
    int? userPromoCodeId,
    String? promoCode,                       // 👈 AJOUTÉ
    String? bearerToken,                     // 👈 optionnel si route protégée
    bool useGuardedEndpoint = false,         // true -> /mobile-init ; false -> /init
  }) async {
    final path = useGuardedEndpoint ? '/orders/paymob/mobile-init'
                                    : '/orders/paymob/init';
    final uri = Uri.parse('$baseUrl$path');

    final body = <String, dynamic>{
      "userId": userId,
      "userLocationId": userLocationId,
      "invoicePaymentMethodId": invoicePaymentMethodId,
      "total": total,
      "deliveryFees": deliveryFees,
      "discountAmount": discountAmount,
      "additionalNotes": additionalNotes,
      "items": items,
      "deliveryStartTime": deliveryStartTime,
      "deliveryEndTime": deliveryEndTime,
      "userPromoCodeId": userPromoCodeId,
      "promoCode": promoCode,               // 👈 ENVOYÉ AU BACK
    }..removeWhere((k, v) => v == null);

    final headers = <String, String>{
      "Accept": "application/json",
      "Content-Type": "application/json",
      if (bearerToken != null && bearerToken.trim().isNotEmpty)
        "Authorization": "Bearer $bearerToken",
    };

    final res = await _client.post(
      uri,
      headers: headers,
      body: jsonEncode(body),
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(
          'initPaymobMobileV2 failed: ${res.statusCode} ${res.body}');
    }

    final map = jsonDecode(res.body) as Map<String, dynamic>;
    return InitPaymobResponse.fromJson(map);
  }
}
