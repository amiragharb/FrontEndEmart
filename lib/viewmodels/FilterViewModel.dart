import 'package:flutter/foundation.dart';

class FilterViewModel extends ChangeNotifier {
  // null => pas de borne
  double? minPrice;
  double? maxPrice;
  String? categoryId; // "All" ou un id de catégorie

  // Valeurs par défaut (rien sélectionné)
  FilterViewModel({this.minPrice, this.maxPrice, this.categoryId});

  void setPriceRange(double? min, double? max) {
    minPrice = min;
    maxPrice = max;
    notifyListeners();
  }

  void setCategory(String? id) {
    categoryId = id == 'All' ? null : id;
    notifyListeners();
  }

  void reset() {
    minPrice = null;
    maxPrice = null;
    categoryId = null;
    notifyListeners();
  }

  bool get isActive => minPrice != null || maxPrice != null || categoryId != null;
}
