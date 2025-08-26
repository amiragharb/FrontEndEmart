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

  // ⭐ Champs pour les évaluations
  final double avgRating;
  final int totalRatings;

  // 📝 Champs de description
  final String? indications;
  final String? pamphletEn;
  final String? pamphletAr;
  final String? packDescription;
  final String? youtubeURL;

  // 🖼️ Liste complète des photos
  final List<String> imageUrls;

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

      // 📝 Champs description
      indications: json['Indications'],
      pamphletEn: json['PamphletEn'],
      pamphletAr: json['PamphletAr'],
      packDescription: json['PackDescription'],
      youtubeURL: json['YoutubeURL'],

      // 🖼️ Liste d'images
      imageUrls: (json['imageUrls'] as List?)?.map((e) => e.toString()).toList() ?? [],
    );
  }
}
