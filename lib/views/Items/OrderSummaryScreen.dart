import 'package:flutter/material.dart';
import 'package:frontendemart/models/SellerItem_model.dart';
import 'package:frontendemart/models/UserLocation_model.dart';
import 'package:frontendemart/services/cart_service.dart';
import 'package:frontendemart/views/Items/Summary2Screenscreen.dart';

class OrderSummaryScreen extends StatefulWidget {
  const OrderSummaryScreen({super.key});

  @override
  State<OrderSummaryScreen> createState() => _OrderSummaryScreenState();
}

class _OrderSummaryScreenState extends State<OrderSummaryScreen> {
  List<SellerItem> _items = [];

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  Future<void> _loadCart() async {
    final items = await CartService.getCartItems();
    setState(() {
      _items = items;
    });
  }

  double get total =>
      _items.fold(0, (sum, item) => sum + (item.price * (item.qty ?? 1)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Order Summary"),
        centerTitle: true,
        backgroundColor: Colors.deepOrange,
      ),
      body: _items.isEmpty
          ? const Center(
              child: Text(
                "Your cart is empty",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: _items.length,
                    itemBuilder: (ctx, i) {
                      final item = _items[i];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 3,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              // 🖼 Image
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  item.photoUrl ??
                                      "https://via.placeholder.com/100",
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                  errorBuilder: (ctx, error, stackTrace) {
                                    return Container(
                                      width: 60,
                                      height: 60,
                                      color: Colors.grey.shade200,
                                      child: const Icon(Icons.image_not_supported,
                                          color: Colors.grey),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),

                              // Infos produit
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.nameEn,
                                        style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 6),
                                    Text(
                                      "${item.price.toStringAsFixed(2)} EGP",
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.green,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Quantité + supprimer
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle,
                                        color: Colors.redAccent),
                                    onPressed: () {
                                      setState(() {
                                        if ((item.qty ?? 1) > 1) {
                                          item.qty = (item.qty ?? 1) - 1;
                                        }
                                      });
                                    },
                                  ),
                                  Text("${item.qty ?? 1}",
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold)),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle,
                                        color: Colors.green),
                                    onPressed: () {
                                      setState(() {
                                        item.qty = (item.qty ?? 1) + 1;
                                      });
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
                                    onPressed: () async {
                                      await CartService.removeFromCart(
                                          item.sellerItemID);
                                      _loadCart();
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Footer avec total + checkout
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Total: ${total.toStringAsFixed(2)} EGP",
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepOrange,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () async {
                          // 📦 Récupérer les produits du panier
                          final items = await CartService.getCartItems();

                          // 📍 Récupérer les adresses enregistrées
                          final addresses = await CartService.getAddresses();

                          if (addresses.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text("⚠️ Aucune adresse trouvée !")),
                            );
                            return;
                          }

                          final selectedAddress = addresses.first; // 👉 Par défaut

                          // ➡️ Navigation vers Summary2Screen
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => Summary2Screen(
                                items: items,
                                selectedAddress: selectedAddress,
                              ),
                            ),
                          );
                        },
                        child: const Text(
                          "Checkout",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
    );
  }
}
