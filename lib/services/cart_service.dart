import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:frontendemart/config/api.dart';
import 'package:frontendemart/models/UserLocation_model.dart';
import 'package:frontendemart/models/SellerItem_model.dart';
import 'package:frontendemart/views/payment/choose_payment_method_screen.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class CartService {
  static const String _cartKey = "cart_items";
  static const String _addressKey = "addresses";
static final String baseUrl = ApiConfig.baseUrl;

  /// -------------------- CART --------------------

  static Future<List<SellerItem>> getCartItems() async {
    final prefs = await SharedPreferences.getInstance();
    final cartString = prefs.getString(_cartKey);
    if (cartString == null) return [];

    final List decoded = jsonDecode(cartString);
    return decoded.map((e) => SellerItem.fromJson(e)).toList();
  }

  static Future<void> addToCart(SellerItem item) async {
    final prefs = await SharedPreferences.getInstance();
    final items = await getCartItems();

    final index = items.indexWhere((e) => e.sellerItemID == item.sellerItemID);
    if (index != -1) {
      items[index].qty += item.qty; // ⚡ incrémenter quantité
    } else {
      items.add(item);
    }

    final encoded = jsonEncode(items.map((e) => e.toJson()).toList());
    await prefs.setString(_cartKey, encoded);
  }

  static Future<void> removeFromCart(int sellerItemId) async {
    final prefs = await SharedPreferences.getInstance();
    final items = await getCartItems();
    items.removeWhere((e) => e.sellerItemID == sellerItemId);

    final encoded = jsonEncode(items.map((e) => e.toJson()).toList());
    await prefs.setString(_cartKey, encoded);
  }

  static Future<void> clearCart() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cartKey);
  }

  /// -------------------- ADDRESSES --------------------

  static Future<List<UserLocation>> getAddresses() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_addressKey);
    if (jsonString == null) return [];
    final List decoded = jsonDecode(jsonString);
    return decoded.map((e) => UserLocation.fromJson(e)).toList();
  }

  static Future<void> saveAddresses(List<UserLocation> addresses) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(addresses.map((e) => e.toJson()).toList());
    await prefs.setString(_addressKey, jsonString);
  }

  static Future<void> addAddress(UserLocation address) async {
    final addresses = await getAddresses();
    addresses.add(address);
    await saveAddresses(addresses);
  }

  static Future<void> removeAddress(int userLocationID) async {
    final addresses = await getAddresses();
    addresses.removeWhere((e) => e.userLocationID == userLocationID);
    await saveAddresses(addresses);
  }

 // lib/services/cart_service.dart// services/cart_service.dart
static Future<Map<String, dynamic>> placeOrder({
  required int userId,
  required int userLocationId,
  required PaymentMethod method,
  required DateTime deliveryStart,
  required DateTime deliveryEnd,
  required double total,
  required double deliveryFees,
  required double discountAmount,
  required List<Map<String, dynamic>> items,
  String? additionalNotes,
  int? userPromoCodeId,
  String? promoCode, // 👈 nouveau
}) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');

  final body = {
    'userId': userId,
    'userLocationId': userLocationId,
    'invoicePaymentMethodId': method == PaymentMethod.cod ? 1 : 2,
    'deliveryStartTime': deliveryStart.toIso8601String(),
    'deliveryEndTime': deliveryEnd.toIso8601String(),
    'total': total, // (le back recalcule tout de toute façon)
    'deliveryFees': deliveryFees,
    'discountAmount': discountAmount,
    'additionalNotes': additionalNotes,
    'userPromoCodeId': userPromoCodeId,
    'promoCode': promoCode,                 // 👈 **passe le code**
    'items': items,
  };

  final uri = Uri.parse('${ApiConfig.baseUrl}/orders');
  final headers = {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
    if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
  };

  final res = await http
      .post(uri, headers: headers, body: json.encode(body))
      .timeout(const Duration(seconds: 20));

  if (res.statusCode < 200 || res.statusCode >= 300) {
    throw Exception('placeOrder failed: ${res.statusCode} ${res.body}');
  }
  final map = json.decode(res.body);
  return (map is Map<String, dynamic>) ? map : <String, dynamic>{};
}

// lib/services/cart_service.dart
// lib/services/cart_service.dart

static String _numStr(double n) => n.toStringAsFixed(2).replaceAll(',', '.');



 static Future<Map<String, dynamic>> previewPromo({
    required String code,
    required double subTotal,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final uri = Uri.parse('${ApiConfig.baseUrl}/orders/promo/validate').replace(
      queryParameters: {
        'code': code,
        'subTotal': subTotal.toStringAsFixed(2), // "220.00"
      },
    );

    final headers = <String, String>{
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };

    final res = await http
        .get(uri, headers: headers)
        .timeout(const Duration(seconds: 15));

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('promo preview failed: ${res.statusCode} ${res.body}');
    }
    final map = json.decode(res.body);
    return (map is Map<String, dynamic>) ? map : <String, dynamic>{};
  }



}
