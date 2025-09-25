import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:frontendemart/models/SellerItem_model.dart';

class WishlistViewModeltep extends ChangeNotifier {
  // Map indexée par une clé stable (ici SellerItemID)
  final Map<String, SellerItem> _items = {};

  static const _kWishlistKey = 'wishlist_items_v1';
  bool _hydrated = false;
  bool get hydrated => _hydrated;

  // ----- Getters -----
  List<SellerItem> get items => _items.values.toList(growable: false);
  int get count => _items.length;

  bool contains(SellerItem it) => _items.containsKey(_keyOf(it));

  // Clé stable : adapte si besoin (ex: '${it.medicineID}-${it.sellerID}-${it.sellerItemID}')
  String _keyOf(SellerItem it) => '${it.sellerItemID}';

  // ----- Hydration (restore) -----
  Future<void> hydrate() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kWishlistKey);

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
    } catch (_) {
      // Données corrompues → repartir propre
      _items.clear();
    }

    _hydrated = true;
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final list = _items.values.map((e) => e.toJson()).toList();
    await prefs.setString(_kWishlistKey, jsonEncode(list));
  }

  // ----- Mutations -----
  void add(SellerItem item) {
    final k = _keyOf(item);
    if (_items.containsKey(k)) return; // déjà présent
    _items[k] = _clone(item);
    notifyListeners();
    _persist();
  }
void remove(int sellerItemID) {
  _items.remove('$sellerItemID');  // si tes clés sont des String
  notifyListeners();
  _persist(); // si tu persistes
}


void removeByKey(String key) {
  if (_items.remove(key) != null) {
    notifyListeners();
    _persist();
  }
}

void removeById(int sellerItemID) => removeByKey('$sellerItemID');




  void toggle(SellerItem item) {
    final k = _keyOf(item);
    if (_items.containsKey(k)) {
      _items.remove(k);
    } else {
      _items[k] = _clone(item);
    }
    notifyListeners();
    _persist();
  }

  void clear() {
    if (_items.isEmpty) return;
    _items.clear();
    notifyListeners();
    _persist();
  }

  // ----- Utilitaire : clone "propre" pour éviter toute mutation externe -----
  SellerItem _clone(SellerItem s) => SellerItem(
        sellerItemID: s.sellerItemID,
        medicineID: s.medicineID,
        sellerID: s.sellerID,
        stockQuantity: s.stockQuantity,
        price: s.price,
        priceWas: s.priceWas,
        isOutOfStock: s.isOutOfStock,
        nameEn: s.nameEn,
        nameAr: s.nameAr,
        photoUrl: s.photoUrl,        // ⚠️ on garde EXACTEMENT l’URL
        avgRating: s.avgRating,
        totalRatings: s.totalRatings,
        indications: s.indications,
        pamphletEn: s.pamphletEn,
        pamphletAr: s.pamphletAr,
        packDescription: s.packDescription,
        youtubeURL: s.youtubeURL,
        imageUrls: List<String>.from(s.imageUrls),
        qty: s.qty,                  // pas utilisé pour wishlist, mais on garde
      );
}
