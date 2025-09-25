import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:frontendemart/views/homeAdmin/custom_bottom_navbar.dart';
import 'package:provider/provider.dart';

import 'package:frontendemart/models/SellerItem_model.dart';
import 'package:frontendemart/viewmodels/CartViewModel.dart';
import 'package:frontendemart/viewmodels/Config_ViewModel.dart';
import 'package:frontendemart/views/Ordres/OrderSummaryScreen.dart';

/* ---------- Helper couleur primaire robuste ---------- */
Color parseHexColor(String? hex, {Color fallback = const Color(0xFFEE6B33)}) {
  if (hex == null) return fallback;
  var s = hex.trim();
  if (s.isEmpty) return fallback;

  s = s.replaceAll('#', '');
  if (s.toLowerCase().startsWith('0x')) s = s.substring(2);
  if (s.length == 6) s = 'FF$s'; // ajoute alpha si manquant

  final val = int.tryParse(s, radix: 16);
  return val != null ? Color(val) : fallback;
}

class ShowCartScreen extends StatelessWidget {
  const ShowCartScreen({super.key});

  String keyOf(SellerItem it) => '${it.sellerItemID}';

  @override
  Widget build(BuildContext context) {
    final _ = context.locale; // rebuild si langue change

    final cart   = context.watch<CartViewModel>();
    final items  = cart.items;
    final total  = cart.total;

    final config = context.watch<ConfigViewModel>().config;
    final primaryColor = parseHexColor(
      config?.ciPrimaryColor,
      fallback: const Color(0xFFEE6B33),
    );

    return Scaffold
    (

      backgroundColor: const Color(0xFFF6F6F8),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: primaryColor,
        centerTitle: true,
        title: Text('cart'.tr(),
            style: TextStyle(color: primaryColor, fontWeight: FontWeight.w700)),
        actions: [
          if (items.isNotEmpty)
            IconButton(
              icon: Icon(Icons.delete_sweep, color: Colors.red.shade600),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: Text('clear_cart'.tr()),
                    content: Text('confirm_clear_cart'.tr()),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context), child: Text('cancel'.tr())),
                      TextButton(
                        onPressed: () {
                          context.read<CartViewModel>().clear();
                          Navigator.pop(context);
                        },
                        child: Text('clear'.tr(), style: TextStyle(color: Colors.red.shade600)),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),

      body: items.isEmpty
          ? _buildEmptyCart(context, primaryColor)
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              children: [
                _HeaderCapsule(
                  primaryColor: primaryColor,
                  title: 'items_in_cart'.tr(),
                  subtitle:
                      '${items.length} ${'items'.tr()} • ${total.toStringAsFixed(0)} ${'currency_egp'.tr()}',
                ),
                const SizedBox(height: 16),

                _SectionCard(
                  primaryColor: primaryColor,
                  title: 'items'.tr(),
                  child: Column(
                    children: [
                      for (final it in items) ...[
                        _CartLine(
                          item: it,
                          primaryColor: primaryColor,
                          onInc: () => context.read<CartViewModel>().inc(keyOf(it)),
                          onDec: () => context.read<CartViewModel>().dec(keyOf(it)),
                          onRemove: () => context.read<CartViewModel>().remove(keyOf(it)),
                          onDismissed: () => context.read<CartViewModel>().remove(keyOf(it)),
                        ),
                        if (it != items.last) const Divider(height: 18),
                      ],
                    ],
                  ),
                ),
              ],
            ),

      bottomNavigationBar: items.isEmpty ? null : _buildBottomCheckout(context, primaryColor, total),

    );
  }

  Widget _buildEmptyCart(BuildContext context, Color primaryColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120, height: 120,
            decoration: BoxDecoration(color: primaryColor.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(Icons.shopping_cart_outlined, size: 60, color: primaryColor.withOpacity(0.6)),
          ),
          const SizedBox(height: 24),
          Text('your_cart_is_empty'.tr(),
              style: TextStyle(color: primaryColor, fontWeight: FontWeight.w600, fontSize: 20)),
          const SizedBox(height: 12),
          Text('start_shopping_now'.tr(), style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.shopping_bag_outlined, color: Colors.white),
            label: Text('continue_shopping'.tr(),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomCheckout(BuildContext context, Color primaryColor, double total) {
    final isRtl = Directionality.of(context) == ui.TextDirection.rtl;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, -5))],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: primaryColor.withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('total'.tr(),
                        style: TextStyle(fontSize: 20, color: primaryColor, fontWeight: FontWeight.bold)),
                    Text(
                      '${total.toStringAsFixed(0)} ${'currency_egp'.tr()}',
                      style: TextStyle(fontSize: 20, color: primaryColor, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const OrderSummaryScreen()));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.shopping_bag, color: Colors.white),
                      const SizedBox(width: 12),
                      Text('checkout'.tr(),
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(width: 8),
                      Icon(isRtl ? Icons.arrow_back_ios_new : Icons.arrow_forward_ios,
                          size: 18, color: Colors.white),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/* ==================== widgets style “Profil” ==================== */

class _HeaderCapsule extends StatelessWidget {
  const _HeaderCapsule({required this.primaryColor, required this.title, required this.subtitle});
  final Color primaryColor;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 86,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [primaryColor.withOpacity(.85), primaryColor.withOpacity(.65)],
        ),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(.07), blurRadius: 16, offset: const Offset(0, 8))],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
            child: Icon(Icons.shopping_cart, color: primaryColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(.22),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(.35)),
                  ),
                  child: Text(subtitle,
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.primaryColor, required this.title, required this.child});
  final Color primaryColor;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(.06), blurRadius: 12, offset: const Offset(0, 6))],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Container(width: 8, height: 8, decoration: BoxDecoration(color: primaryColor, shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF3B3B3B))),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 16), child: child),
        ],
      ),
    );
  }
}

class _CartLine extends StatelessWidget {
  const _CartLine({
    required this.item,
    required this.primaryColor,
    required this.onInc,
    required this.onDec,
    required this.onRemove,
    required this.onDismissed,
  });

  final SellerItem item;
  final Color primaryColor;
  final VoidCallback onInc;
  final VoidCallback onDec;
  final VoidCallback onRemove;
  final VoidCallback onDismissed;

  @override
  Widget build(BuildContext context) {
    final key = '${item.sellerItemID}';
    final url = (item.photoUrl?.trim().isNotEmpty == true)
        ? item.photoUrl!.trim()
        : (item.imageUrls.isNotEmpty ? item.imageUrls.first : '');
    final price = item.price;
    final qty   = item.qty;
    final itemTotal = price * qty;

    return Dismissible(
      key: Key('cart-$key'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: AlignmentDirectional.centerEnd,
        padding: const EdgeInsetsDirectional.only(end: 20),
        color: Colors.red.shade400,
        child: const Icon(Icons.delete, color: Colors.white, size: 28),
      ),
      onDismissed: (_) {
        onDismissed();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('item_removed'.tr()), backgroundColor: Colors.red.shade400),
        );
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // image
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 60, height: 60,
              child: url.isEmpty
                  ? Icon(Icons.image_not_supported, color: Colors.grey.shade400)
                  : Image.network(
                      url, key: ValueKey(url), fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(Icons.image_not_supported, color: Colors.grey.shade400),
                    ),
            ),
          ),
          const SizedBox(width: 12),

          // infos
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.nameEn.isNotEmpty ? item.nameEn : item.nameAr,
                    maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text('${price.toStringAsFixed(0)} ${'currency_egp'.tr()}',
                        style: TextStyle(color: primaryColor, fontWeight: FontWeight.w700)),
                    Text('  ×  $qty', style: TextStyle(color: Colors.grey.shade600)),
                  ],
                ),
                const SizedBox(height: 4),
                Text('${'total'.tr()}: ${itemTotal.toStringAsFixed(0)} ${'currency_egp'.tr()}',
                    style: TextStyle(color: primaryColor, fontWeight: FontWeight.w800)),
              ],
            ),
          ),

          // contrôles
          Column(
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _QuantityButton(
                    icon: Icons.remove,
                    color: qty > 1 ? primaryColor : Colors.grey.shade400,
                    onPressed: qty > 1 ? onDec : null,
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text('$qty',
                        style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 8),
                  _QuantityButton(icon: Icons.add, color: primaryColor, onPressed: onInc),
                ],
              ),
              const SizedBox(height: 10),
              Material(
                color: Colors.transparent,
                child: Ink(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withOpacity(0.25)),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))],
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: onRemove,
                    child: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuantityButton extends StatelessWidget {
  const _QuantityButton({required this.icon, required this.color, this.onPressed});
  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36, height: 36,
      decoration: BoxDecoration(
        color: onPressed != null ? color.withOpacity(0.1) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: onPressed != null ? color.withOpacity(0.3) : Colors.grey.shade300),
      ),
      child: IconButton(
        onPressed: onPressed, icon: Icon(icon, size: 18), color: color, padding: EdgeInsets.zero,
      ),
    );
  }
}
