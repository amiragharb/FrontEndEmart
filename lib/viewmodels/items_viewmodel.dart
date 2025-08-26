import 'package:flutter/material.dart';
import 'package:frontendemart/models/SellerItem_model.dart';
import 'package:frontendemart/models/category_model.dart';
import '../services/api_service.dart';

class ItemsViewModel extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  List<SellerItem> _items = [];
  List<Category> _categories = [];
  bool _loading = false;
  bool loading = false;

  String? _searchQuery;
  String _categoryFilter = "All";
  String _sortOption = "None";

  // --- Getters ---
  List<SellerItem> get items => _items;
  List<Category> get categories => _categories;
  String get selectedCategory => _categoryFilter;
  String get sortOption => _sortOption;

  // --- Best sellers ---
  List<SellerItem> get bestSellers =>
      _items.where((i) => i.priceWas != null && i.priceWas! > i.price).toList();

  // --- Charger les catégories ---
  Future<void> loadCategories() async {
    try {
      _categories = await _apiService.fetchCategories();
      notifyListeners();
    } catch (e) {
      debugPrint("❌ Erreur loadCategories: $e");
      _categories = [];
    }
  }

  // --- Charger les items avec filtres ---
  Future<void> loadItems({String? search, String? category, String? sort}) async {
    _loading = true;
    notifyListeners();

    try {
      _items = await _apiService.fetchItems(
        search: search,
        category: category,
        sort: sort,
      );
    } catch (e) {
      debugPrint("❌ Erreur loadItems: $e");
      _items = [];
    }

    _loading = false;
    notifyListeners();
  }

  // --- Recherche ---
  void searchItems(String query) {
    _searchQuery = query;
    loadItems(search: query, category: _categoryFilter, sort: _sortOption);
  }

  // --- Filtrer par catégorie ---
Future<void> filterByCategory(String? category) async {
  if (category == null || category == "All") {
    _categoryFilter = "All";
    await loadItems(search: _searchQuery, category: null, sort: _sortOption);
  } else {
    _categoryFilter = category;
    await loadItems(search: _searchQuery, category: _categoryFilter, sort: _sortOption);
  }
}

void sortItems(String? sortOption) {
  if (sortOption == null || sortOption == "None") {
    _sortOption = "None";
    loadItems(search: _searchQuery, category: _categoryFilter == "All" ? null : _categoryFilter, sort: null);
  } else {
    _sortOption = sortOption;
    loadItems(search: _searchQuery, category: _categoryFilter == "All" ? null : _categoryFilter, sort: _sortOption);
  }
}
// ⚡ Charger les stats de ratings pour un produit
Future<Map<String, dynamic>?> loadRatings(int sellerItemId) async {
  try {
    final result = await _apiService.fetchRatings(sellerItemId);
    return result;
  } catch (e) {
    debugPrint("❌ Erreur loadRatings: $e");
    return null;
  }
}

// ⚡ Ajouter un rating
Future<bool> addRating(
  int sellerItemId,
  int userId,
  int rating, {
  String? comment,
  bool recommend = false,
}) async {
  final success = await _apiService.rateProduct(
    sellerItemId,
    userId,
    rating,
    comment: comment,
    recommend: recommend,
  );

  if (success) {
    // 🔄 recharge les ratings après ajout
    await loadRatings(sellerItemId);
  }

  return success;
}


}
