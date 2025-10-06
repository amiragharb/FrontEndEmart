import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:frontendemart/change_langue/change_language.dart';
import 'package:frontendemart/viewmodels/Config_ViewModel.dart';
import 'package:intl/intl.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/country_picker_dialog.dart'; // 👈 pour PickerDialogStyle
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';

import 'login_screen.dart';
import 'package:frontendemart/models/user_model.dart';
import 'package:frontendemart/viewmodels/auth_viewmodel.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});
  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final fullNameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final phoneController = TextEditingController();

  String? completePhoneNumber;
  DateTime? selectedDate;

  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    fullNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  // ===== Utils =====
  Future<void> _pickDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked != null) setState(() => selectedDate = picked);
  }

  Map<String, String> _splitName(String full) {
    final parts = full.trim().split(RegExp(r'\s+'));
    final first = parts.first;
    final last = parts.sublist(1).join(' ');
    return {'first': first, 'last': last};
  }

  Color _parseHexColor(String? hex, {Color fallback = const Color(0xFF233B8E)}) {
    if (hex == null) return fallback;
    var s = hex.trim().replaceAll('#', '');
    if (s.toLowerCase().startsWith('0x')) s = s.substring(2);
    if (s.length == 6) s = 'FF$s';
    final v = int.tryParse(s, radix: 16);
    return v != null ? Color(v) : fallback;
  }

  Color _onPrimary(Color c) {
    final l = (0.299 * c.red + 0.587 * c.green + 0.114 * c.blue) / 255.0;
    return l > 0.6 ? const Color(0xFF1A1A1A) : Colors.white;
  }

  String? _required(String? v) =>
      v == null || v.trim().isEmpty ? 'requiredField'.tr() : null;

  @override
  Widget build(BuildContext context) {
    final _ = context.locale; // rebuild on language change

    // backend config
    final configVM = Provider.of<ConfigViewModel>(context);
    final config = configVM.config;

    // palette dynamique (comme login)
    final primaryColor   = _parseHexColor(config?.ciPrimaryColor);
    final secondaryColor = _parseHexColor(
      config?.ciSecondaryColor,
      fallback: Colors.deepPurple.shade100,
    );
    final onPrimary = _onPrimary(primaryColor);

    final formattedDate = selectedDate != null
        ? DateFormat('yyyy-MM-dd').format(selectedDate!)
        : 'dob'.tr();

    return Scaffold(
      backgroundColor: Colors.white, // 💡 fond blanc comme login
      body: Stack(
        children: [
          // ===== BLOBS (identique style login) =====
          Positioned(
            top: -80, left: -40,
            child: _Blob(color: primaryColor.withOpacity(.22), size: 220),
          ),
          Positioned(
            bottom: -60, right: -30,
            child: _Blob(color: primaryColor.withOpacity(.16), size: 240),
          ),
          Positioned(
            top: -55, right: -35,
            child: _Blob(color: secondaryColor.withOpacity(.20), size: 160),
          ),
          Positioned(
            bottom: -70, left: -50,
            child: _Blob(color: secondaryColor.withOpacity(.18), size: 180),
          ),

          // ===== bouton langue =====
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Align(
                alignment: Alignment.topRight,
                child: Consumer2<ConfigViewModel, LocaleProvider>(
                  builder: (context, cfg, localeProvider, _) {
                    final supported = cfg.supportedLanguages;
                    final isEnglish = context.locale.languageCode == 'en';

                    if (cfg.forcedLanguage != null) {
                      final forced = Locale(cfg.forcedLanguage!);
                      if (context.locale.languageCode != forced.languageCode) {
                        EasyLocalization.of(context)!.setLocale(forced);
                        localeProvider.setLocale(forced);
                      }
                      return const SizedBox.shrink();
                    }

                    if (supported.length > 1) {
                      return GestureDetector(
                        onTap: () async {
                          final newLocale = isEnglish ? const Locale('ar') : const Locale('en');
                          await EasyLocalization.of(context)!.setLocale(newLocale);
                          localeProvider.setLocale(newLocale);
                        },
                        child: Text(
                          isEnglish ? "🇺🇸 English" : "🇪🇬 العربية",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ),
          ),

          // ===== contenu =====
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.network(
                      config?.ciLogo ?? 'assets/logo_BlueTransparent.png',
                      height: 110,
                    ),
                    const SizedBox(height: 16),

                    _GlassCard(
                      padding: const EdgeInsets.fromLTRB(22, 22, 22, 26),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            // Tabs style login
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                GestureDetector(
                                  onTap: () => Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                                  ),
                                  child: Text(
                                    'login'.tr(),
                                    style: const TextStyle(fontSize: 16, color: Colors.black87),
                                  ),
                                ),
                                const SizedBox(width: 20),
                                _GlassTab(
                                  label: 'signup'.tr(),
                                  isActive: true,
                                  underlineColor: primaryColor,
                                ),
                              ],
                            ),
                            const SizedBox(height: 22),

                            // Champs
                            _GlassTextField(
                              controller: fullNameController,
                              hint: 'fullName'.tr(),
                              icon: Icons.person,
                              validator: (v) {
                                final text = (v ?? '').trim();
                                if (text.isEmpty) return 'requiredField'.tr();
                                if (!RegExp(r'^\S+\s+\S+').hasMatch(text)) return 'enterFullName'.tr();
                                return null;
                              },
                              primaryColor: primaryColor,
                            ),
                            const SizedBox(height: 12),

                            _GlassTextField(
                              controller: emailController,
                              hint: 'email'.tr(),
                              icon: Icons.email,
                              keyboardType: TextInputType.emailAddress,
                              validator: _required,
                              primaryColor: primaryColor,
                            ),
                            const SizedBox(height: 12),

                            _GlassPhoneField(
                              controller: phoneController,
                              onChanged: (v) => setState(() => completePhoneNumber = v),
                              hint: 'phoneNumber'.tr(),
                              primaryColor: primaryColor, // <- important
                            ),
                            const SizedBox(height: 12),

                            _GlassTextField(
                              controller: passwordController,
                              hint: 'password'.tr(),
                              icon: Icons.lock,
                              obscure: _obscurePassword,
                              validator: _required,
                              trailing: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
                                  color: Colors.black87,
                                ),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                              primaryColor: primaryColor,
                            ),
                            const SizedBox(height: 12),

                            _GlassTextField(
                              controller: confirmPasswordController,
                              hint: 'rePassword'.tr(),
                              icon: Icons.lock_outline,
                              obscure: _obscureConfirm,
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return 'requiredField'.tr();
                                if (v != passwordController.text) return 'passwordMismatch'.tr();
                                return null;
                              },
                              trailing: IconButton(
                                icon: Icon(
                                  _obscureConfirm ? Icons.visibility : Icons.visibility_off,
                                  color: Colors.black87,
                                ),
                                onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                              ),
                              primaryColor: primaryColor,
                            ),
                            const SizedBox(height: 12),

                            _GlassTappable(
                              onTap: () => _pickDate(context),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_month, color: Colors.black87),
                                  const SizedBox(width: 12),
                                  Text(formattedDate, style: const TextStyle(fontSize: 16)),
                                ],
                              ),
                            ),
                            const SizedBox(height: 22),

                            _GlassButton(
                              label: 'signUpBtn'.tr(),
                              color: primaryColor,
                              onColor: onPrimary,
                              onPressed: () {
                                if (_formKey.currentState!.validate()) {
                                  if (selectedDate == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('selectDob'.tr())),
                                    );
                                    return;
                                  }
                                  if (completePhoneNumber == null || completePhoneNumber!.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('validPhone'.tr())),
                                    );
                                    return;
                                  }
                                  final parts = _splitName(fullNameController.text);
                                  final user = UserModel(
                                    email: emailController.text.trim(),
                                    password: passwordController.text.trim(),
                                    firstName: parts['first'] ?? '',
                                    lastName: parts['last'] ?? '',
                                    mobile: completePhoneNumber!,
                                    dateOfBirth: DateFormat('yyyy-MM-dd').format(selectedDate!),
                                  );
                                  Provider.of<AuthViewModel>(context, listen: false).signup(user, context);
                                }
                              },
                            ),

                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('${'alreadyAccount'.tr()} '),
                                GestureDetector(
                                  onTap: () => Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                                  ),
                                  child: Text(
                                    'login'.tr(),
                                    style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/* -------------------- Glass widgets -------------------- */

class _GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const _GlassCard({required this.child, this.padding = const EdgeInsets.all(20)});
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.35),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withOpacity(0.6), width: 1),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(.08), blurRadius: 24, offset: const Offset(0, 10)),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _GlassTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscure;
  final String? Function(String?)? validator;
  final Widget? trailing;
  final TextInputType keyboardType;
  final Color? primaryColor;

  const _GlassTextField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.validator,
    this.trailing,
    this.keyboardType = TextInputType.text,
    this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final pc = primaryColor ?? const Color(0xFF233B8E);
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: TextFormField(
          controller: controller,
          obscureText: obscure,
          validator: validator,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white.withOpacity(.45),
            hintText: hint,
            prefixIcon: Icon(icon, color: Colors.black87),
            suffixIcon: trailing,
            contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(color: Colors.white.withOpacity(.7)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(color: Colors.white.withOpacity(.6)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: const BorderRadius.all(Radius.circular(18)),
              borderSide: BorderSide(color: pc, width: 1.4), // dynamique
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassPhoneField extends StatefulWidget {
  final TextEditingController controller;
  final void Function(String completeNumber) onChanged;
  final String hint;
  final Color? primaryColor; // <- nouveau

  const _GlassPhoneField({
    required this.controller,
    required this.onChanged,
    required this.hint,
    this.primaryColor,
  });

  @override
  State<_GlassPhoneField> createState() => _GlassPhoneFieldState();
}

class _GlassPhoneFieldState extends State<_GlassPhoneField> {
  late final FocusNode _fn;
  bool _focused = false;

  Color get _primary => widget.primaryColor ?? const Color(0xFF233B8E);

  @override
  void initState() {
    super.initState();
    _fn = FocusNode();
    _fn.addListener(() {
      if (mounted) setState(() => _focused = _fn.hasFocus);
    });
  }

  @override
  void dispose() {
    _fn.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textDirection = Directionality.of(context);

    // 👇 Thème local + style du picker pour harmoniser le bottom sheet
    final themed = Theme(
      data: Theme.of(context).copyWith(
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
        ),
        dialogBackgroundColor: Colors.white,
        colorScheme: Theme.of(context).colorScheme.copyWith(
          primary: _primary,
          secondary: _primary.withOpacity(.12),
        ),
      ),
      child: IntlPhoneField(
        controller: widget.controller,
        focusNode: _fn,
        initialCountryCode: 'EG',
        showDropdownIcon: true,
        disableLengthCheck: true,
        searchText: 'searchCountry'.tr(),
        cursorColor: _primary,
        dropdownIcon: Icon(Icons.arrow_drop_down, color: _primary),

        // 👇 style dédié au panel de sélection
        pickerDialogStyle: PickerDialogStyle(
          backgroundColor: Colors.white,
          searchFieldInputDecoration: InputDecoration(
            hintText: 'searchCountry'.tr(),
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _primary, width: 1.4),
            ),
          ),
          countryNameStyle: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
          countryCodeStyle: const TextStyle(color: Colors.black54),
          listTileDivider: Divider(color: _primary.withOpacity(.18), height: 1),
        ),

        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: widget.hint,
          hintStyle: const TextStyle(fontSize: 16),
          hintTextDirection: textDirection,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        onChanged: (phone) => widget.onChanged(phone.completeNumber),
      ),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(.45),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: _focused ? _primary : Colors.white.withOpacity(.7),
              width: _focused ? 1.6 : 1.0,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: themed,
        ),
      ),
    );
  }
}

class _GlassTappable extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;
  const _GlassTappable({required this.onTap, required this.child});
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: InkWell(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.45),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withOpacity(.7)),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _GlassButton extends StatelessWidget {
  final String label;
  final Color color;
  final Color? onColor;
  final VoidCallback onPressed;
  const _GlassButton({
    required this.label,
    required this.color,
    required this.onPressed,
    this.onColor,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = onColor ??
        ((0.299 * color.red + 0.587 * color.green + 0.114 * color.blue) / 255.0 > 0.6
            ? const Color(0xFF1A1A1A)
            : Colors.white);

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: color.withOpacity(.95),
              foregroundColor: textColor,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              elevation: 6,
              shadowColor: color.withOpacity(.35),
            ),
            onPressed: onPressed,
            child: Text(
              label,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassTab extends StatelessWidget {
  final String label;
  final bool isActive;
  final Color underlineColor;
  const _GlassTab({
    required this.label,
    required this.isActive,
    required this.underlineColor,
  });

  @override
  Widget build(BuildContext context) {
    final locale = context.locale.languageCode;
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isActive ? underlineColor : Colors.black87,
          ),
          textAlign: locale == 'ar' ? TextAlign.right : TextAlign.left,
        ),
        const SizedBox(height: 6),
        if (isActive)
          Container(
            height: 2,
            width: 56,
            decoration: BoxDecoration(
              color: underlineColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
      ],
    );
  }
}

class _Blob extends StatelessWidget {
  final Color color;
  final double size;
  const _Blob({required this.color, required this.size});
  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: color, blurRadius: 90, spreadRadius: 40)],
        ),
      ),
    );
  }
}
