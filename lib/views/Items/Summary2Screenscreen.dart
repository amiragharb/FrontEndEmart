import 'package:flutter/material.dart';
import 'package:frontendemart/models/SellerItem_model.dart';
import 'package:frontendemart/models/UserLocation_model.dart';

class Summary2Screen extends StatelessWidget {
  final List<SellerItem> items;
  final UserLocation selectedAddress;

  const Summary2Screen({
    super.key,
    required this.items,
    required this.selectedAddress,
  });

  double get total =>
      items.fold(0, (sum, item) => sum + (item.price * (item.qty ?? 1)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Confirm Order"),
        backgroundColor: Colors.deepOrange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ✅ Adresse choisie
            Card(
              color: Colors.orange.shade50,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: const Icon(Icons.location_on, color: Colors.deepOrange),
                title: Text(selectedAddress.address),
                subtitle: Text(
                  "${selectedAddress.labelName ?? ""}\n"
                  "GPS: ${selectedAddress.latitude ?? "?"}, ${selectedAddress.longitude ?? "?"}",
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ✅ Liste des produits
            Expanded(
              child: ListView.builder(
                itemCount: items.length,
                itemBuilder: (ctx, i) {
                  final item = items[i];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      leading: Image.network(
                        item.photoUrl ?? "https://via.placeholder.com/80",
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.image_not_supported),
                      ),
                      title: Text(item.nameEn),
                      subtitle: Text(
                        "${item.price.toStringAsFixed(2)} EGP  x${item.qty ?? 1}",
                      ),
                      trailing: Text(
                        "${(item.price * (item.qty ?? 1)).toStringAsFixed(2)} EGP",
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green),
                      ),
                    ),
                  );
                },
              ),
            ),

            // ✅ Total + bouton Confirmer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Total: ${total.toStringAsFixed(2)} EGP",
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                    onPressed: () {
                      // 👉 Appel API de création de commande ici
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Order confirmed ✅")),
                      );
                    },
                    child: const Text("Confirm"),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
