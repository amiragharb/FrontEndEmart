class SellerItem {
  final int sellerItemID;
  final int medicineID;
  final int sellerID;
  final int stockQuantity;
  final double price;
  final double? priceWas;
  final bool isOutOfStock;
  final String nameEn;
  final String nameAr;
  final String? photoUrl;

  final double avgRating;
  final int totalRatings;

  final String? indications;
  final String? pamphletEn;
  final String? pamphletAr;
  final String? packDescription;
  final String? youtubeURL;

  final List<String> imageUrls;

  int qty; // ✅ quantité

  SellerItem({
    required this.sellerItemID,
    required this.medicineID,
    required this.sellerID,
    required this.stockQuantity,
    required this.price,
    this.priceWas,
    required this.isOutOfStock,
    required this.nameEn,
    required this.nameAr,
    this.photoUrl,
    required this.avgRating,
    required this.totalRatings,
    this.indications,
    this.pamphletEn,
    this.pamphletAr,
    this.packDescription,
    this.youtubeURL,
    this.imageUrls = const [],
    this.qty = 1, // ✅ par défaut
  });

  factory SellerItem.fromJson(Map<String, dynamic> json) {
    String? finalUrl = json['photoUrl'];
    if (finalUrl != null) {
      finalUrl = finalUrl.replaceAll(" ", "%20");
    }

    return SellerItem(
      sellerItemID: json['SellerItemID'],
      medicineID: json['MedicineID'],
      sellerID: json['SellerID'],
      stockQuantity: json['StockQuantity'] ?? 0,
      price: (json['Price'] as num).toDouble(),
      priceWas: json['PriceWas'] != null ? (json['PriceWas'] as num).toDouble() : null,
      isOutOfStock: json['IsOutOfStock'] ?? false,
      nameEn: json['NameEn'] ?? "Unnamed",
      nameAr: json['NameAr'] ?? "",
      photoUrl: finalUrl,
      avgRating: (json['AvgRating'] ?? 0).toDouble(),
      totalRatings: json['TotalRatings'] ?? 0,
      indications: json['Indications'],
      pamphletEn: json['PamphletEn'],
      pamphletAr: json['PamphletAr'],
      packDescription: json['PackDescription'],
      youtubeURL: json['YoutubeURL'],
      imageUrls: (json['imageUrls'] as List?)?.map((e) => e.toString()).toList() ?? [],
      qty: json['Qty'] ?? 1, // ✅ récupération quantité
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'SellerItemID': sellerItemID,
      'MedicineID': medicineID,
      'SellerID': sellerID,
      'StockQuantity': stockQuantity,
      'Price': price,
      'PriceWas': priceWas,
      'IsOutOfStock': isOutOfStock,
      'NameEn': nameEn,
      'NameAr': nameAr,
      'photoUrl': photoUrl,
      'AvgRating': avgRating,
      'TotalRatings': totalRatings,
      'Indications': indications,
      'PamphletEn': pamphletEn,
      'PamphletAr': pamphletAr,
      'PackDescription': packDescription,
      'YoutubeURL': youtubeURL,
      'imageUrls': imageUrls,
      'Qty': qty, // ✅ sauvegarde quantité
    };
  }
}
