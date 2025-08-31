import 'dart:convert';
import 'package:frontendemart/models/UserLocation_model.dart';
import 'package:frontendemart/models/SellerItem_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CartService {
  static const String _cartKey = "cart_items";
  static const String _addressKey = "addresses";

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
}
