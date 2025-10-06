// lib/views/payment/choose_payment_method_screen.dart
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';

import 'package:frontendemart/models/address_model.dart';
import 'package:frontendemart/viewmodels/Config_ViewModel.dart';
import 'package:frontendemart/viewmodels/card_input.dart'; // ⬅️ pour typer le retour
import 'package:frontendemart/routes/routes.dart';
import 'package:frontendemart/views/homeAdmin/custom_bottom_navbar.dart';

Color _parseHexColor(String? hex, {Color fallback = const Color(0xFF0B1E6D)}) {
  if (hex == null) return fallback;
  var s = hex.trim().replaceAll('#', '');
  if (s.toLowerCase().startsWith('0x')) s = s.substring(2);
  if (s.length == 6) s = 'FF$s';
  final v = int.tryParse(s, radix: 16);
  return v != null ? Color(v) : fallback;
}

enum PaymentMethod { cod, card }

class ChoosePaymentMethodScreen extends StatefulWidget {
  const ChoosePaymentMethodScreen({super.key, required this.address});
  final Address address;

  @override
  State<ChoosePaymentMethodScreen> createState() => _ChoosePaymentMethodScreenState();
}

class _ChoosePaymentMethodScreenState extends State<ChoosePaymentMethodScreen> {
  PaymentMethod? _method = PaymentMethod.cod; // par défaut: COD
  bool _navigating = false; // évite double navigation

  @override
  Widget build(BuildContext context) {
    // rebuild si la langue change
    final _ = context.locale;

    final config = context.watch<ConfigViewModel>().config;
    final primary = _parseHexColor(config?.ciPrimaryColor);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F8),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: primary,
        centerTitle: true,
        title: Text(
          'choose_payment_method'.tr(),
          style: TextStyle(color: primary, fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        children: [
          _HeaderCapsule(
            primaryColor: primary,
            title: 'payment_method'.tr(),
            subtitle: 'select_a_payment_option'.tr(),
          ),
          const SizedBox(height: 16),

          // Adresse de livraison
          _SectionCard(
            primaryColor: primary,
            title: 'delivery_address'.tr(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.address.title ?? 'address'.tr(),
                    style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(
                  [
                    if ((widget.address.address ?? '').trim().isNotEmpty)
                      widget.address.address!.trim(),
                    if ((widget.address.governorateName ?? '').trim().isNotEmpty)
                      widget.address.governorateName!.trim(),
                    if ((widget.address.countryName ?? '').trim().isNotEmpty)
                      widget.address.countryName!.trim(),
                  ].join(' · '),
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Choix du mode de paiement
          _SectionCard(
            primaryColor: primary,
            title: 'choose_payment_method'.tr(),
            child: Column(
              children: [
                RadioListTile<PaymentMethod>(
                  value: PaymentMethod.cod,
                  groupValue: _method,
                  onChanged: (v) => setState(() => _method = v),
                  activeColor: primary,
                  title: Text('cash_on_delivery'.tr(),
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  secondary: Icon(Icons.payments_outlined, color: primary),
                ),
                const Divider(height: 1),
                RadioListTile<PaymentMethod>(
                  value: PaymentMethod.card,
                  groupValue: _method,
                  onChanged: (v) => setState(() => _method = v),
                  activeColor: primary,
                  title: Text('add_bank_card'.tr(),
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  secondary: Icon(Icons.credit_card, color: primary),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // CTA
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (_method == null || _navigating)
                  ? null
                  : () async {
                      setState(() => _navigating = true);
                      try {
                        if (_method == PaymentMethod.card) {
                          // 1) Aller à l’écran d’ajout de carte et attendre le résultat
                          final result = await Navigator.pushNamed(context, AppRoutes.addCard);

                          // 2) Si l’utilisateur a bien ajouté une carte, on enchaîne vers le résumé
                          if (!mounted) return;
                          if (result is CardInput) {
                            Navigator.pushNamed(
                              context,
                              AppRoutes.orderSummary,
                              arguments: {
                                'address': widget.address,
                                'method': PaymentMethod.card,
                                'card': result, // on passe la carte au résumé
                              },
                            );
                          } else {
                            // L’utilisateur est revenu sans valider
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('no_card_added'.tr())),
                            );
                          }
                        } else {
                          // ➜ COD : directement vers le résumé
                          if (!mounted) return;
                          Navigator.pushNamed(
                            context,
                            AppRoutes.orderSummary,
                            arguments: {
                              'address': widget.address,
                              'method': PaymentMethod.cod,
                            },
                          );
                        }
                      } finally {
                        if (mounted) setState(() => _navigating = false);
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: Text('proceed'.tr()),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 0),
    );
  }
}

/* ===== UI widgets (mêmes styles que les autres écrans) ===== */

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
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primaryColor.withOpacity(.85), primaryColor.withOpacity(.65)],
        ),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(.07), blurRadius: 16, offset: const Offset(0, 8))],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
            child: Icon(Icons.credit_card, color: primaryColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
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
                  child: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis,
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
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
