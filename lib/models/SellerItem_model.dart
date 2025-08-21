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
  });

factory SellerItem.fromJson(Map<String, dynamic> json) {
  String? finalUrl = json['photoUrl'];

  // Encode juste les espaces par sécurité
  if (finalUrl != null) {
    finalUrl = finalUrl.replaceAll(" ", "%20");
  }

  return SellerItem(
    sellerItemID: json['SellerItemID'],
    medicineID: json['MedicineID'],
    sellerID: json['SellerID'],
    stockQuantity: json['StockQuantity'],
    price: (json['Price'] as num).toDouble(),
    priceWas: json['PriceWas'] != null ? (json['PriceWas'] as num).toDouble() : null,
    isOutOfStock: json['IsOutOfStock'] ?? false,
    nameEn: json['NameEn'] ?? "Unnamed",
    nameAr: json['NameAr'] ?? "",
    photoUrl: finalUrl,
  );
}



}
