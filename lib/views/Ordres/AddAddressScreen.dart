import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:frontendemart/models/address_model.dart';
import 'package:frontendemart/viewmodels/addresses_viewmodel.dart';
import 'package:frontendemart/viewmodels/Config_ViewModel.dart';

class AddEditAddressScreen extends StatefulWidget {
  const AddEditAddressScreen({super.key, this.existing});
  final Address? existing;

  @override
  State<AddEditAddressScreen> createState() => _AddEditAddressScreenState();
}

class _AddEditAddressScreenState extends State<AddEditAddressScreen> {
  final _form = GlobalKey<FormState>();

  // Champs demandés + (title optionnel)
  late final TextEditingController _title;        // optionnel
  late final TextEditingController _address;      // Address details
  late final TextEditingController _building;     // Building number
  late final TextEditingController _specialSigns; // Special signs
  late final TextEditingController _lat;
  late final TextEditingController _lng;

  bool get _isAr => context.locale.languageCode.toLowerCase().startsWith('ar');

  // Country (string)
  static const String _countryValueEN = 'Egypt';
  String get _countryLabelUI => _isAr ? 'مصر' : 'Egypt';

  // State/Governorates (on stocke et on envoie l’EN en backend)
  static const List<String> _statesEN = <String>[
    'Cairo','Giza','Alexandria','Dakahlia','Sharqia','Gharbia','Qalyubia','Monufia','Beheira',
    'Kafr El Sheikh','Damietta','Port Said','Ismailia','Suez','Matrouh','North Sinai','South Sinai',
    'Fayoum','Beni Suef','Minya','Assiut','Sohag','Qena','Luxor','Aswan','Red Sea','New Valley',
  ];
  static const List<String> _statesAR = <String>[
    'القاهرة','الجيزة','الإسكندرية','الدقهلية','الشرقية','الغربية','القليوبية','المنوفية','البحيرة',
    'كفر الشيخ','دمياط','بورسعيد','الإسماعيلية','السويس','مطروح','شمال سيناء','جنوب سيناء',
    'الفيوم','بني سويف','المنيا','أسيوط','سوهاج','قنا','الأقصر','أسوان','البحر الأحمر','الوادي الجديد',
  ];

  String? _stateEN;          // valeur envoyée (EN)
  bool _isHome = false;      // tu peux garder si utile
  bool _isWork = false;      // idem
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final a = widget.existing;

    _title        = TextEditingController(text: a?.title ?? '');
    _address      = TextEditingController(text: a?.address ?? '');
    _building     = TextEditingController(text: a?.buildingNameOrNumber ?? '');
    _specialSigns = TextEditingController(text: a?.nearestLandmark ?? '');
    _lat          = TextEditingController(text: a?.lat?.toString() ?? '');
    _lng          = TextEditingController(text: a?.lng?.toString() ?? '');

    _isHome = a?.isHome ?? false;
    _isWork = a?.isWork ?? false;

    // Pré-sélection du state depuis governorateName (string) si présent
    final govName = a?.governorateName?.trim();
    if ((govName ?? '').isNotEmpty) {
      final idx = _statesEN.indexWhere(
        (en) => en.toLowerCase() == govName!.toLowerCase(),
      );
      if (idx >= 0) _stateEN = _statesEN[idx];
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _address.dispose();
    _building.dispose();
    _specialSigns.dispose();
    _lat.dispose();
    _lng.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // rebuild si langue change
    final _ = context.locale;

    final config = context.watch<ConfigViewModel>().config;
    final hex = config?.ciPrimaryColor;
    final primary = (hex != null && hex.isNotEmpty)
        ? Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16))
        : const Color(0xFF0B1E6D);

    final isEdit = widget.existing != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F8),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: primary,
        centerTitle: true,
        title: Text(
          isEdit ? 'edit_address'.tr() : 'add_new_address'.tr(),
          style: TextStyle(color: primary, fontWeight: FontWeight.w700),
        ),
      ),
      body: Form(
        key: _form,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          children: [
            _Header(primary: primary, title: isEdit ? 'edit_address'.tr() : 'add_new_address'.tr()),
            const SizedBox(height: 16),

            _Section(primary: primary, title: _isAr ? 'العنوان' : 'Address', child: Column(
              children: [
                // Country (string) + State (string)
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _countryValueEN, // fixe pour l’instant
                        items: [
                          DropdownMenuItem(value: _countryValueEN, child: Text(_countryLabelUI)),
                        ],
                        onChanged: (_) {},
                        decoration: _dec(primary, label: 'country'.tr()),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: (_stateEN != null && _statesEN.contains(_stateEN!)) ? _stateEN : null,
                        items: List.generate(_statesEN.length, (i) {
                          final valueEN = _statesEN[i];
                          final label   = _isAr ? _statesAR[i] : _statesEN[i];
                          return DropdownMenuItem(value: valueEN, child: Text(label));
                        }),
                        onChanged: (v) => setState(() => _stateEN = v),
                        validator: (v) => (v == null || v.isEmpty) ? 'required_field'.tr() : null,
                        decoration: _dec(primary, label: 'state'.tr()),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Address details
                _T(label: 'address_details'.tr(), controller: _address, primary: primary,
                   maxLines: 2, validator: (v) => (v ?? '').trim().isEmpty ? 'required_field'.tr() : null),

                // Building number
                _T(label: 'building_number'.tr(), controller: _building, primary: primary),

                // Special signs
                _T(label: 'special_signs'.tr(), controller: _specialSigns, primary: primary),

                // Location (lat/lng)
                Row(
                  children: [
                    Expanded(
                      child: _T(
                        label: 'lat'.tr(),
                        controller: _lat,
                        primary: primary,
                        keyboard: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _T(
                        label: 'lng'.tr(),
                        controller: _lng,
                        primary: primary,
                        keyboard: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // (Optionnel) Type d’adresse
                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 8,
                    children: [
                      FilterChip(
                        label: Text('home'.tr()),
                        selected: _isHome,
                        onSelected: (s) => setState(() { _isHome = s; if (s) _isWork = false; }),
                        selectedColor: primary.withOpacity(.15),
                        checkmarkColor: primary,
                        side: BorderSide(color: primary.withOpacity(.35)),
                      ),
                      FilterChip(
                        label: Text('work'.tr()),
                        selected: _isWork,
                        onSelected: (s) => setState(() { _isWork = s; if (s) _isHome = false; }),
                        selectedColor: primary.withOpacity(.15),
                        checkmarkColor: primary,
                        side: BorderSide(color: primary.withOpacity(.35)),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // (Optionnel) Title (label du point)
                _T(label: 'title'.tr(), controller: _title, primary: primary),
              ],
            )),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context, false),
                    icon: const Icon(Icons.arrow_back),
                    label: Text('back'.tr()),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: primary.withOpacity(.25)),
                      foregroundColor: primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.save),
                    label: Text(_saving ? '...' : 'save'.tr()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                      disabledBackgroundColor: primary.withOpacity(.5),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _dec(Color primary, {required String label}) => InputDecoration(
    labelText: label,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    focusedBorder: OutlineInputBorder(
      borderSide: BorderSide(color: primary),
      borderRadius: BorderRadius.circular(12),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
  );

  double? _parseDouble(String s) {
    final v = s.trim();
    if (v.isEmpty) return null;
    return double.tryParse(v.replaceAll(',', '.'));
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();

    final formState = _form.currentState;
    if (formState == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('please_fill_required_fields'.tr())));
      return;
    }
    final isValid = formState.validate();
    if (!isValid || _stateEN == null || _stateEN!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('please_fill_required_fields'.tr())));
      return;
    }

    setState(() => _saving = true);

    final vm = context.read<AddressesViewModel>();
    final dto = Address(
      userLocationId: widget.existing?.userLocationId ?? 0,
      title: _title.text.trim().isEmpty ? null : _title.text.trim(),
      address: _address.text.trim(),
      buildingNameOrNumber: _building.text.trim().isEmpty ? null : _building.text.trim(),
      nearestLandmark: _specialSigns.text.trim().isEmpty ? null : _specialSigns.text.trim(),
      lat: _parseDouble(_lat.text),
      lng: _parseDouble(_lng.text),

      // ✅ on envoie les STRINGS, pas les IDs
      countryId: null,
      countryName: _countryValueEN,
      governorateId: null,
      governorateName: _stateEN,

      // plus de district/city
      districtId: null,
      districtName: null,

      isHome: _isHome,
      isWork: _isWork,
    );

    try {
      if (widget.existing == null) {
        await vm.add(dto);
      } else {
        await vm.update(dto);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('saved_successfully'.tr()), behavior: SnackBarBehavior.floating),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), behavior: SnackBarBehavior.floating),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

/* ===== UI mini-composants ===== */

class _Header extends StatelessWidget {
  const _Header({required this.primary, required this.title});
  final Color primary;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 86,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [primary.withOpacity(.85), primary.withOpacity(.65)],
        ),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(.07), blurRadius: 16, offset: const Offset(0, 8))],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Container(width: 48, height: 48, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
              child: Icon(Icons.location_on, color: primary)),
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
                  child: Text(_isAr(context) ? 'أدخل تفاصيل عنوان التسليم' : 'Enter delivery address details',
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

  bool _isAr(BuildContext c) => c.locale.languageCode.toLowerCase().startsWith('ar');
}

class _Section extends StatelessWidget {
  const _Section({required this.primary, required this.title, required this.child});
  final Color primary;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) 
  {
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
                Container(width: 8, height: 8, decoration: BoxDecoration(color: primary, shape: BoxShape.circle)),
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

class _T extends StatelessWidget {
  const _T({
    required this.label,
    required this.controller,
    required this.primary,
    this.maxLines = 1,
    this.keyboard,
    this.validator,
  });

  final String label;
  final TextEditingController controller;
  final Color primary;
  final int maxLines;
  final TextInputType? keyboard;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboard,
        validator: validator,
        textInputAction: TextInputAction.next,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: primary),
            borderRadius: BorderRadius.circular(12),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        ),
      ),
    );
  }
}
