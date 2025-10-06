import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';

import 'package:frontendemart/viewmodels/Config_ViewModel.dart';
import 'package:frontendemart/views/homeAdmin/custom_bottom_navbar.dart';
import '../Items/product_details_screen.dart';

class AllItemsScreen extends StatelessWidget {
  final List items;
  final String title;

  const AllItemsScreen({
    super.key,
    required this.items,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final locale = context.locale.languageCode;

    // Couleur primaire depuis la config backend (fallback si absent)
    final cfg = context.watch<ConfigViewModel>().config;
    final primaryColor = (cfg?.ciPrimaryColor != null && cfg!.ciPrimaryColor!.isNotEmpty)
        ? Color(int.parse('FF${cfg.ciPrimaryColor}', radix: 16))
        : const Color(0xFFEE6B33);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w700),
          overflow: TextOverflow.ellipsis,
        ),
        elevation: 0,
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.68,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];

          // Données sûres
          final name = locale == 'ar'
              ? (item.nameAr ?? item.nameEn ?? '')
              : (item.nameEn ?? item.nameAr ?? '');
          final imageUrl = item.photoUrl ?? 'https://via.placeholder.com/150';
          final priceTxt = "${(item.price ?? 0).toInt()} ${tr('egp')}";

          return InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ProductDetailsScreen(item: item)),
            ),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(.08),
                    spreadRadius: 1,
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Image
                  Expanded(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                      child: Container(
                        color: Colors.grey.shade50,
                        width: double.infinity,
                        height: double.infinity,
                        child: imageUrl.startsWith('http')
                            ? Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _imageFallback(),
                              )
                            : Image.asset(
                                imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _imageFallback(),
                              ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Nom du produit avec bordure couleur primaire
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        border: Border.all(color: primaryColor, width: 1.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: primaryColor, // texte visible
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Prix
                  Text(
                    priceTxt,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                      fontSize: 14,
                    ),
                  ),

                  const SizedBox(height: 10),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 0),
    );
  }

  // Widget fallback d'image
  Widget _imageFallback() => Container(
        color: Colors.grey.shade100,
        child: Icon(
          Icons.image_not_supported,
          size: 56,
          color: Colors.grey.shade400,
        ),
      );
}
