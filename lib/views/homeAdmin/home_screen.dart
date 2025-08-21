import 'dart:async';
import 'package:carousel_slider/carousel_slider.dart' as cs;
import 'package:flutter/material.dart';
import 'package:frontendemart/models/category_model.dart';
import 'package:frontendemart/viewmodels/items_viewmodel.dart';
import 'package:frontendemart/views/homeAdmin/CategoryItemsScreen.dart';
import 'package:provider/provider.dart';
import 'package:frontendemart/views/homeAdmin/custom_bottom_navbar.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // Couleurs cohérentes avec la navigation
  static const _primaryColor = Color(0xFFEE6B33);
  static const _secondaryColor = Color(0xFF6366F1);
  static const _backgroundColor = Color(0xFFF8FAFC);

  @override
Widget build(BuildContext context) {
  return ChangeNotifierProvider(
    create: (_) => ItemsViewModel()
      ..loadItems()
      ..loadCategories(),
    child: Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: Consumer<ItemsViewModel>(
          builder: (context, vm, child) {
            // ⏳ Premier chargement avec spinner
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
                            color: _primaryColor,
                            strokeWidth: 3,
                            value: value,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Loading amazing products...",
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

            // ✅ Sinon → toujours la Home avec ses sections
            return ListView(
              children: [
                _buildHeader(context),
                _buildSearchBar(vm, context),
                _buildCarousel(),
                _buildCategories(vm),
                const SizedBox(height: 32),
                _buildSectionTitle("🆕 Latest Items"),
                _buildItemsHorizontal(vm.items, context),
                const SizedBox(height: 24),
                _buildSectionTitle("🔥 Best Sellers"),
                _buildItemsHorizontal(vm.bestSellers, context),
                const SizedBox(height: 24),
                _buildSectionTitle("⭐ Top Brands"),
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

  /// ------------------------
  /// HEADER
  /// ------------------------
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_primaryColor, _primaryColor.withOpacity(0.8)],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Hero(
                tag: 'app_logo',
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Image.asset(
                    "assets/logo_BlueTransparent.png",
                    height: 32,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    "Welcome back!",
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  Text(
                    "Let's go shopping",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                ],
              ),
            ],
          ),
          Row(
            children: [
              _buildModernCircleIcon(Icons.chat_bubble_outline, count: 3),
              const SizedBox(width: 12),
              _buildModernCircleIcon(Icons.shopping_bag_outlined, count: 12),
              const SizedBox(width: 12),
              _buildModernCircleIcon(Icons.notifications_outlined, count: 6),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildModernCircleIcon(IconData icon, {int count = 0}) {
    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        if (count > 0)
          Positioned(
            right: -2,
            top: -2,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                "$count",
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
      ],
    );
  }

  /// ------------------------
  /// SEARCH + FILTERS
  /// ------------------------
  /// ------------------------
  /// SEARCH + FILTERS
  /// ------------------------
  Widget _buildSearchBar(ItemsViewModel vm, BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔍 Barre de recherche
       RawAutocomplete<String>(
  optionsBuilder: (TextEditingValue textEditingValue) {
    if (textEditingValue.text.isEmpty) {
      return const Iterable<String>.empty();
    }

    final query = textEditingValue.text.toLowerCase();

    // 🔹 Suggestions = noms des catégories + noms des produits
    final categoryMatches = vm.categories
        .where((cat) => cat.nameEn.toLowerCase().contains(query))
        .map((cat) => cat.nameEn);

    final productMatches = vm.items
        .where((item) => item.nameEn.toLowerCase().contains(query))
        .map((item) => item.nameEn);

    return [...categoryMatches, ...productMatches];
  },
 onSelected: (String selection) async {
  // 🔹 Vérifier si c’est une catégorie
  final categoryMatch = vm.categories.firstWhere(
    (cat) => cat.nameEn.toLowerCase() == selection.toLowerCase(),
    orElse: () => null as Category, // ⚠️ à remplacer par firstWhereOrNull si possible
  );

  if (categoryMatch != null) {
    await vm.filterByCategory(categoryMatch.id.toString());

    if (vm.items.isEmpty && !vm.loading && context.mounted) {
      _showNoResultsDialog(context, "Catégorie: ${categoryMatch.nameEn}");

      // 🔥 Recharge la homepage normale
      await vm.loadItems();
    }
  } else {
    // 🔹 Sinon recherche produit
 vm.searchItems(selection);

    if (vm.items.isEmpty && !vm.loading && context.mounted) {
      _showNoResultsDialog(context, "Produit: $selection");

      // 🔥 Recharge la homepage normale
      await vm.loadItems();
    }
  }
},

  fieldViewBuilder:
      (context, controller, focusNode, onFieldSubmitted) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      onSubmitted: (query) => onFieldSubmitted(),
      decoration: InputDecoration(
        hintText: "Rechercher un produit ou une catégorie...",
        prefixIcon: Icon(Icons.search, color: _primaryColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  },
  optionsViewBuilder:
      (context, onSelected, options) {
    return Align(
      alignment: Alignment.topLeft,
      child: Material(
        elevation: 4.0,
        child: ListView(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          children: options.map((option) {
            return ListTile(
              title: Text(option),
              onTap: () => onSelected(option),
            );
          }).toList(),
        ),
      ),
    );
  },
)

,

          const SizedBox(height: 20),

          // 🗂️ Filtres
          Row(
            children: [
              Expanded(
                child: _buildDropdown<String>(
                  value: vm.selectedCategory,
                  label: "Category",
                  icon: Icons.category,
                  items: [
                    const DropdownMenuItem(
                        value: "All", child: Text("All")),
                    ...vm.categories.map(
                      (cat) => DropdownMenuItem(
                        value: cat.id.toString(),
                        child: Text(
                          cat.nameEn,
                          overflow: TextOverflow.ellipsis, // ✅ coupe le texte
                        ),
                      ),
                    ),
                  ],
                  onChanged: (value) async {
  if (value == "All") {
    await vm.loadItems(); // 🔥 retour à tous les produits
  } else {
    await vm.filterByCategory(value);
  }

  if (vm.items.isEmpty && !vm.loading && context.mounted) {
    _showNoCategoryDialog(context);

    // 🔥 Recharge la homepage normale
    await vm.loadItems();
  }
},

                ),
              ),
              const SizedBox(width: 16),
              Expanded(
  child: _buildDropdown<String>(
    value: vm.sortOption,
    label: "Sort by",
    icon: Icons.sort,
    items: ["None", "PriceAsc", "PriceDesc", "BestRated"]
        .map(
          (sort) => DropdownMenuItem(
            value: sort,
            child: Text(
              sort,
              overflow: TextOverflow.ellipsis, // ✅ coupe si long
            ),
          ),
        )
        .toList(),
    onChanged: (value) async {
      if (value == "None") {
        await vm.loadItems(); // 🔥 retour à la homepage par défaut
      } else {
        vm.sortItems(value!);
      }

      if (vm.items.isEmpty && !vm.loading && context.mounted) {
        _showNoResultsDialog(context, "Aucun produit pour ce tri");

        // 🔥 Recharge la homepage normale
        await vm.loadItems();
      }
    },
  ),
),

            ],
          ),
        ],
      ),
    );
  }

  /// ------------------------
  /// DROPDOWN corrigé
  /// ------------------------
  Widget _buildDropdown<T>({
    required T value,
    required String label,
    required IconData icon,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
  }) {
    return DropdownButtonFormField<T>(
      isExpanded: true, // ✅ évite l’overflow
      value: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: _primaryColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      items: items,
      onChanged: onChanged,
    );
  }

  
  /// ------------------------
  /// POPUPS
  /// ------------------------
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

  void _showNoCategoryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Aucun produit"),
        content: const Text("Cette catégorie ne contient aucun produit."),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("OK", style: TextStyle(color: Colors.orange)),
          )
        ],
      ),
    );
  }

  // ... (le reste de ton code _buildCarousel, _buildCategories, _buildItemsHorizontal, etc. reste identique)



  Widget _buildCarousel() {
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
                items: [
                  "assets/logo_BlueTransparent.png",

                  "assets/logo_BlueTransparent.png",
                  "assets/logo_BlueTransparent.png",
                ].map((img) {
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
                          Image.asset(
                            img, 
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

  Widget _buildCategories(ItemsViewModel vm) {
    if (vm.categories.isEmpty) {
      return Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.category_outlined, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              Text(
                "No categories found 😕",
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      height: 140,
      margin: const EdgeInsets.only(top: 24),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: vm.categories.length,
        itemBuilder: (context, index) {
          final cat = vm.categories[index];
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
                            categoryName: cat.nameEn,
                          ),
                        ),
                      );
                    },
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
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [_primaryColor, _primaryColor.withOpacity(0.8)],
                              ),
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
                              cat.nameEn,
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
                        colors: [_primaryColor, _primaryColor.withOpacity(0.7)],
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

  Widget _buildItemsHorizontal(List items, BuildContext context) {
    if (items.isEmpty) {
      return Container(
        height: 280,
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.shopping_bag_outlined, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              Text(
                "No products found",
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: 280,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemBuilder: (context, index) {
          final item = items[index];
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
                    child: _buildModernProductCard(item),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildModernProductCard(item) {
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
)

,
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
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.3),
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
                  child: const Icon(
                    Icons.favorite_border,
                    size: 18,
                    color: Colors.grey,
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
                    item.nameEn,
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
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
  "${item.price}",   // ✅ affiche la valeur
  style: TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: Colors.green.shade700,
  ),
),

                      ),
                      if (hasDiscount) ...[
                        const SizedBox(width: 8),
                        Text(
  "${item.priceWas}",
  style: TextStyle(
    fontSize: 12,
    decoration: TextDecoration.lineThrough,
    color: Colors.grey.shade500,
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
    );
  }

  Widget _buildBrandsRow() {
    final brands = [
      "logo_BlueTransparent.png",
      "logo_BlueTransparent.png",
      "logo_BlueTransparent.png",
      "logo_BlueTransparent.png",
    ];

    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: brands.length,
        itemBuilder: (context, index) {
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
                      // Animation de feedback au tap
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Brand ${index + 1} selected!'),
                          duration: const Duration(milliseconds: 1500),
                          backgroundColor: _primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(20),
                    splashColor: _primaryColor.withOpacity(0.1),
                    child: Center(
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          image: DecorationImage(
                            image: AssetImage(brands[index]),
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
}