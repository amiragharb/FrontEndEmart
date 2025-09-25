import 'package:flutter/material.dart';
import 'package:frontendemart/views/homeAdmin/custom_bottom_navbar.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:frontendemart/routes/routes.dart';
import 'package:frontendemart/models/address_model.dart';
import 'package:frontendemart/viewmodels/addresses_viewmodel.dart';
import 'package:frontendemart/viewmodels/Config_ViewModel.dart';

/// Parse couleur hex depuis la config
Color parseHexColor(String? hex, {Color fallback = const Color(0xFF0B1E6D)}) {
  if (hex == null) return fallback;
  var s = hex.trim();
  if (s.isEmpty) return fallback;
  s = s.replaceAll('#', '');
  if (s.toLowerCase().startsWith('0x')) s = s.substring(2);
  if (s.length == 6) s = 'FF$s';
  final val = int.tryParse(s, radix: 16);
  return val != null ? Color(val) : fallback;
}

// (Optionnel) Fallback de libellés si jamais tu reçois encore governorateId
const Map<int, String> _govIdToEN = {
  1:'Alexandria', 2:'Beni Suef', 3:'Cairo', 4:'Giza', 5:'Beheira', 6:'Ismailia',
  7:'Fayoum', 8:'Damietta', 9:'Monufia', 10:'Kafr El Sheikh', 11:'Dakahlia',
  12:'Qalyubia', 13:'Gharbia', 14:'Sharqia', 15:'Red Sea', 16:'Aswan', 17:'Qena',
  18:'Minya', 19:'North Sinai', 20:'Matrouh', 21:'Sohag', 22:'Suez', 23:'Luxor',
  24:'Port Said', 25:'South Sinai', 26:'Assiut', 27:'New Valley',
};
const Map<int, String> _govIdToAR = {
  1:'الإسكندرية', 2:'بني سويف', 3:'القاهرة', 4:'الجيزة', 5:'البحيرة', 6:'الإسماعيلية',
  7:'الفيوم', 8:'دمياط', 9:'المنوفية', 10:'كفر الشيخ', 11:'الدقهلية',
  12:'القليوبية', 13:'الغربية', 14:'الشرقية', 15:'البحر الأحمر', 16:'أسوان', 17:'قنا',
  18:'المنيا', 19:'شمال سيناء', 20:'مطروح', 21:'سوهاج', 22:'السويس', 23:'الأقصر',
  24:'بورسعيد', 25:'جنوب سيناء', 26:'أسيوط', 27:'الوادي الجديد',
};

String _stateLabel(Address a, bool isAr) {
  final s = a.governorateName?.trim();
  if (s != null && s.isNotEmpty) return s;
  final id = a.governorateId;
  if (id == null) return '';
  return isAr ? (_govIdToAR[id] ?? '') : (_govIdToEN[id] ?? '');
}

class ChooseAddressScreen extends StatefulWidget {
  const ChooseAddressScreen({super.key});

  @override
  State<ChooseAddressScreen> createState() => _ChooseAddressScreenState();
}

class _ChooseAddressScreenState extends State<ChooseAddressScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await context.read<AddressesViewModel>().getAll();
      } catch (e, st) {
        debugPrint('getAll error: $e\n$st');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), behavior: SnackBarBehavior.floating),
        );
      }
    });
  }

  Future<void> _refresh() async {
    await context.read<AddressesViewModel>().getAll();
  }

  @override
  Widget build(BuildContext context)
  {
    // rebuild si langue change
    final _ = context.locale;

    final vm = context.watch<AddressesViewModel>();
    final config = context.watch<ConfigViewModel>().config;
    final primary = parseHexColor(config?.ciPrimaryColor);
    final list = vm.list;
    final isAr = context.locale.languageCode.toLowerCase().startsWith('ar');

    return Scaffold
    (
      backgroundColor: const Color(0xFFF6F6F8),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: primary,
        centerTitle: true,
        title: Text('choose_address'.tr(),
            style: TextStyle(color: primary, fontWeight: FontWeight.w700)),
      ),
      body: vm.loading
          ? const Center(child: CircularProgressIndicator())
          : vm.error != null
              ? _ErrorState(primary: primary, message: vm.error!, onRetry: _refresh)
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  children: [
                    _HeaderCapsule(
                      primaryColor: primary,
                      title: 'choose_address'.tr(),
                      subtitle: isAr
                          ? 'اختر عنوان التوصيل أو أضف عنوانًا جديدًا'
                          : 'Pick a delivery address or add a new one',
                    ),
                    const SizedBox(height: 16),
                    _SectionCard(
                      primaryColor: primary,
                      title: 'your_addresses'.tr(),
                      child: list.isEmpty
                          ? _EmptyInsideCard(primary: primary)
                          : RefreshIndicator(
                              color: primary,
                              onRefresh: _refresh,
                              child: ListView.separated(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: EdgeInsets.zero,
                                shrinkWrap: true,
                                itemCount: list.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 12),
                                itemBuilder: (_, i) =>
                                    _AddressCard(address: list[i], primary: primary),
                              ),
                            ),
                    ),
                  ],
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await Navigator.pushNamed(context, AppRoutes.addAddress);
          if (created == true && mounted) {
            await _refresh();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('saved_successfully'.tr()), behavior: SnackBarBehavior.floating),
            );
          }
        },
        backgroundColor: primary,
        icon: const Icon(Icons.add_location_alt, color: Colors.white),
        label: Text('add_new_address'.tr(), style: const TextStyle(color: Colors.white)),
      ),
              bottomNavigationBar: const CustomBottomNavBar(currentIndex: 0),

    );
    
  }
}

/* ======================  Widgets style “Profil”  ====================== */

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
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(.07), blurRadius: 16, offset: const Offset(0, 8))],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
            child: Icon(Icons.location_on, color: primaryColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start,
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

/* ======================  États & cartes  ====================== */

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.primary, required this.message, required this.onRetry});
  final Color primary;
  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: _SectionCard(
        primaryColor: primary,
        title: 'something_went_wrong'.tr(),
        child: Column(
          children: [
            Icon(Icons.error_outline, size: 64, color: primary.withOpacity(.6)),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade700)),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text('try_again'.tr()),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyInsideCard extends StatelessWidget {
  const _EmptyInsideCard({required this.primary});
  final Color primary;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(Icons.location_off_outlined, size: 64, color: primary.withOpacity(.6)),
        const SizedBox(height: 12),
        Text('no_addresses_yet'.tr(), style: TextStyle(color: primary, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text('tap_plus_to_add_address'.tr(), style: TextStyle(color: Colors.grey.shade600)),
      ],
    );
  }
}

class _AddressCard extends StatelessWidget {
  const _AddressCard({required this.address, required this.primary});
  final Address address;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    final isAr = context.locale.languageCode.toLowerCase().startsWith('ar');

    // Sous-titre compact : Address · State · Country
    final parts = <String>[
      if ((address.address ?? '').trim().isNotEmpty) address.address!.trim(),
      if (_stateLabel(address, isAr).isNotEmpty) _stateLabel(address, isAr),
      if ((address.countryName ?? '').trim().isNotEmpty) address.countryName!.trim(),
    ];
    final subtitle = parts.join(' · ');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(.06), blurRadius: 12, offset: const Offset(0, 6))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: primary, borderRadius: BorderRadius.circular(12)),
            child: Icon(address.isHome ? Icons.home : Icons.location_on, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: InkWell(
              onTap: () => _showAddressSheet(context, address, primary),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(address.title ?? 'address'.tr(), style: const TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (v) async {
              if (v == 'edit') {
                final ok = await Navigator.pushNamed(
                  context,
                  AppRoutes.editAddress,
                  arguments: address,
                );
                if (ok == true && context.mounted) {
                  await context.read<AddressesViewModel>().getAll();
                }
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(value: 'edit', child: Text('edit'.tr())),
            ],
          ),
        ],
      ),
    );
  }
}

/* ------------------- Dialog: preview + actions ------------------- */


                 Future<void> _showAddressSheet(BuildContext context, Address a, Color primary) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      final mq = MediaQuery.of(ctx);
      final padBottom = mq.viewInsets.bottom;
      final isAr = context.locale.languageCode.toLowerCase().startsWith('ar');

      final countryLabel = (a.countryName?.trim().isNotEmpty ?? false)
          ? a.countryName!.trim()
          : 'Egypt';
      final stateLabel = _stateLabel(a, isAr);

      return SafeArea(
        child: Container(
          constraints: BoxConstraints(maxHeight: mq.size.height * .85),
          padding: EdgeInsets.fromLTRB(16, 8, 16, 12 + padBottom),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(.15), blurRadius: 24, offset: const Offset(0, -8))],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 44, height: 4, decoration: BoxDecoration(
                color: Colors.black12, borderRadius: BorderRadius.circular(4),
              )),
              const SizedBox(height: 12),

              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      (a.title?.isNotEmpty ?? false) ? a.title! : 'address'.tr(),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: primary.withOpacity(.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: primary.withOpacity(.25)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(a.isHome ? Icons.home_rounded : Icons.location_on_rounded, size: 16, color: primary),
                        const SizedBox(width: 6),
                        Text(a.isHome ? 'home'.tr() : (a.isWork ? 'work'.tr() : 'address'.tr()),
                            style: TextStyle(color: primary, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),
              Divider(color: Colors.black.withOpacity(.06), height: 1),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(top: 12, bottom: 6),
                  child: Column(
                    children: [
                      if (a.lat != null || a.lng != null)
                        _InfoRow(
                          icon: Icons.gps_fixed, primary: primary, label: 'location'.tr(),
                          value: '${'lat'.tr()}: ${a.lat?.toStringAsFixed(6) ?? '—'}  ·  ${'lng'.tr()}: ${a.lng?.toStringAsFixed(6) ?? '—'}',
                          bold: true,
                        ),
                      _InfoRow(icon: Icons.description_outlined, primary: primary, label: 'address_details'.tr(), value: a.address),
                      _InfoRow(icon: Icons.apartment_outlined, primary: primary, label: 'building_number'.tr(), value: a.buildingNameOrNumber),
                      _InfoRow(icon: Icons.place_outlined, primary: primary, label: 'special_signs'.tr(), value: a.nearestLandmark),
                      _InfoRow(icon: Icons.flag_outlined, primary: primary, label: 'country'.tr(), value: countryLabel),
                      _InfoRow(icon: Icons.map_outlined, primary: primary, label: 'state'.tr(), value: stateLabel),
                    ],
                  ),
                ),
              ),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.edit_outlined),
                      label: Text('update'.tr()),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        foregroundColor: primary,
                        side: BorderSide(color: primary.withOpacity(.3)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () async {
                        Navigator.pop(ctx);
                        final ok = await Navigator.pushNamed(context, AppRoutes.editAddress, arguments: a);
                        if (!context.mounted) return;
                        if (ok == true) {
                          await context.read<AddressesViewModel>().getAll();
                          ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                            SnackBar(content: Text('saved_successfully'.tr()), behavior: SnackBarBehavior.floating),
                          );
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.check_rounded, color: Colors.white),
                      label: Text('use_this_address'.tr()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      onPressed: () {
                        // ferme le sheet, puis navigue vers le choix du paiement
                        Navigator.pop(ctx);
                        if (!context.mounted) return;
                        Navigator.pushNamed(context, AppRoutes.choosePayment, arguments: a);
                      },
                    ),
                  ),
                ],
              ),
              TextButton(onPressed: () => Navigator.pop(ctx), child: Text('cancel'.tr())),
            ],
          ),
        ),
      );
    },
  );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.primary,
    required this.label,
    required this.value,
    this.bold = false,
  });

  final IconData icon;
  final Color primary;
  final String label;
  final String? value;
  final bool bold;

  String _fmt(String? v) => (v == null || v.trim().isEmpty) ? '—' : v.trim();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: primary.withOpacity(.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: primary.withOpacity(.25)),
            ),
            child: Icon(icon, color: primary, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                const SizedBox(height: 3),
                Text(
                  _fmt(value),
                  style: TextStyle(fontWeight: bold ? FontWeight.w800 : FontWeight.w600, fontSize: 14.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
