import 'package:frontendemart/models/SellerItem_model.dart';

class CartItem {
  final int sellerItemId;
  final int medicineId;
  final String name;
  final double price;
  final String? photoUrl;
  int qty;

  CartItem({
    required this.sellerItemId,
    required this.medicineId,
    required this.name,
    required this.price,
    this.photoUrl,
    this.qty = 1,
  });

  factory CartItem.fromSellerItem(SellerItem item, {int qty = 1}) {
    return CartItem(
      sellerItemId: item.sellerItemID,
      medicineId: item.medicineID,
      name: item.nameEn.isNotEmpty ? item.nameEn : item.nameAr,
      price: (item.price as num).toDouble(),
      photoUrl: item.photoUrl,
      qty: qty,
    );
  }

  Map<String, dynamic> toJson() => {
        'sellerItemId': sellerItemId,
        'medicineId': medicineId,
        'name': name,
        'price': price,
        'photoUrl': photoUrl,
        'qty': qty,
      };

  factory CartItem.fromJson(Map<String, dynamic> j) => CartItem(
        sellerItemId: j['sellerItemId'],
        medicineId: j['medicineId'],
        name: j['name'],
        price: (j['price'] as num).toDouble(),
        photoUrl: j['photoUrl'],
        qty: j['qty'] ?? 1,
      );
}
