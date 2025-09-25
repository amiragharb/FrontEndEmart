import 'package:flutter/material.dart';
import 'package:frontendemart/viewmodels/items_viewmodel.dart';
import 'package:frontendemart/views/homeAdmin/custom_bottom_navbar.dart';
import 'package:frontendemart/viewmodels/Config_ViewModel.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';

class CategoryItemsScreen extends StatelessWidget {
  final String categoryId;
  final String categoryName;

  const CategoryItemsScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  // Fonction utilitaire pour parser la couleur depuis la config
  Color _parsePrimaryColor(ConfigViewModel configVM) {
    final colorString = configVM.config?.ciPrimaryColor;
    if (colorString != null && colorString.isNotEmpty) {
      try {
        return Color(int.parse('FF${colorString.replaceAll('#', '')}', radix: 16));
      } catch (_) {}
    }
    return const Color(0xFFEE6B33); // fallback
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.locale.languageCode;
    final configVM = context.watch<ConfigViewModel>();
    final primaryColor = _parsePrimaryColor(configVM);

    return ChangeNotifierProvider(
      create: (_) => ItemsViewModel()..loadItems(category: categoryId),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: primaryColor,
          title: Text(
            categoryName,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white, // titre en blanc
            ),
          ),
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.white), // icône retour en blanc
        ),
        body: Consumer<ItemsViewModel>(
          builder: (context, vm, child) {
            if (vm.loading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (vm.items.isEmpty) {
              return _buildEmptyState(primaryColor);
            }
            return GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.68,
              ),
              itemCount: vm.items.length,
              itemBuilder: (context, index) {
                final item = vm.items[index];
                return _buildModernProductCard(item, locale, primaryColor);
              },
            );
          },
        ),
        bottomNavigationBar: const CustomBottomNavBar(currentIndex: 0),
      ),
    );
  }

  Widget _buildModernProductCard(item, String locale, Color primaryColor) {
    final hasDiscount = item.priceWas != null && item.priceWas > item.price;
    final discountPercent = hasDiscount
        ? (((item.priceWas - item.price) / item.priceWas) * 100).round()
        : 0;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: Container(
                  height: 140,
                  width: double.infinity,
                  color: Colors.grey.shade50,
                  child: item.photoUrl != null && item.photoUrl.isNotEmpty
                      ? Image.network(
                          item.photoUrl,
                          fit: BoxFit.cover,
                        )
                      : Center(
                          child: Icon(Icons.image_not_supported, size: 60, color: Colors.grey.shade400),
                        ),
                ),
              ),
              if (hasDiscount)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "-$discountPercent%",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    locale == 'ar' ? (item.nameAr ?? item.nameEn) : item.nameEn,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "${item.price.toInt()} ${'egp'.tr()}",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                      ),
                      if (hasDiscount) ...[
                        const SizedBox(width: 8),
                        Text(
                          "${item.priceWas.toInt()} ${'egp'.tr()}",
                          style: TextStyle(
                            fontSize: 12,
                            decoration: TextDecoration.lineThrough,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildEmptyState(Color primaryColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 80, color: primaryColor),
          const SizedBox(height: 16),
          Text(
            'no_products_found'.tr(),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'try_another_category'.tr(),
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}
