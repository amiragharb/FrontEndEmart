// views/checkout/add_card_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import 'package:frontendemart/viewmodels/card_input.dart';
import 'package:frontendemart/viewmodels/Config_ViewModel.dart';
import 'package:frontendemart/views/homeAdmin/custom_bottom_navbar.dart';

Color _parseHexColor(String? hex, {Color fallback = const Color(0xFF0B1E6D)}) {
  if (hex == null) return fallback;
  var s = hex.trim().replaceAll('#', '');
  if (s.toLowerCase().startsWith('0x')) s = s.substring(2);
  if (s.length == 6) s = 'FF$s';
  final v = int.tryParse(s, radix: 16);
  return v != null ? Color(v) : fallback;
}

class AddCardScreen extends StatefulWidget {
  const AddCardScreen({super.key});

  @override
  State<AddCardScreen> createState() => _AddCardScreenState();
}

class _AddCardScreenState extends State<AddCardScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _number = TextEditingController();
  final _cvv = TextEditingController();

  int _mm = DateTime.now().month;
  int _yyyy = DateTime.now().year;

  bool _default = true;
  bool _submitting = false;

  @override
  void dispose() {
    _name.dispose();
    _number.dispose();
    _cvv.dispose();
    super.dispose();
  }

  // ---- Helpers ----
  bool _luhnValid(String input) {
    final digits = input.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 12) return false;
    var sum = 0, even = false;
    for (var i = digits.length - 1; i >= 0; i--) {
      var d = int.parse(digits[i]);
      if (even) {
        d *= 2;
        if (d > 9) d -= 9;
      }
      sum += d;
      even = !even;
    }
    return sum % 10 == 0;
  }

  String _brand(String digits) {
    final d = digits.replaceAll(RegExp(r'\D'), '');
    if (d.isEmpty) return '';
    if (d.startsWith('4')) return 'VISA';
    if (RegExp(r'^(5[1-5])').hasMatch(d)) return 'Mastercard';
    if (RegExp(r'^(3[47])').hasMatch(d)) return 'AMEX';
    if (RegExp(r'^(6(?:011|5))').hasMatch(d)) return 'Discover';
    return 'CARD';
  }

  String _masked(String digits) {
    final d = digits.replaceAll(RegExp(r'\D'), '');
    if (d.length <= 4) return d;
    final tail = d.substring(d.length - 4);
    return '•••• •••• •••• $tail';
  }

  Future<void> _submit() async {
    final ok = _form.currentState?.validate() ?? false;
    if (!ok) return;

    setState(() => _submitting = true);
    try {
      final card = CardInput(
        holderName: _name.text.trim(),
        number: _number.text.replaceAll(RegExp(r'\s+'), ''),
        expMonth: _mm,
        expYear: _yyyy,
        cvv: _cvv.text,
      );
      if (!mounted) return;
      Navigator.of(context).pop(card);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // rebuild si la langue change
    final _ = context.locale;

    final config = context.watch<ConfigViewModel>().config;
    final primary = _parseHexColor(config?.ciPrimaryColor);

    final months = List<int>.generate(12, (i) => i + 1);
    final years = List<int>.generate(15, (i) => DateTime.now().year + i);

    final digits = _number.text;
    final brand = _brand(digits);
    final masked = _masked(digits);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F8),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: primary,
        centerTitle: true,
        title: Text(
          'add_payment_method'.tr(),
          style: TextStyle(color: primary, fontWeight: FontWeight.w700),
        ),
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          children: [
            // Header Capsule
            _HeaderCapsule(
              primaryColor: primary,
              title: 'add_payment_method'.tr(),
              subtitle: 'enter_your_card_details'.tr(),
            ),
            const SizedBox(height: 16),

            // --------- Preview card ----------
            _SectionCard(
              primaryColor: primary,
              title: 'card_preview'.tr(),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primary, primary.withOpacity(0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: primary.withOpacity(0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    )
                  ],
                ),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Stack(
                    children: [
                      Align(
                        alignment: Alignment.topRight,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white.withOpacity(0.3)),
                          ),
                          child: Text(
                            brand.isEmpty ? 'CARD' : brand,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          masked.isEmpty ? '•••• •••• •••• ••••' : masked,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            letterSpacing: 2,
                            fontWeight: FontWeight.w600,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.bottomLeft,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                _name.text.isEmpty ? 'name_on_card'.tr() : _name.text.toUpperCase(),
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.95),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '${_mm.toString().padLeft(2, '0')}/${_yyyy % 100}',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.95),
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // --------- Switch default ----------
            

            const SizedBox(height: 16),

            // --------- Form Card ----------
            _SectionCard(
              primaryColor: primary,
              title: 'card_details'.tr(),
              child: Column(
                children: [
                  TextFormField(
                    controller: _name,
                    decoration: InputDecoration(
                      labelText: 'name_on_card'.tr(),
                      prefixIcon: Icon(Icons.person_outline, color: primary),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: primary, width: 2),
                      ),
                    ),
                    textInputAction: TextInputAction.next,
                    onChanged: (_) => setState(() {}),
                    validator: (v) =>
                        (v == null || v.trim().length < 2) ? 'required_field'.tr() : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _number,
                    decoration: InputDecoration(
                      labelText: 'card_number'.tr(),
                      prefixIcon: Icon(Icons.credit_card, color: primary),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: primary, width: 2),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    onChanged: (_) => setState(() {}),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(19),
                      _CardNumberInputFormatter(),
                    ],
                    validator: (v) {
                      final raw = (v ?? '').replaceAll(RegExp(r'\s+'), '');
                      if (raw.isEmpty) return 'required_field'.tr();
                      if (!_luhnValid(raw)) return tr('invalid_card');
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: _mm,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: 'month'.tr(),
                            prefixIcon: Icon(Icons.calendar_today, color: primary, size: 20),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: primary, width: 2),
                            ),
                          ),
                          items: months
                              .map((m) => DropdownMenuItem(
                                    value: m,
                                    child: Text(m.toString().padLeft(2, '0')),
                                  ))
                              .toList(),
                          onChanged: (v) => setState(() => _mm = v ?? _mm),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: _yyyy,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: 'year'.tr(),
                            prefixIcon: Icon(Icons.event, color: primary, size: 20),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: primary, width: 2),
                            ),
                          ),
                          items: years
                              .map((y) => DropdownMenuItem(value: y, child: Text(y.toString())))
                              .toList(),
                          onChanged: (v) => setState(() => _yyyy = v ?? _yyyy),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _cvv,
                    decoration: InputDecoration(
                      labelText: 'CVV/CVC',
                      prefixIcon: Icon(Icons.lock_outline, color: primary),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: primary, width: 2),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(4),
                    ],
                    validator: (v) {
                      final s = (v ?? '').trim();
                      if (s.length < 3 || s.length > 4) return tr('invalid_cvv');
                      return null;
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Security info
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.shield_outlined, color: Colors.green.shade700, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'your_information_is_secure'.tr(),
                      style: TextStyle(
                        color: Colors.green.shade900,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        'add_your_card'.tr(),
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 0),
    );
  }
}

/* ===== UI widgets (même style que ChoosePaymentMethodScreen) ===== */

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
          BoxShadow(
            color: Colors.black.withOpacity(.07),
            blurRadius: 16,
            offset: const Offset(0, 8),
          )
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.credit_card, color: primaryColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
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
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.06),
            blurRadius: 12,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: primaryColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF3B3B3B),
                  ),
                ),
              ],
            ),
          ),
          Divider(color: Colors.brown.shade200, height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: child,
          ),
        ],
      ),
    );
  }
}

/// Simple 4-4-4-4 spacing for card number as you type
class _CardNumberInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final buf = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      buf.write(digits[i]);
      final isLast = i == digits.length - 1;
      if (!isLast && (i + 1) % 4 == 0) buf.write(' ');
    }
    final text = buf.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}