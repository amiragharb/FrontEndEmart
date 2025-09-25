import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontendemart/models/SellerItem_model.dart';

class CartViewModel extends ChangeNotifier {
  final Map<String, SellerItem> _items = {};
  static const _kCartKey = 'cart_items_v1';
  bool _hydrated = false;
  bool get hydrated => _hydrated;

  List<SellerItem> get items => _items.values.toList(growable: false);

  double get total {
    double sum = 0;
    for (final it in _items.values) {
      sum += it.price * it.qty; // price: double, qty: int (non-null)
    }
    return sum;
  }

  // ✅ Clé stable basée sur ton vrai modèle
  String _keyOf(SellerItem it) => '${it.sellerItemID}';
  // ou: '${it.medicineID}-${it.sellerID}-${it.sellerItemID}'

  // -------- Hydration (restore) ----------
  Future<void> hydrate() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kCartKey);
    if (raw == null || raw.isEmpty) {
      _hydrated = true;
      notifyListeners();
      return;
    }

    try {
      final List list = jsonDecode(raw) as List;
      _items.clear();
      for (final m in list) {
        final it = SellerItem.fromJson(Map<String, dynamic>.from(m as Map));
        _items[_keyOf(it)] = it;
      }
    } catch (e) {
      // si données corrompues → on repart propre
      _items.clear();
    }
    _hydrated = true;
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final list = _items.values.map((e) => e.toJson()).toList();
    await prefs.setString(_kCartKey, jsonEncode(list));
  }

  // -------- Mutations ----------
  void add(SellerItem item, {int qty = 1}) {
    final k = _keyOf(item);
    final ex = _items[k];
    if (ex == null) {
      // IMPORTANT: ne pas passer par fromJson(toJson()) → on garde photoUrl EXACTE
      _items[k] = SellerItem(
        sellerItemID: item.sellerItemID,
        medicineID: item.medicineID,
        sellerID: item.sellerID,
        stockQuantity: item.stockQuantity,
        price: item.price,
        priceWas: item.priceWas,
        isOutOfStock: item.isOutOfStock,
        nameEn: item.nameEn,
        nameAr: item.nameAr,
        photoUrl: item.photoUrl,
        avgRating: item.avgRating,
        totalRatings: item.totalRatings,
        indications: item.indications,
        pamphletEn: item.pamphletEn,
        pamphletAr: item.pamphletAr,
        packDescription: item.packDescription,
        youtubeURL: item.youtubeURL,
        imageUrls: item.imageUrls,
        qty: qty < 1 ? 1 : qty,
      );
    } else {
      ex.qty = ex.qty + (qty < 1 ? 1 : qty);
    }
    notifyListeners();
    _persist();
  }

  void remove(String key) {
    if (_items.remove(key) != null) {
      notifyListeners();
      _persist();
    }
  }

  void inc(String key) {
    final it = _items[key];
    if (it == null) return;
    it.qty = it.qty + 1;
    notifyListeners();
    _persist();
  }

  void dec(String key) {
    final it = _items[key];
    if (it == null) return;
    if (it.qty > 1) {
      it.qty = it.qty - 1;
      notifyListeners();
      _persist();
    }
  }

  void clear() {
    if (_items.isEmpty) return;
    _items.clear();
    notifyListeners();
    _persist();
  }
    /// Retourne les lignes à envoyer à l'API /orders
  List<Map<String, dynamic>> toOrderItemsPayload() {
  return _items.values.map((it) => {
    "medicineId": it.medicineID,   // ✅ colonne FK de tbl_OrderItems
    "quantity": it.qty,            // ✅ Quantity
    "price": it.price,             // ✅ Price
    "isStrip": false,              // adapte si tu gères les strips
    // "alternativeMedicineId": <int?>, // si tu l’utilises plus tard
  }).toList(growable: false);
}

  /// Total déjà présent (get total) = somme des lignes
  double get subtotal => total; // alias lisible

}
