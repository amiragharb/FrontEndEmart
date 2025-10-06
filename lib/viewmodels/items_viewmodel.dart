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

  // ===== Collections principales =====
  List<Datasheet> _datasheets = [];
  List<SellerItem> _allItems = [];
  List<SellerItem> _items = [];
  List<Category> _categories = [];
  List<VideoModel> _videos = [];

  // ===== Filtres / état UI =====
  String? _searchQuery;
  String _categoryFilter = "All";
  String _sortOption = "None";
  double? _minPrice;
  double? _maxPrice;

  // ===== Divers =====
  final Map<int, ProductRatingData> _ratingsCache = {};
  int _currentProductId = -1;
  ProductRatingData? _currentRatingData;

  bool _loading = false;
  bool loading = false;

  List<Category> _topBrandsOrCategories = [];

  // ===== Getters =====
  List<SellerItem> get items => _items;
  List<Category> get categories => _categories;
  String get selectedCategory => _categoryFilter;
  String get sortOption => _sortOption;
  List<Datasheet> get datasheets => _datasheets;
  List<VideoModel> get videos => _videos;
  List<Category> get topBrandsOrCategories => _topBrandsOrCategories;

  double? get minPrice => _minPrice;
  double? get maxPrice => _maxPrice;
  bool get isLoading => _loading;

  // ===== Best sellers =====
  List<SellerItem> get bestSellers =>
      _items.where((i) => i.priceWas != null && i.priceWas! > i.price).toList();

  // ===== Reset données produit =====
  void resetProductData() {
    _currentProductId = -1;
    _currentRatingData = null;
    _datasheets = [];
    _videos = [];
    notifyListeners();
  }

  // ===== Catégories =====
  Future<void> loadCategories() async {
    try {
      _categories = await _apiService.fetchCategories();
      notifyListeners();
    } catch (e) {
      debugPrint("Erreur loadCategories: $e");
      _categories = [];
    }
  }

  /* ===========================================================
   *                     ITEMS & FILTRES
   * =========================================================== */

  /// Charge depuis l'API avec filtres serveur, puis applique les filtres locaux
  Future<void> loadItems({String? search, String? category, String? sort}) async {
    _loading = true;
    notifyListeners();

    try {
      final fetched = await _apiService.fetchItems(
        search: search,
        category: (category == null || category == "All") ? null : category,
        sort: (sort == null || sort == "None") ? null : sort,
      );

      _allItems = fetched;
      _applyLocalFiltersAndSort();
    } catch (e) {
      debugPrint("Erreur loadItems: $e");
      _allItems = [];
      _items = [];
    }

    _loading = false;
    notifyListeners();
  }

  /// Recherche (server-side)
  void searchItems(String query) {
    _searchQuery = query;
    loadItems(
      search: query,
      category: _categoryFilter,
      sort: _sortOption,
    );
  }

  /// Filtre catégorie (server-side)
  Future<void> filterByCategory(String? category) async {
    _categoryFilter = (category == null || category == "All") ? "All" : category;
    await loadItems(
      search: _searchQuery,
      category: _categoryFilter,
      sort: _sortOption,
    );
  }

  /// Tri
  void sortItems(String? sortOption) {
    _sortOption = (sortOption == null || sortOption == "None") ? "None" : sortOption;
    loadItems(
      search: _searchQuery,
      category: _categoryFilter,
      sort: _sortOption,
    );
  }

  /// Définir plage de prix (local-only) - CORRIGÉ
  void setPriceRange(double min, double max) {
    _minPrice = min;
    _maxPrice = max;
    _applyLocalFiltersAndSort(); // Applique immédiatement sans recharger
    notifyListeners();
  }

  /// Réinitialise tous les filtres - CORRIGÉ
  Future<void> resetFilters() async {
    _searchQuery = null;
    _categoryFilter = 'All';
    _sortOption = 'None';
    _minPrice = null;
    _maxPrice = null;
    await loadItems();
  }

  /// Applique les filtres locaux (prix) + tri sur _allItems → _items
  void _applyLocalFiltersAndSort() {
    var list = List<SellerItem>.from(_allItems);

    // Filtre prix min
    if (_minPrice != null) {
      list = list.where((it) => (it.price ?? 0) >= _minPrice!).toList();
    }
    
    // Filtre prix max
    if (_maxPrice != null) {
      list = list.where((it) => (it.price ?? 0) <= _maxPrice!).toList();
    }

    // Tri local
    switch (_sortOption) {
      case "PriceAsc":
        list.sort((a, b) => (a.price ?? 0).compareTo(b.price ?? 0));
        break;
      case "PriceDesc":
        list.sort((a, b) => (b.price ?? 0).compareTo(a.price ?? 0));
        break;
      case "BestRated":
        list.sort((a, b) => (b.avgRating ?? 0).compareTo(a.avgRating ?? 0));
        break;
      default:
        break;
    }

    _items = list;
  }

  /* ===========================================================
   *                        RATINGS
   * =========================================================== */

  double get averageRating => _currentRatingData?.averageRating ?? 0.0;
  int get totalRatings => _currentRatingData?.totalRatings ?? 0;
  int get recommendPercent => _currentRatingData?.recommendPercent ?? 0;
  List<Map<String, dynamic>> get distribution => _currentRatingData?.distribution ?? [];

  Future<void> loadRatings(int sellerItemId) async {
    if (_ratingsCache.containsKey(sellerItemId)) {
      _currentProductId = sellerItemId;
      _currentRatingData = _ratingsCache[sellerItemId];
      notifyListeners();
      return;
    }

    try {
      _currentProductId = sellerItemId;
      final res = await _apiService.fetchRatings(sellerItemId);

      List<Map<String, dynamic>> distRaw = const [];
      int recommend = 0;

      if (res is List && res.isNotEmpty) {
        final block0 = res[0];
        if (block0 is List) {
          distRaw = block0
              .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
              .toList();
        }
        if (res.length > 1 && res[1] is List && (res[1] as List).isNotEmpty) {
          final m = Map<String, dynamic>.from((res[1] as List).first);
          recommend = (m['RecommendThisProduct'] as num?)?.toInt() ?? 0;
        }
      } else if (res is Map) {
        distRaw = List<Map<String, dynamic>>.from(res['distribution'] ?? const []);
        recommend = (res['recommend'] as num?)?.toInt() ?? 0;
      }

      final Map<int, int> counts = {for (var s in [0,1,2,3,4,5]) s: 0};
      for (final row in distRaw) {
        final rateRaw = (row['Rate'] as num?)?.toDouble() ?? 0.0;
        final total   = (row['total'] as num?)?.toInt() ?? 0;
        final stars = rateRaw > 5 ? (rateRaw / 20.0).round() : rateRaw.round();
        final s = stars.clamp(0, 5).toInt();
        counts[s] = (counts[s] ?? 0) + total;
      }

      int totalVotes = counts.values.fold(0, (a, b) => a + b);
      int sum = 0;
      counts.forEach((stars, c) => sum += stars * c);
      final avgRating = totalVotes > 0 ? (sum / totalVotes) : 0.0;

      final distribution = [5, 4, 3, 2, 1]
          .map<Map<String, dynamic>>((s) => <String, dynamic>{
                'Rate': s,
                'total': counts[s] ?? 0,
              })
          .toList();

      final data = ProductRatingData(
        averageRating: avgRating,
        totalRatings: totalVotes,
        recommendPercent: recommend,
        distribution: distribution,
      );

      _ratingsCache[sellerItemId] = data;
      _currentRatingData = data;
      notifyListeners();
    } catch (e) {
      _currentRatingData = ProductRatingData(
        averageRating: 0.0,
        totalRatings: 0,
        recommendPercent: 0,
        distribution: const [],
      );
      notifyListeners();
    }
  }

  void applyLocalRating({
    required int sellerItemId,
    required int rating,
    required bool recommend,
  }) {
    final current = _ratingsCache[sellerItemId] ??
        ProductRatingData(
          averageRating: 0,
          totalRatings: 0,
          recommendPercent: 0,
          distribution: List.generate(6, (i) => {'Rate': 5 - i, 'total': 0}),
        );

    final oldTotal = current.totalRatings;
    final oldAvg   = current.averageRating;

    final newTotal = oldTotal + 1;
    final newAvg   = ((oldAvg * oldTotal) + rating) / newTotal;

    final dist = List<Map<String, dynamic>>.from(current.distribution);
    final idx  = dist.indexWhere((e) => e['Rate'] == rating);
    if (idx >= 0) {
      dist[idx]['total'] = (dist[idx]['total'] ?? 0) + 1;
    } else {
      dist.add({'Rate': rating, 'total': 1});
    }

    final oldRecommendCount = ((current.recommendPercent / 100) * oldTotal).round();
    final newRecommendCount = oldRecommendCount + (recommend ? 1 : 0);
    final newPercent = newTotal == 0 ? 0 : ((newRecommendCount * 100) / newTotal).round();

    final updated = ProductRatingData(
      averageRating: newAvg,
      totalRatings: newTotal,
      recommendPercent: newPercent,
      distribution: dist,
    );

    _ratingsCache[sellerItemId] = updated;
    if (_currentProductId == sellerItemId) {
      _currentRatingData = updated;
    }
    notifyListeners();
  }

  Future<bool> addRating(
    int sellerItemId,
    int userId,
    int rating, {
    String? comment,
    bool recommend = false,
  }) async {
    applyLocalRating(
      sellerItemId: sellerItemId,
      rating: rating,
      recommend: recommend,
    );

    final success = await _apiService.rateProduct(
      sellerItemId,
      userId,
      rating,
      comment: comment,
      recommend: recommend,
    );

    if (success) {
      _ratingsCache.remove(sellerItemId);
      await loadRatings(sellerItemId);
    } else {
      await loadRatings(sellerItemId);
    }
    return success;
  }

  /* ===========================================================
   *                    DATASHEETS / VIDÉOS
   * =========================================================== */

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

  ProductRatingData? getRatingsForProduct(int sellerItemId) {
    return _ratingsCache[sellerItemId];
  }

  bool hasRatingsForProduct(int sellerItemId) {
    return _ratingsCache.containsKey(sellerItemId);
  }

  bool isCurrentProduct(int sellerItemId) {
    return _currentProductId == sellerItemId;
  }

  /* ===========================================================
   *                 Top brands / catégories
   * =========================================================== */
  Future<void> loadTopBrandsOrCategories({int limit = 6}) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/top-brands?limit=$limit');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['data'] as List;
        _topBrandsOrCategories =
            data.map((json) => Category.fromJson(json)).toList();
        debugPrint("Top brands/categories chargés: ${_topBrandsOrCategories.length}");
      } else {
        _topBrandsOrCategories = [];
        debugPrint("Erreur loadTopBrandsOrCategories: statusCode=${response.statusCode}");
      }
    } catch (e) {
      _topBrandsOrCategories = [];
      debugPrint("Erreur loadTopBrandsOrCategories: $e");
    } finally {
      notifyListeners();
    }
  }
}

/* ===== Modèle des ratings ===== */
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
  String toString() =>
      'ProductRatingData(avg: $averageRating, total: $totalRatings, recommend: $recommendPercent%)';
}