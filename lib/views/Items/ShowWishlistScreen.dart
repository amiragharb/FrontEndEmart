// lib/views/Wishlist/ShowWishlistScreen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:frontendemart/models/SellerItem_model.dart';
import 'package:frontendemart/viewmodels/Config_ViewModel.dart';
import 'package:frontendemart/viewmodels/CartViewModel.dart';
import 'package:frontendemart/viewmodels/wishlist_viewmodel_tmp.dart'; // <-- garde ton nom actuel
import 'package:frontendemart/views/homeAdmin/custom_bottom_navbar.dart';

class ShowWishlistScreen extends StatelessWidget {
  const ShowWishlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final _ = context.locale; // rebuild on language change

    final wish  = context.watch<WishlistViewModeltep>();
    final items = wish.items;

    final config = context.watch<ConfigViewModel>().config;
    final hex = config?.ciPrimaryColor?.replaceAll('#', '');
    final primaryColor = (hex != null && hex.isNotEmpty)
        ? Color(int.parse('FF$hex', radix: 16))
        : const Color(0xFF0B1E6D);

    final bg = const Color(0xFFF7F2F7); // léger rose/violet comme le profil

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: primaryColor,
        centerTitle: true,
        title: Text('wishlist'.tr(),
            style: TextStyle(color: primaryColor, fontWeight: FontWeight.w700)),
      ),

      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        children: [
          _HeaderPill(primaryColor: primaryColor, count: items.length),

          const SizedBox(height: 12),

          // Carte de section (comme "الحساب / الخدمات" dans le profil)
          _SectionCard(
            title: 'wishlist'.tr(),
            primaryColor: primaryColor,
            child: items.isEmpty
                ? _EmptySection(primaryColor: primaryColor)
                : Column(
                    children: List.generate(items.length, (i) {
                      final it = items[i];
                      return _WishRow(
                        item: it,
                        primaryColor: primaryColor,
                        isLast: i == items.length - 1,
                      );
                    }),
                  ),
          ),
        ],
      ),

      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 2),
    );
  }
}

/* ---------------------------- UI components ---------------------------- */

class _HeaderPill extends StatelessWidget {
  const _HeaderPill({required this.primaryColor, required this.count});
  final Color primaryColor;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 82,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primaryColor.withOpacity(.25), primaryColor.withOpacity(.15)],
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          // icône rond à gauche (comme le globe sur l’écran profil)
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: primaryColor.withOpacity(.25), blurRadius: 8, offset: const Offset(0, 3))],
            ),
            child: const Icon(Icons.favorite, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'wishlist'.tr(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: primaryColor,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // puce compteur (comme le badge dans ta capture)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              '${'items'.tr()} $count',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.primaryColor, required this.child});
  final String title;
  final Color primaryColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(.06), blurRadius: 14, offset: const Offset(0, 8))],
      ),
      child: Column(
        children: [
          // entête de section
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.centerRight,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              color: Colors.white,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    textAlign: TextAlign.start,
                    style: TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: primaryColor, shape: BoxShape.circle),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _EmptySection extends StatelessWidget {
  const _EmptySection({required this.primaryColor});
  final Color primaryColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(Icons.favorite_border, size: 56, color: primaryColor.withOpacity(.5)),
        const SizedBox(height: 8),
        Text('your_wishlist_is_empty'.tr(),
            style: TextStyle(color: primaryColor, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text('start_shopping_now'.tr(), style: TextStyle(color: Colors.grey.shade600)),
        const SizedBox(height: 10),
      ],
    );
  }
}

class _WishRow extends StatelessWidget {
  const _WishRow({required this.item, required this.primaryColor, required this.isLast});
  final SellerItem item;
  final Color primaryColor;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final url = (item.photoUrl?.trim().isNotEmpty == true)
        ? item.photoUrl!.trim()
        : (item.imageUrls.isNotEmpty ? item.imageUrls.first : '');

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // image
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 56,
                height: 56,
                child: url.isEmpty
                    ? Icon(Icons.image_not_supported, color: Colors.grey.shade400)
                    : Image.network(
                        url,
                        key: ValueKey(url),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            Icon(Icons.image_not_supported, color: Colors.grey.shade400),
                      ),
              ),
            ),
            const SizedBox(width: 12),

            // titre + prix
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.nameEn.isNotEmpty ? item.nameEn : item.nameAr,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${item.price.toStringAsFixed(0)} ${'currency_egp'.tr()}',
                    style: TextStyle(color: primaryColor, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),

            // actions à droite (comme mini icônes dans profil)
            Row(
              children: [
                // ajouter au panier
                Material(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () {
                      context.read<CartViewModel>().add(item, qty: 1);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('added_to_cart'.tr()),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    child: const SizedBox(
                      width: 42,
                      height: 42,
                      child: Icon(Icons.add_shopping_cart, color: Colors.white, size: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // supprimer
                Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => context.read<WishlistViewModeltep>().remove(item.sellerItemID),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.red.withOpacity(.25)),
                      ),
                      child: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        if (!isLast) Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Divider(height: 1, color: Colors.grey.shade200),
        ),
      ],
    );
  }
}
