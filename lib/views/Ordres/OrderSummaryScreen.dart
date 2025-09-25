import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:frontendemart/views/Ordres/ChooseAddressScreen.dart';
import 'package:provider/provider.dart';

import 'package:frontendemart/viewmodels/CartViewModel.dart';
import 'package:frontendemart/viewmodels/Config_ViewModel.dart';
import 'package:frontendemart/models/SellerItem_model.dart';
import 'package:frontendemart/views/Ordres/ShowCartScreen.dart';
import 'package:frontendemart/views/homeAdmin/custom_bottom_navbar.dart';
import 'package:frontendemart/models/address_model.dart';

/* ---------- Helper couleur primaire robuste ---------- */
Color parseHexColor(String? hex, {Color fallback = const Color(0xFFEE6B33)}) {
  if (hex == null) return fallback;
  var s = hex.trim();
  if (s.isEmpty) return fallback;

  // Nettoyage formats: "#RRGGBB", "0xFFRRGGBB", "RRGGBB", "FFRRGGBB"
  if (s.toLowerCase().startsWith('0x')) s = s.substring(2);
  if (s.length == 6) s = 'FF$s'; // ajoute alpha si manquant

  final val = int.tryParse(s, radix: 16);
  return val != null ? Color(val) : fallback;
}

// ✅ IMPORTANT: importer le bon écran ChooseAddress
//   (corrige l'ancien import "views/Items/ChooseAddressScreen.dart")

class OrderSummaryScreen extends StatelessWidget {
  const OrderSummaryScreen({super.key});

  String _money(BuildContext context, double amount) =>
      '${amount.toStringAsFixed(0)} ${'currency_egp'.tr()}';

  @override
  Widget build(BuildContext context) {
    // force rebuild si la langue change
    final _ = context.locale;

    final cart   = context.watch<CartViewModel>();
    final items  = cart.items;
    final config = context.watch<ConfigViewModel>().config;

    // ⬇️ Utilisation du helper robuste
    final primaryColor = parseHexColor(config?.ciPrimaryColor);

    final int units        = items.fold<int>(0, (s, it) => s + it.qty);
    final double subTotal  = cart.total;
    const double delivery  = 0;
    const double taxes     = 0;
    final double grandTotal = subTotal + delivery + taxes;

    // 🔍 Logs de build + récap
    debugPrint('[OrderSummary] build: items=${items.length}, units=$units, '
        'sub=$subTotal, delivery=$delivery, taxes=$taxes, total=$grandTotal');

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F8),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: primaryColor,
        centerTitle: true,
        title: Text(
          'order_summary'.tr(),
          style: TextStyle(color: primaryColor, fontWeight: FontWeight.w700),
        ),
      ),

      body: items.isEmpty
          ? _buildEmpty(context, primaryColor)
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              children: [
                // --- En-tête façon “Profil” ---
                _HeaderCapsule(
                  primaryColor: primaryColor,
                  title: 'review_your_order'.tr(),
                  subtitle:
                      '${'items'.tr()} ${items.length} • ${'total'.tr()} ${_money(context, grandTotal)}',
                ),

                const SizedBox(height: 16),

                // --- Section PRODUITS ---
                _SectionCard(
                  primaryColor: primaryColor,
                  title: 'items'.tr(),
                  child: Column(
                    children: [
                      for (final it in items) ...[
                        _OrderLine(item: it, primaryColor: primaryColor),
                        if (it != items.last) const Divider(height: 18),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // --- Section RÉCAP ---
                _SectionCard(
                  primaryColor: primaryColor,
                  title: 'summary'.tr(),
                  child: Column(
                    children: [
                      _KVRow(label: 'subtotal'.tr(), value: _money(context, subTotal)),
                      const SizedBox(height: 10),
                      _KVRow(label: 'delivery'.tr(), value: _money(context, delivery)),
                      if (taxes != 0) ...[
                        const SizedBox(height: 10),
                        _KVRow(label: 'taxes'.tr(), value: _money(context, taxes)),
                      ],
                      const Divider(height: 24),
                      _KVRow(
                        label: 'total'.tr(),
                        value: _money(context, grandTotal),
                        bold: true,
                        color: primaryColor,
                        size: 18,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // --- Actions ---
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          debugPrint('[OrderSummary] tap edit cart → ShowCartScreen');
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(builder: (_) => const ShowCartScreen()),
                          );
                        },
                        icon: const Icon(Icons.edit_outlined),
                        label: Text('edit_cart'.tr()),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: primaryColor.withOpacity(0.25)),
                          foregroundColor: primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _goChooseAddress(context, primaryColor),
                        icon: const Icon(Icons.lock_outline),
                        label: Text('confirm_order'.tr()),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 2),
    );
  }

  Widget _buildEmpty(BuildContext context, Color primaryColor) {
    debugPrint('[OrderSummary] empty cart UI');
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
  mainAxisSize: MainAxisSize.min,
  children: [
    Icon(Icons.receipt_long_outlined,
        size: 64, color: primaryColor.withOpacity(0.6)),
    const SizedBox(height: 12),
    Text('your_cart_is_empty'.tr(),
        style: TextStyle(color: primaryColor, fontWeight: FontWeight.w700)),
    const SizedBox(height: 8),
    Text('start_shopping_now'.tr(),
        style: TextStyle(color: Colors.grey.shade600)),
    const SizedBox(height: 24),
    ElevatedButton(
      onPressed: () {
        debugPrint('[OrderSummary] empty → go home');
        // Naviguer vers l'écran Home en effaçant le stack
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/home',
          (Route<dynamic> route) => false,
        );
      },
      style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
      child: Text('back'.tr(), style: const TextStyle(color: Colors.white)),
    ),
  ],
)
,
      ),
    );
  }

  void _confirm(BuildContext context, Color primaryColor) {
    debugPrint('[OrderSummary] confirm dialog opened');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: primaryColor),
            const SizedBox(width: 8),
            Text('order_confirmation'.tr()),
          ],
        ),
        content: Text('order_will_be_processed'.tr()),
        actions: [
          TextButton(
            onPressed: () {
              debugPrint('[OrderSummary] confirm → cancel');
              Navigator.pop(ctx);
            },
            child: Text('cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () {
              debugPrint('[OrderSummary] confirm → confirmed, clearing cart');
              Navigator.pop(ctx);
              context.read<CartViewModel>().clear();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('order_placed_successfully'.tr()), backgroundColor: Colors.green),
              );
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
            child: Text('confirm_order'.tr(), style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

/* ======================  Widgets “style Profil”  ====================== */

class _HeaderCapsule extends StatelessWidget {
  const _HeaderCapsule({
    required this.primaryColor,
    required this.title,
    required this.subtitle,
  });

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
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primaryColor.withOpacity(.85), primaryColor.withOpacity(.65)],
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(.07), blurRadius: 16, offset: const Offset(0, 8)),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // pastille
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.shopping_bag, color: primaryColor),
          ),
          const SizedBox(width: 12),
          // textes
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(.22),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(.35)),
                  ),
                  child: Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                  ),
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
  const _SectionCard({
    required this.primaryColor,
    required this.title,
    required this.child,
  });

  final Color primaryColor;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(.06), blurRadius: 12, offset: const Offset(0, 6))],
      ),
      child: Column(
        children: [
          // entête style “Profil” avec puce bleue
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _OrderLine extends StatelessWidget {
  const _OrderLine({required this.item, required this.primaryColor});
  final SellerItem item;
  final Color primaryColor;

  @override
  Widget build(BuildContext context) {
    final url = (item.photoUrl?.trim().isNotEmpty == true)
        ? item.photoUrl!.trim()
        : (item.imageUrls.isNotEmpty ? item.imageUrls.first : '');
    final lineTotal = item.price * item.qty;

    // log par ligne (utile si images 404/encodage)
    debugPrint('[OrderSummary] line: id=${item.sellerItemID}, qty=${item.qty}, '
        'price=${item.price}, url="${url.isEmpty ? '(none)' : url}"');

    return Row(
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
                    url,
                    key: ValueKey(url),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) {
                      debugPrint('[OrderSummary] image load error: $url');
                      return Icon(Icons.image_not_supported, color: Colors.grey.shade400);
                    },
                  ),
          ),
        ),
        const SizedBox(width: 12),
        // infos
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.nameEn.isNotEmpty ? item.nameEn : item.nameAr,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                '${item.qty} × ${item.price.toStringAsFixed(0)} ${'currency_egp'.tr()}',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        // montant
        Text(
          '${lineTotal.toStringAsFixed(0)} ${'currency_egp'.tr()}',
          style: TextStyle(color: primaryColor, fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}

// ----------- Navigation vers ChooseAddress + logs -----------
Future<void> _goChooseAddress(BuildContext context, Color primaryColor) async {
  debugPrint('[OrderSummary] tap confirm → push ChooseAddressScreen');
  final Address? selected = await Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const ChooseAddressScreen()),
  );

  debugPrint('[OrderSummary] returned from ChooseAddress, '
      'selected=${selected == null ? 'null' : 'id=${selected.userLocationId} title=${selected.title}'}');

  // L’utilisateur est revenu sans choisir → on ne fait rien
  if (selected == null) return;

  // Dialog de confirmation
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.check_circle, color: primaryColor),
          const SizedBox(width: 8),
          Text('order_confirmation'.tr()),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('delivery_address'.tr()),
          const SizedBox(height: 6),
          Text(
            [
              if ((selected.title ?? '').isNotEmpty) selected.title,
              if ((selected.address ?? '').isNotEmpty) selected.address,
              if ((selected.districtName ?? '').isNotEmpty) selected.districtName,
              if ((selected.governorateName ?? '').isNotEmpty) selected.governorateName,
            ].whereType<String>().join(' · '),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            debugPrint('[OrderSummary] confirm dialog → cancel');
            Navigator.pop(ctx);
          },
          child: Text('cancel'.tr()),
        ),
        ElevatedButton(
          onPressed: () {
            debugPrint('[OrderSummary] confirm dialog → confirmed with address '
                'id=${selected.userLocationId}');
            Navigator.pop(ctx);

            // 👉 ici: appel backend “create order” avec selected.userLocationId si besoin
            context.read<CartViewModel>().clear();

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('order_placed_successfully'.tr()), backgroundColor: Colors.green),
            );
            Navigator.pop(context); // retour après confirmation
          },
          style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
          child: Text('confirm_order'.tr(), style: const TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );
}

// ----------- KV Row utilitaire -----------
class _KVRow extends StatelessWidget {
  const _KVRow({
    required this.label,
    required this.value,
    this.bold = false,
    this.color,
    this.size,
  });

  final String label;
  final String value;
  final bool bold;
  final Color? color;
  final double? size;

  @override
  Widget build(BuildContext context) {
    final tColor = color ?? Colors.black87;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey.shade700)),
        Text(
          value,
          style: TextStyle(
            fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
            color: tColor,
            fontSize: size,
          ),
        ),
      ],
    );
  }
}
