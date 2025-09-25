import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:frontendemart/views/homeAdmin/custom_bottom_navbar.dart';
import '../../models/category_model.dart';
import '../Items/CategoryItemsScreen.dart';
import 'package:frontendemart/viewmodels/Config_ViewModel.dart';
import 'package:provider/provider.dart';

class AllCategoriesScreen extends StatelessWidget {
  final List<Category> categories;
  const AllCategoriesScreen({super.key, required this.categories});

  @override
  Widget build(BuildContext context) {
    final locale = EasyLocalization.of(context)!.locale.languageCode;

    // Récupération config backend
    final configVM = Provider.of<ConfigViewModel>(context);
    final config = configVM.config;

    // Couleur primaire dynamique avec fallback
    final primaryColor = (config?.ciPrimaryColor != null && config!.ciPrimaryColor!.isNotEmpty)
        ? Color(int.parse('FF${config.ciPrimaryColor}', radix: 16))
        : const Color(0xFFEE6B33);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'all_categories'.tr(),
          style: const TextStyle(color: Colors.white), // titre AppBar en blanc
        ),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white), // icônes de la AppBar en blanc
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.1,
        ),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          return InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CategoryItemsScreen(
                    categoryId: cat.id.toString(),
                    categoryName: locale == 'ar' ? cat.nameAr ?? '' : cat.nameEn ?? '',
                  ),
                ),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white, // fond de la carte
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [primaryColor, primaryColor.withOpacity(0.8)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.category,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      locale == 'ar' ? cat.nameAr ?? '' : cat.nameEn ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: primaryColor, // texte catégorie en couleur primaire
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 0),
    );
  }
}
