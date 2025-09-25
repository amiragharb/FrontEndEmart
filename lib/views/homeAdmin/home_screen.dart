import 'package:carousel_slider/carousel_slider.dart' as cs;
import 'package:flutter/material.dart';
import 'package:frontendemart/models/category_model.dart';
import 'package:frontendemart/routes/routes.dart';
import 'package:frontendemart/viewmodels/CartViewModel.dart';
import 'package:frontendemart/viewmodels/auth_viewmodel.dart';
import 'package:frontendemart/views/Ordres/ShowCartScreen.dart';
import 'package:frontendemart/views/homeAdmin/all_categories_screen.dart';
import 'package:frontendemart/views/homeAdmin/all_items_screen.dart';
import 'package:frontendemart/viewmodels/items_viewmodel.dart';
import 'package:frontendemart/views/Items/product_details_screen.dart';
import 'package:frontendemart/views/Items/CategoryItemsScreen.dart';
import 'package:provider/provider.dart';
import 'package:frontendemart/views/homeAdmin/custom_bottom_navbar.dart';
import 'package:easy_localization/easy_localization.dart';
import 'dart:ui' as ui;
import 'package:frontendemart/viewmodels/Config_ViewModel.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  static const _primaryColor = Color(0xFFEE6B33);
  // Removed unused _secondaryColor
  static const _backgroundColor = Color(0xFFF8FAFC);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
    List<Category> _topBrandsOrCategories = []; // <-- Déclaration ici
 
  void _showNoResultsDialog(BuildContext context, String query) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Aucun résultat"),
        content: Text("Aucun produit trouvé pour « $query »."),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("OK", style: TextStyle(color: Colors.orange)),
          )
        ],
      ),
    );
  }
  @override
  void initState() {
    super.initState();
    var vm = ItemsViewModel();
    vm.loadItems();
    vm.loadCategories();
    vm.loadTopBrandsOrCategories(); // <-- appel ici, une seule fois
  }
  void _showNoCategoryDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text("no_product".tr()), // clé pour la traduction
      content: Text("category_empty".tr()), // clé pour la traduction
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(
            "ok".tr(), // clé pour la traduction
            style: const TextStyle(color: Colors.orange),
          ),
        ),
      ],
    ),
  );
}


  Widget _buildCarousel() {
  return Consumer<ItemsViewModel>(
    builder: (context, vm, _) {
      if (vm.items.isEmpty) {
        // Placeholder ou loader si les items ne sont pas encore chargés
        return SizedBox(
          height: 200,
          child: Center(child: CircularProgressIndicator()),
        );
      }

      return TweenAnimationBuilder(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 1000),
        builder: (context, value, child) {
          return Transform.translate(
            offset: Offset(0, 30 * (1 - value)),
            child: Opacity(
              opacity: value,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: cs.CarouselSlider(
                  options: cs.CarouselOptions(
                    height: 200,
                    autoPlay: true,
                    enlargeCenterPage: true,
                    viewportFraction: 0.9,
                    autoPlayCurve: Curves.fastOutSlowIn,
                    autoPlayAnimationDuration: const Duration(milliseconds: 800),
                  ),
                  items: vm.items.map((item) {
                    final imageUrl = item.photoUrl ?? "assets/logo_BlueTransparent.png";
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            spreadRadius: 2,
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Stack(
                          children: [
                            imageUrl.startsWith('http')
                                ? Image.network(
                                    imageUrl,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                  )
                                : Image.asset(
                                    imageUrl,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                  ),
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withOpacity(0.3),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

Widget _buildCategories(ItemsViewModel vm, String locale, ConfigViewModel configVM) {
  final config = configVM.config;

  final primaryColor = (config?.ciPrimaryColor != null && config!.ciPrimaryColor!.isNotEmpty)
      ? Color(int.parse('FF${config.ciPrimaryColor}', radix: 16))
      : const Color(0xFFEE6B33);

  if (vm.categories.isEmpty) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.category_outlined, size: 48, color: primaryColor.withOpacity(0.7)),
            const SizedBox(height: 12),
            Text(
              'no_categories_found'.tr(),
              style: TextStyle(
                color: primaryColor.withOpacity(0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  final showCategories = vm.categories.length > 6 ? vm.categories.take(6).toList() : vm.categories;
  final showSeeMore = vm.categories.length > 6;

  return Container(
    height: 140,
    margin: const EdgeInsets.only(top: 24),
    child: ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: showCategories.length + (showSeeMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (showSeeMore && index == showCategories.length) {
          return TweenAnimationBuilder(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: Duration(milliseconds: 800 + (index * 100)),
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, 50 * (1 - value)),
                child: Opacity(
                  opacity: value,
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AllCategoriesScreen(categories: vm.categories),
                        ),
                      );
                    },
                    child: Container(
                      width: 100,
                      margin: const EdgeInsets.only(right: 16),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            spreadRadius: 1,
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.more_horiz, color: primaryColor, size: 32),
                          const SizedBox(height: 12),
                          Text(
                             'see_more'.tr(),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        }

        final cat = showCategories[index];
        return TweenAnimationBuilder(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 800 + (index * 100)),
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, 50 * (1 - value)),
              child: Opacity(
                opacity: value,
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CategoryItemsScreen(
                          categoryId: cat.id.toString(),
                          categoryName: locale == 'ar' ? cat.nameAr : cat.nameEn,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    width: 100,
                    margin: const EdgeInsets.only(right: 16),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
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
                            color: primaryColor,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.category,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            locale == 'ar' ? cat.nameAr : cat.nameEn,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    ),
  );
}


  Widget _buildSectionTitle(String title) {
    return TweenAnimationBuilder(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(-50 * (1 - value), 0),
          child: Opacity(
            opacity: value,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 24,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [HomeScreen._primaryColor, HomeScreen._primaryColor.withOpacity(0.7)],
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

Widget _buildItemsHorizontal(
    List items, BuildContext context, String locale, ConfigViewModel configVM) {
  final config = configVM.config;

  final primaryColor = (config?.ciPrimaryColor != null && config!.ciPrimaryColor!.isNotEmpty)
      ? Color(int.parse('FF${config.ciPrimaryColor}', radix: 16))
      : const Color(0xFFEE6B33);

  if (items.isEmpty) {
    return Container(
      height: 280,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_bag_outlined, size: 48, color: primaryColor.withOpacity(0.7)),
            const SizedBox(height: 12),
            Text(
              'no_products_found'.tr(),
              style: TextStyle(
                color: primaryColor.withOpacity(0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  final showItems = items.length > 6 ? items.take(6).toList() : items;
  final showSeeMore = items.length > 6;

  return SizedBox(
    height: 280,
    child: ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: showItems.length + (showSeeMore ? 1 : 0),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemBuilder: (context, index) {
        if (showSeeMore && index == showItems.length) {
          return TweenAnimationBuilder(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: Duration(milliseconds: 600 + (index * 100)),
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, 30 * (1 - value)),
                child: Opacity(
                  opacity: value,
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AllItemsScreen(
                            items: items,
                            title: 'all_items'.tr(),
                          ),
                        ),
                      );
                    },
                    child: Container(
                      width: 180,
                      margin: const EdgeInsets.only(right: 16),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            spreadRadius: 1,
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.more_horiz, color: primaryColor, size: 40),
                          const SizedBox(height: 12),
                          Text(
                            'see_more'.tr(),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        }

        final item = showItems[index];
        return TweenAnimationBuilder(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 600 + (index * 100)),
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, 30 * (1 - value)),
              child: Opacity(
                opacity: value,
                child: Container(
                  width: 180,
                  margin: const EdgeInsets.only(right: 16),
                  child: _buildModernProductCard(context, item, locale, configVM),
                ),
              ),
            );
          },
        );
      },
    ),
  );
}

Widget _buildModernProductCard(
    BuildContext context, item, String locale, ConfigViewModel configVM) {
  final config = configVM.config;

  final primaryColor = (config?.ciPrimaryColor != null && config!.ciPrimaryColor!.isNotEmpty)
      ? Color(int.parse('FF${config.ciPrimaryColor}', radix: 16))
      : const Color(0xFFEE6B33);

  final hasDiscount = item.priceWas != null && item.priceWas > item.price;
  final discountPercent = hasDiscount
      ? (((item.priceWas - item.price) / item.priceWas) * 100).round()
      : 0;

  return InkWell(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProductDetailsScreen(item: item),
        ),
      );
    },
    child: Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            spreadRadius: 1,
            blurRadius: 15,
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
                  child: Image.network(
                    item.photoUrl ?? "https://via.placeholder.com/150",
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey.shade100,
                      child: Icon(
                        Icons.image_not_supported,
                        size: 60,
                        color: Colors.grey.shade400,
                      ),
                    ),
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
                      color: primaryColor, // ✅ couleur importée
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
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
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.favorite_border,
                    size: 18,
                    color: primaryColor.withOpacity(0.8), // ✅ couleur importée
                  ),
                ),
              ),
            ],
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    locale == 'ar' ? item.nameAr ?? item.nameEn : item.nameEn,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _buildStars(item.avgRating, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        "(${item.totalRatings})",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Spacer(),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "${item.price.toInt()} ${'egp'.tr()}",
                        style: TextStyle(
                          fontSize: hasDiscount ? 20 : 18,
                          fontWeight: FontWeight.bold,
                          color: primaryColor, // ✅ couleur importée
                        ),
                      ),
                      if (hasDiscount) ...[
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            "${item.priceWas?.toInt()} ${'egp'.tr()}",
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              decoration: TextDecoration.lineThrough,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ),
                      ]
                    ],
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    ),
  );
}

  Widget _buildBrandsRow() {
  if (_topBrandsOrCategories.isEmpty) {
    // Affichage d'un loader ou placeholder si la liste est vide
    return SizedBox(
      height: 120,
      child: Center(
        child: CircularProgressIndicator(
          color: HomeScreen._primaryColor,
        ),
      ),
    );
  }

  return SizedBox(
    height: 120,
    child: ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _topBrandsOrCategories.length,
      itemBuilder: (context, index) {
        final brand = _topBrandsOrCategories[index];

        return TweenAnimationBuilder(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 600 + (index * 150)),
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: Container(
                width: 100,
                margin: const EdgeInsets.only(right: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
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
                child: InkWell(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${brand.nameEn} selected!'),
                        duration: const Duration(milliseconds: 1500),
                        backgroundColor: HomeScreen._primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(20),
                  splashColor: HomeScreen._primaryColor.withOpacity(0.1),
                  child: Center(
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        image: DecorationImage(
image: NetworkImage(brand.logo),
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    ),
  );
}


  Widget _buildStars(double rating, {double size = 16}) {
    final filledStars = rating.floor();
    final halfStar = (rating - filledStars) >= 0.5;
    final emptyStars = 5 - filledStars - (halfStar ? 1 : 0);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < filledStars; i++)
          Icon(Icons.star, color: Colors.amber, size: size),
        if (halfStar) Icon(Icons.star_half, color: Colors.amber, size: size),
        for (int i = 0; i < emptyStars; i++)
          Icon(Icons.star_border, color: Colors.amber, size: size),
      ],
    );
  }

  Widget _buildDropdown<T>({
    required T value,
    required String label,
    required IconData icon,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: HomeScreen._primaryColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      items: items,
      onChanged: onChanged,
    );
  }

  Future<void> _checkSession() async {
    final authVM = Provider.of<AuthViewModel>(context, listen: false);
    await authVM.loadUserProfile();
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.locale.languageCode;
    final configVM = Provider.of<ConfigViewModel>(context);

    return ChangeNotifierProvider(
      create: (_) => ItemsViewModel()
        ..loadItems()
        ..loadCategories(),
      child: Scaffold(
        backgroundColor: HomeScreen._backgroundColor,
        body: SafeArea(
          child: Consumer<ItemsViewModel>(
            builder: (context, vm, child) {
              if (vm.loading && vm.items.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TweenAnimationBuilder(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 1200),
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: 0.8 + (0.2 * value),
                            child: CircularProgressIndicator(
                              color: HomeScreen._primaryColor,
                              strokeWidth: 3,
                              value: value,
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'loading_products'.tr(),
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView(
                children: [
                  _buildHeader(context),
                  _buildSearchBar(vm, configVM, context),
                  _buildCarousel(),
                  _buildCategories(vm, locale, configVM),
                  const SizedBox(height: 32),
                  _buildSectionTitle('latest_items'.tr()),
                  _buildItemsHorizontal(vm.items, context, locale, configVM),
                  const SizedBox(height: 24),
                  _buildSectionTitle('best_sellers'.tr()),
                  _buildItemsHorizontal(vm.items, context, locale, configVM),
                  const SizedBox(height: 24),
                  _buildSectionTitle('top_brands'.tr()),
                  _buildBrandsRow(),
                  const SizedBox(height: 32),
                ],
              );
            },
          ),
        ),
        bottomNavigationBar: const CustomBottomNavBar(currentIndex: 0),
      ),
    );
  }

Widget _buildHeader(BuildContext context) {
  // Config / couleurs
  final config = context.watch<ConfigViewModel>().config;
  final hex = config?.ciPrimaryColor;
  final primaryColor = (hex != null && hex.isNotEmpty)
      ? Color(int.parse('FF$hex', radix: 16))
      : const Color(0xFFEE6B33);

  // Logo: URL réseau ou asset local
  final rawLogo = config?.ciLogo?.trim();
  final isNetworkLogo = rawLogo != null &&
      (rawLogo.startsWith('http://') || rawLogo.startsWith('https://'));
  final logoPath = rawLogo ?? "assets/logo_BlueTransparent.png";

  // Cart count (badge)
  final cartCount = context.watch<CartViewModel>().items.length;

  final w = MediaQuery.of(context).size.width;
  final h = MediaQuery.of(context).size.height;

  return Container(
    padding: EdgeInsets.symmetric(horizontal: w * 0.05, vertical: 16),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [primaryColor, primaryColor.withOpacity(0.8)],
      ),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Logo + textes
        Expanded(
          child: Row(
            children: [
              Hero(
                tag: 'app_logo',
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SizedBox(
                    height: h * 0.04,
                    child: isNetworkLogo
                        ? Image.network(
                            logoPath,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const Icon(Icons.image, color: Colors.white),
                          )
                        : Image.asset(
                            logoPath,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const Icon(Icons.image, color: Colors.white),
                          ),
                  ),
                ),
              ),
              SizedBox(width: w * 0.03),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'welcome_back'.tr(),
                      style: TextStyle(color: Colors.white70, fontSize: w * 0.04),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'lets_go_shopping'.tr(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: w * 0.05,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Actions droites: chat, panier (avec badge), notif
        Row(
  children: [
    // Icône Historique avec navigation vers la liste des commandes
    _buildModernCircleIcon(
      Icons.history,         // tu peux mettre Icons.history_rounded si tu préfères
      count: 3,
      onTap: () => Navigator.pushNamed(context, AppRoutes.orderHistory),
    ),

    SizedBox(width: w * 0.03),

    // Panier avec badge + navigation
    Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.shopping_cart, color: Colors.white, size: 22),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ShowCartScreen()),
              );
            },
          ),
        ),
        if (cartCount > 0)
          Positioned(
            right: 4,
            top: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.redAccent,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white, width: 1),
              ),
              child: Text(
                '$cartCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    ),

    SizedBox(width: w * 0.03),

    // Notifications (pas d’action pour l’instant)
    _buildModernCircleIcon(Icons.notifications_outlined, count: 6),
  ],
)
,
      ],
    ),
  );
}

  // Helper réutilisable — à mettre dans le même fichier (ou un widget util)
Widget _buildModernCircleIcon(
  IconData icon, {
  int count = 0,
  VoidCallback? onTap, // <— nouveau paramètre
}) {
  return Stack(
    clipBehavior: Clip.none,
    children: [
      Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: IconButton(
          icon: Icon(icon, color: Colors.white, size: 22),
          onPressed: onTap, // <— on utilise le callback ici
        ),
      ),
      if (count > 0)
        Positioned(
          right: 4,
          top: 4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.redAccent,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white, width: 1),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
    ],
  );
}


  Widget _buildSearchBar(ItemsViewModel vm, ConfigViewModel configVM, BuildContext context) {
  final locale = context.locale.languageCode;
  return Container(
    margin: EdgeInsets.symmetric(
      horizontal: MediaQuery.of(context).size.width * 0.05,
      vertical: 20,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RawAutocomplete<String>(
          optionsBuilder: (TextEditingValue textEditingValue) {
            if (textEditingValue.text.isEmpty) {
              return const Iterable<String>.empty();
            }
            final query = textEditingValue.text.toLowerCase();
            final categoryMatches = vm.categories
                .where((cat) => (locale == 'ar' ? cat.nameAr : cat.nameEn)
                    .toLowerCase()
                    .contains(query))
                .map((cat) => locale == 'ar' ? cat.nameAr : cat.nameEn);
            final productMatches = vm.items
                .where((item) => (locale == 'ar' ? item.nameAr : item.nameEn)
                    .toLowerCase()
                    .contains(query))
                .map((item) => locale == 'ar' ? item.nameAr : item.nameEn);
            return [...categoryMatches, ...productMatches];
          },
          onSelected: (String selection) async {
            final categoryMatch = vm.categories.firstWhere(
              (cat) => (locale == 'ar' ? cat.nameAr : cat.nameEn)
                  .toLowerCase() ==
                  selection.toLowerCase(),
              orElse: () => Category(id: -1, nameEn: '', nameAr: '', logo: ''),
            );
            if (categoryMatch.id != -1) {
              await vm.filterByCategory(categoryMatch.id.toString());
              if (vm.items.isEmpty && !vm.loading && context.mounted) {
                _showNoResultsDialog(
                  context,
                  "${locale == 'ar' ? 'الفئة' : 'Category'}: ${locale == 'ar' ? categoryMatch.nameAr : categoryMatch.nameEn}",
                );
                await vm.loadItems();
              }
            } else {
              vm.searchItems(selection);
              if (vm.items.isEmpty && !vm.loading && context.mounted) {
                _showNoResultsDialog(
                  context,
                  "${locale == 'ar' ? 'المنتج' : 'Product'}: $selection",
                );
                await vm.loadItems();
              }
            }
          },
          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
            return TextField(
              controller: controller,
              focusNode: focusNode,
              onSubmitted: (query) => onFieldSubmitted(),
              textDirection: locale == 'ar'
                  ? ui.TextDirection.rtl
                  : ui.TextDirection.ltr,
              decoration: InputDecoration(
                hintText: locale == 'ar'
                    ? "ابحث عن منتج أو فئة..."
                    : "Search for a product or category...",
                prefixIcon: Icon(
                  Icons.search,
                  color: (configVM.config?.ciPrimaryColor != null && configVM.config!.ciPrimaryColor!.isNotEmpty)
                      ? Color(int.parse('FF${configVM.config!.ciPrimaryColor}', radix: 16))
                      : const Color(0xFFEE6B33),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            );
          },
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4.0,
                child: ListView(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  children: options.map((option) {
                    return ListTile(
                      title: Text(option,
                          textDirection: locale == 'ar'
                              ? ui.TextDirection.rtl
                              : ui.TextDirection.ltr),
                      onTap: () => onSelected(option),
                    );
                  }).toList(),
                ),
              ),
            );
          },
        ),
        SizedBox(height: MediaQuery.of(context).size.height * 0.02),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              Flexible(
                flex: 1,
                child: DropdownButtonFormField<String>(
                  isExpanded: true,
                  value: vm.selectedCategory,
                  decoration: InputDecoration(
                    labelText: locale == 'ar' ? "الفئة" : "Category",
                    prefixIcon: Icon(
                      Icons.category,
                      color: (configVM.config?.ciPrimaryColor != null && configVM.config!.ciPrimaryColor!.isNotEmpty)
                          ? Color(int.parse('FF${configVM.config!.ciPrimaryColor}', radix: 16))
                          : const Color(0xFFEE6B33),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items: [
                    DropdownMenuItem(
                        value: "All",
                        child: Text(locale == 'ar' ? "الكل" : "All")),
                    ...vm.categories.map(
                      (cat) => DropdownMenuItem(
                        value: cat.id.toString(),
                        child: Text(
                          locale == 'ar' ? cat.nameAr : cat.nameEn,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ),
                  ],
                  onChanged: (value) async {
                    if (value == "All") {
                      await vm.loadItems();
                    } else {
                      await vm.filterByCategory(value);
                    }
                    if (vm.items.isEmpty && !vm.loading && context.mounted) {
                      _showNoCategoryDialog(context);
                      await vm.loadItems();
                    }
                  },
                ),
              ),
              SizedBox(width: 12),
              Flexible(
                flex: 1,
                child: DropdownButtonFormField<String>(
                  isExpanded: true,
                  value: vm.sortOption,
                  decoration: InputDecoration(
                    labelText: locale == 'ar' ? "ترتيب حسب" : "Sort by",
                    prefixIcon: Icon(
                      Icons.sort,
                      color: (configVM.config?.ciPrimaryColor != null && configVM.config!.ciPrimaryColor!.isNotEmpty)
                          ? Color(int.parse('FF${configVM.config!.ciPrimaryColor}', radix: 16))
                          : const Color(0xFFEE6B33),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items: [
                    DropdownMenuItem(
                        value: "None",
                        child: Text(locale == 'ar' ? "بدون ترتيب" : "None")),
                    DropdownMenuItem(
                        value: "PriceAsc",
                        child: Text(locale == 'ar'
                            ? "السعر تصاعدي"
                            : "Price Ascending")),
                    DropdownMenuItem(
                        value: "PriceDesc",
                        child: Text(locale == 'ar'
                            ? "السعر تنازلي"
                            : "Price Descending")),
                    DropdownMenuItem(
                        value: "BestRated",
                        child: Text(locale == 'ar'
                            ? "الأعلى تقييماً"
                            : "Best Rated")),
                  ],
                  onChanged: (value) async {
                    vm.sortItems(value ?? "None");
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}}
