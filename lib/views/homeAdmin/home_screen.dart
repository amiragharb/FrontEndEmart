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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  static const _primaryColor = Color(0xFFEE6B33);
  static const _backgroundColor = Color(0xFFF8FAFC);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkSession();
    });
  }

  Future<void> _checkSession() async {
    final authVM = Provider.of<AuthViewModel>(context, listen: false);
    await authVM.loadUserProfile();

    final user = authVM.userData;
    if (context.mounted && (user == null || user['username'] == null)) {
      _showSessionExpiredDialog();
    }
  }

  void _showSessionExpiredDialog() {
    final config = context.read<ConfigViewModel>().config;
    final primaryColor = (config?.ciPrimaryColor != null && config!.ciPrimaryColor!.isNotEmpty)
        ? Color(int.parse('FF${config.ciPrimaryColor}', radix: 16))
        : const Color(0xFF233B8E);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.info_outline, color: primaryColor, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'session_expired'.tr(),
                style: TextStyle(
                  color: primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'session_expired_message'.tr(),
              style: const TextStyle(fontSize: 15, color: Colors.black87),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.lock_outline, color: primaryColor, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'please_login_again'.tr(),
                      style: TextStyle(
                        fontSize: 13,
                        color: primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.login,
                (route) => false,
              );
            },
            style: TextButton.styleFrom(
              backgroundColor: primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'login'.tr(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
        ],
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
    );
  }

  void _showNoCategoryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("no_product".tr()),
        content: Text("category_empty".tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              "ok".tr(),
              style: const TextStyle(color: Colors.orange),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCarousel(ItemsViewModel vm) {
    if (vm.items.isEmpty) {
      return const SizedBox(
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
                        color: primaryColor,
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
                      color: primaryColor.withOpacity(0.8),
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
                        Flexible(child: _buildStars(item.avgRating, size: 14)),
                        const SizedBox(width: 4),
                        Text(
                          "(${item.totalRatings})",
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          overflow: TextOverflow.ellipsis,
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
                            color: primaryColor,
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

  Widget _buildBrandsRow(ItemsViewModel vm) {
    final list = vm.topBrandsOrCategories;
    if (list.isEmpty) {
      return const SizedBox(
        height: 120,
        child: Center(
          child: CircularProgressIndicator(color: HomeScreen._primaryColor),
        ),
      );
    }

    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: list.length,
        itemBuilder: (context, index) {
          final brand = list[index];
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

  double _toFiveScale(num? v) {
    final d = (v ?? 0).toDouble();
    final n = d > 5 ? d / 20.0 : d;
    return ((n.clamp(0, 5) * 2).round() / 2.0);
  }

  Widget _buildStars(num? rating, {double size = 16}) {
    final r = _toFiveScale(rating);
    final full = r.floor();
    final half = (r - full) >= 0.5;
    final empty = 5 - full - (half ? 1 : 0);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < full; i++)
          Icon(Icons.star, size: size, color: Colors.amber),
        if (half) Icon(Icons.star_half, size: size, color: Colors.amber),
        for (int i = 0; i < empty; i++)
          Icon(Icons.star_border, size: size, color: Colors.amber),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.locale.languageCode;
    final configVM = Provider.of<ConfigViewModel>(context);

    return ChangeNotifierProvider(
      create: (_) => ItemsViewModel()
        ..loadItems()
        ..loadCategories()
        ..loadTopBrandsOrCategories(),
      child: Scaffold(
        backgroundColor: HomeScreen._backgroundColor,
        body: SafeArea(
          child: Consumer<ItemsViewModel>(
            builder: (context, vm, child) {
              if (vm.isLoading && vm.items.isEmpty) {
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
                  _buildCarousel(vm),
                  _buildCategories(vm, locale, configVM),
                  const SizedBox(height: 32),
                  _buildSectionTitle('latest_items'.tr()),
                  _buildItemsHorizontal(vm.items, context, locale, configVM),
                  const SizedBox(height: 24),
                  _buildSectionTitle('best_sellers'.tr()),
                  _buildItemsHorizontal(vm.bestSellers, context, locale, configVM),
                  const SizedBox(height: 24),
                  _buildSectionTitle('top_brands'.tr()),
                  _buildBrandsRow(vm),
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
    final isRTL = Bidi.isRtlLanguage(Localizations.localeOf(context).languageCode);

    final config = context.watch<ConfigViewModel>().config;
    final hex = config?.ciPrimaryColor;
    final primaryColor = (hex != null && hex.isNotEmpty)
        ? Color(int.parse('FF$hex', radix: 16))
        : const Color(0xFF233B8E);

    final rawLogo = config?.ciLogo?.trim();
    final isNetworkLogo = rawLogo != null &&
        (rawLogo.startsWith('http://') || rawLogo.startsWith('https://'));
    final logoPath = rawLogo ?? "assets/logo_BlueTransparent.png";

    final cartCount = context.watch<CartViewModel>().items.length;

    final size = MediaQuery.of(context).size;
    final w = size.width;

    final actionsRow = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => Navigator.pushNamed(context, AppRoutes.orderHistory),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.history_rounded, color: Colors.white, size: 24),
                    Positioned(
                      right: -6,
                      top: -6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          shape: BoxShape.circle,
                          border: Border.all(color: primaryColor, width: 2),
                        ),
                        child: const Text(
                          '3',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        SizedBox(width: w * 0.025),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ShowCartScreen()),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 24),
                    if (cartCount > 0)
                      Positioned(
                        right: -8,
                        top: -8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: primaryColor, width: 2),
                          ),
                          child: Text(
                            '$cartCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );

    final logoChip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SizedBox(
        height: size.height * 0.035,
        child: isNetworkLogo
            ? Image.network(
                logoPath,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) =>
                    Icon(Icons.image, color: primaryColor),
              )
            : Image.asset(
                logoPath,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) =>
                    Icon(Icons.image, color: primaryColor),
              ),
      ),
    );

    final texts = Flexible(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          crossAxisAlignment:
              isRTL ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'welcome_back'.tr(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontSize: w * 0.045,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );

    final brandAndText = Expanded(
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: isRTL
            ? [texts, SizedBox(width: w * 0.03), logoChip]
            : [logoChip, SizedBox(width: w * 0.03), texts],
      ),
    );

    final children = isRTL
        ? <Widget>[actionsRow, SizedBox(width: w * 0.03), brandAndText]
        : <Widget>[brandAndText, SizedBox(width: w * 0.03), actionsRow];

    return Container(
      padding: EdgeInsets.fromLTRB(w * 0.04, 12, w * 0.04, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primaryColor,
            primaryColor.withOpacity(0.9),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: children,
        ),
      ),
    );
  }

  Widget _buildSearchBar(ItemsViewModel vm, ConfigViewModel configVM, BuildContext context) {
    final locale = context.locale.languageCode;
    final primary = (configVM.config?.ciPrimaryColor != null && configVM.config!.ciPrimaryColor!.isNotEmpty)
        ? Color(int.parse('FF${configVM.config!.ciPrimaryColor}', radix: 16))
        : const Color(0xFFEE6B33);

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
              if (textEditingValue.text.isEmpty) return const Iterable<String>.empty();
              final q = textEditingValue.text.toLowerCase();

              final cats = vm.categories
                  .where((c) => (locale == 'ar' ? c.nameAr : c.nameEn).toLowerCase().contains(q))
                  .map((c) => locale == 'ar' ? c.nameAr : c.nameEn);

              final prods = vm.items
                  .where((it) => (locale == 'ar' ? it.nameAr : it.nameEn).toLowerCase().contains(q))
                  .map((it) => locale == 'ar' ? it.nameAr : it.nameEn);

              return [...cats, ...prods];
            },
            onSelected: (String selection) async {
              final cat = vm.categories.firstWhere(
                (c) => (locale == 'ar' ? c.nameAr : c.nameEn).toLowerCase() == selection.toLowerCase(),
                orElse: () => Category(id: -1, nameEn: '', nameAr: '', logo: ''),
              );

              if (cat.id != -1) {
                await vm.filterByCategory(cat.id.toString());
                if (vm.items.isEmpty && !vm.isLoading && context.mounted) {
                  _showNoResultsDialog(
                    context,
                    "${locale == 'ar' ? 'الفئة' : 'Category'}: ${locale == 'ar' ? cat.nameAr : cat.nameEn}",
                  );
                  await vm.loadItems();
                }
              } else {
                vm.searchItems(selection);
                if (vm.items.isEmpty && !vm.isLoading && context.mounted) {
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
                onSubmitted: (_) => onFieldSubmitted(),
                textDirection: locale == 'ar' ? ui.TextDirection.rtl : ui.TextDirection.ltr,
                decoration: InputDecoration(
                  hintText: locale == 'ar'
                      ? "ابحث عن منتج أو فئة..."
                      : "Search for a product or category...",
                  prefixIcon: Icon(Icons.search, color: primary),
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
                    children: options.map((opt) {
                      return ListTile(
                        title: Text(
                          opt,
                          textDirection: locale == 'ar' ? ui.TextDirection.rtl : ui.TextDirection.ltr,
                        ),
                        onTap: () => onSelected(opt),
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
                      prefixIcon: Icon(Icons.category, color: primary),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    items: [
                      DropdownMenuItem(value: "All", child: Text(locale == 'ar' ? "الكل" : "All")),
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
                      if (vm.items.isEmpty && !vm.isLoading && context.mounted) {
                        _showNoCategoryDialog(context);
                        await vm.loadItems();
                      }
                    },
                  ),
                ),

                const SizedBox(width: 12),

                Flexible(
                  flex: 1,
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: vm.sortOption,
                    decoration: InputDecoration(
                      labelText: locale == 'ar' ? "ترتيب حسب" : "Sort by",
                      prefixIcon: Icon(Icons.sort, color: primary),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    items: [
                      DropdownMenuItem(value: "None", child: Text(locale == 'ar' ? "بدون ترتيب" : "None")),
                      DropdownMenuItem(value: "PriceAsc", child: Text(locale == 'ar' ? "السعر تصاعدي" : "Price Ascending")),
                      DropdownMenuItem(value: "PriceDesc", child: Text(locale == 'ar' ? "السعر تنازلي" : "Price Descending")),
                      DropdownMenuItem(value: "BestRated", child: Text(locale == 'ar' ? "الأعلى تقييماً" : "Best Rated")),
                    ],
                    onChanged: (value) => vm.sortItems(value ?? "None"),
                  ),
                ),

                const SizedBox(width: 12),

                IconButton(
                  tooltip: locale == 'ar' ? 'تصفية بالسعر' : 'Filter by price',
                  icon: const Icon(Icons.tune),
                  color: primary,
                  onPressed: () => _openPriceFilterSheet(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openPriceFilterSheet(BuildContext context) {
    final vm = context.read<ItemsViewModel>();

    final prices = vm.items.map((e) => (e.price ?? 0).toDouble()).toList();
    double minBound = prices.isEmpty ? 0.0 : prices.reduce((a, b) => a < b ? a : b);
    double maxBound = prices.isEmpty ? 1000.0 : prices.reduce((a, b) => a > b ? a : b);

    if (maxBound <= minBound) maxBound = minBound + 1.0;

    double clampMin(double v) => v.clamp(minBound, maxBound).toDouble();
    double clampMax(double v) => v.clamp(minBound, maxBound).toDouble();

    double currentMin = clampMin((vm.minPrice ?? minBound).toDouble());
    double currentMax = clampMax((vm.maxPrice ?? maxBound).toDouble());
    if (currentMin > currentMax) currentMin = currentMax;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            void setRange(double a, double b) {
              double s = clampMin(a);
              double e = clampMax(b);
              if (s > e) s = e;
              setState(() {
                currentMin = s;
                currentMax = e;
              });
            }

            final divisions = ((maxBound - minBound).round()).clamp(1, 1000);

            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  Text(
                    context.locale.languageCode == 'ar' ? 'تصفية حسب السعر' : 'Filter by price',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          initialValue: currentMin.toStringAsFixed(0),
                          decoration: InputDecoration(
                            labelText: context.locale.languageCode == 'ar' ? 'الحد الأدنى' : 'Min',
                            border: const OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (v) {
                            final d = double.tryParse(v) ?? currentMin;
                            setRange(d, currentMax);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          initialValue: currentMax.toStringAsFixed(0),
                          decoration: InputDecoration(
                            labelText: context.locale.languageCode == 'ar' ? 'الحد الأعلى' : 'Max',
                            border: const OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (v) {
                            final d = double.tryParse(v) ?? currentMax;
                            setRange(currentMin, d);
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  RangeSlider(
                    values: RangeValues(
                      currentMin.clamp(minBound, maxBound),
                      currentMax.clamp(minBound, maxBound),
                    ),
                    min: minBound,
                    max: maxBound,
                    divisions: divisions,
                    labels: RangeLabels(
                      currentMin.toStringAsFixed(0),
                      currentMax.toStringAsFixed(0),
                    ),
                    onChanged: (vals) => setRange(vals.start, vals.end),
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            await vm.resetFilters();
                            if (ctx.mounted) Navigator.pop(ctx);
                          },
                          child: Text(context.locale.languageCode == 'ar' ? 'إعادة الضبط' : 'Reset'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            vm.setPriceRange(currentMin, currentMax);
                            Navigator.pop(ctx);
                          },
                          child: Text(context.locale.languageCode == 'ar' ? 'تطبيق' : 'Apply'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        );
      },
    );
  }
}