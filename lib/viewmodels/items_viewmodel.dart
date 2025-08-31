import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:frontendemart/config/api.dart';
import 'package:frontendemart/models/SellerItem_model.dart';
import 'package:frontendemart/models/category_model.dart';
import 'package:frontendemart/models/datasheet_model.dart';
import 'package:frontendemart/models/video_model.dart';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';

class ItemsViewModel extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  // Collections principales
  List<Datasheet> _datasheets = [];
  List<SellerItem> _items = [];
  List<Category> _categories = [];
  List<VideoModel> _videos = [];
  
  // Cache des ratings par produit pour éviter les rechargements inutiles
  final Map<int, ProductRatingData> _ratingsCache = {};
  
  // Données du produit actuellement affiché
  int _currentProductId = -1;
  ProductRatingData? _currentRatingData;
  
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
  List<Datasheet> get datasheets => _datasheets;
  List<VideoModel> get videos => _videos;
  
  // Getters pour les ratings du produit actuel
  double get averageRating => _currentRatingData?.averageRating ?? 0.0;
  int get totalRatings => _currentRatingData?.totalRatings ?? 0;
  int get recommendPercent => _currentRatingData?.recommendPercent ?? 0;
  List<Map<String, dynamic>> get distribution => _currentRatingData?.distribution ?? [];

  // --- Best sellers ---
  List<SellerItem> get bestSellers =>
      _items.where((i) => i.priceWas != null && i.priceWas! > i.price).toList();

  // --- Réinitialiser les données spécifiques au produit ---
  void resetProductData() {
    _currentProductId = -1;
    _currentRatingData = null;
    _datasheets = [];
    _videos = [];
    notifyListeners();
  }

  // --- Charger les catégories ---
  Future<void> loadCategories() async {
    try {
      _categories = await _apiService.fetchCategories();
      notifyListeners();
    } catch (e) {
      debugPrint("Erreur loadCategories: $e");
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
      debugPrint("Erreur loadItems: $e");
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

  // --- Charger les ratings d'un produit spécifique ---
  Future<void> loadRatings(int sellerItemId) async {
    // CORRECTION 1: Vérifier seulement le cache, pas _currentProductId
    if (_ratingsCache.containsKey(sellerItemId)) {
      _currentProductId = sellerItemId;
      _currentRatingData = _ratingsCache[sellerItemId];
      debugPrint("Ratings chargés depuis le cache pour produit $sellerItemId");
      notifyListeners();
      return;
    }

    try {
      _currentProductId = sellerItemId;
      final result = await _apiService.fetchRatings(sellerItemId);

      final distribution = List<Map<String, dynamic>>.from(result["distribution"] ?? []);
      final recommend = result["recommend"] ?? 0;

      int totalVotes = 0;
      int sum = 0;
      for (var d in distribution) {
        final total = d["total"] as int? ?? 0;
        final rate = d["Rate"] as int? ?? 0;
        totalVotes += total;
        sum += rate * total;
      }

      final avgRating = totalVotes > 0 ? sum / totalVotes : 0.0;
      
      // Créer et sauvegarder les données de rating
      final ratingData = ProductRatingData(
        averageRating: avgRating,
        totalRatings: totalVotes,
        recommendPercent: recommend,
        distribution: distribution,
      );

      _ratingsCache[sellerItemId] = ratingData;
      _currentRatingData = ratingData;

      debugPrint("Ratings chargés depuis l'API pour produit $sellerItemId: avg=$avgRating, total=$totalVotes");
      notifyListeners();
    } catch (e) {
      debugPrint("Erreur loadRatings($sellerItemId): $e");
      // En cas d'erreur, créer des données vides
      _currentRatingData = ProductRatingData(
        averageRating: 0.0,
        totalRatings: 0,
        recommendPercent: 0,
        distribution: [],
      );
      notifyListeners();
    }
  }

  // --- Ajouter un rating ---
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
      // Supprimer du cache pour forcer un rechargement avec les nouvelles données
      _ratingsCache.remove(sellerItemId);
      await loadRatings(sellerItemId);
      debugPrint("Rating ajouté avec succès pour produit $sellerItemId");
    }

    return success;
  }

  // --- Charger les datasheets pour un médicament ---
  Future<void> loadDatasheets(int medicineId) async {
    try {
      loading = true;
      notifyListeners();

      final response = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/items/$medicineId/datasheets"),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = jsonDecode(response.body);
        _datasheets = jsonData.map((e) => Datasheet.fromJson(e)).toList();
        debugPrint("Datasheets chargés: ${_datasheets.length} éléments");
      } else {
        _datasheets = [];
        debugPrint("Aucun datasheet trouvé pour le médicament $medicineId");
      }
    } catch (e) {
      debugPrint("Erreur loadDatasheets: $e");
      _datasheets = [];
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  // --- Charger les vidéos pour un médicament ---
  Future<void> loadVideos(int medicineId) async {
    debugPrint("Chargement des vidéos pour médicament $medicineId");

    try {
      loading = true;
      notifyListeners();

      _videos = await _apiService.fetchVideos(medicineId);
      debugPrint("Vidéos chargées: ${_videos.length} éléments");
      
      for (var v in _videos) {
        debugPrint("Vidéo: id=${v.id}, nom=${v.fileName}, url=${v.fileUrl}");
      }
    } catch (e, stack) {
      debugPrint("Erreur loadVideos: $e");
      debugPrint(stack.toString());
      _videos = [];
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  // --- Obtenir les ratings d'un produit spécifique depuis le cache ---
  ProductRatingData? getRatingsForProduct(int sellerItemId) {
    return _ratingsCache[sellerItemId];
  }

  // --- Vérifier si les ratings d'un produit sont chargés ---
  bool hasRatingsForProduct(int sellerItemId) {
    return _ratingsCache.containsKey(sellerItemId);
  }

  // CORRECTION 3: Nouvelle méthode pour vérifier si on affiche le bon produit
  bool isCurrentProduct(int sellerItemId) {
    return _currentProductId == sellerItemId;
  }
}

// --- Classe pour encapsuler les données de rating d'un produit ---
class ProductRatingData {
  final double averageRating;
  final int totalRatings;
  final int recommendPercent;
  final List<Map<String, dynamic>> distribution;

  ProductRatingData({
    required this.averageRating,
    required this.totalRatings,
    required this.recommendPercent,
    required this.distribution,
  });

  @override
  String toString() {
    return 'ProductRatingData(avg: $averageRating, total: $totalRatings, recommend: $recommendPercent%)';
  }
  
  
}