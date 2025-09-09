import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:frontendemart/change_langue/change_language.dart';
import 'package:intl/intl.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
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

  // Découper le nom complet en first/last (après validation 2 mots mini)
  Map<String, String> _splitName(String full) {
    final parts = full.trim().split(RegExp(r'\s+'));
    final first = parts.first;
    final last = parts.sublist(1).join(' ');
    return {'first': first, 'last': last};
  }

  @override
Widget build(BuildContext context) {
  // Listen to locale to force rebuild on language change
  final _ = context.locale;
  final formattedDate = selectedDate != null
      ? DateFormat('yyyy-MM-dd').format(selectedDate!)
      : 'dob'.tr();

  return Scaffold
(
    backgroundColor: Colors.white,
    body: Stack(
  children: [
    // fond
    Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFFEFE6), Color(0xFFFDE2D6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    ),

    // blobs décoratifs
    Positioned(
      top: -80,
      left: -40,
      child: _Blob(color: const Color(0xFFFFA26B).withOpacity(.25), size: 220),
    ),
    Positioned(
      bottom: -60,
      right: -30,
      child: _Blob(color: const Color(0xFF2E64C5).withOpacity(.18), size: 240),
    ),
    
         // Removed SizedBox to ensure language switcher is clickable

    // 🌐 bouton langue en haut à droite
    Positioned(
      top: 16,
      right: 16,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: Consumer<LocaleProvider>(
          builder: (context, localeProvider, _) {
            return PopupMenuButton<Locale>(
              onSelected: (locale) async {
                await EasyLocalization.of(context)!.setLocale(locale);
                localeProvider.setLocale(locale);
              },
              tooltip: 'change_language'.tr(),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: Locale('en'),
                  child: Row(
                    children: [
                      Text("🇺🇸 "),
                      SizedBox(width: 8),
                      Text("English"),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: Locale('ar'),
                  child: Row(
                    children: [
                      Text("🇪🇬 "),
                      SizedBox(width: 8),
                      Text("العربية"),
                    ],
                  ),
                ),
              ],
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFEE6B33),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.language,
                  color: Colors.white,
                ),
              ),
            );
          },
        ),
      ),
    ),
         const SizedBox(height: 16),

 
        SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              children: [
                const SizedBox(height: 8),
                const Image(
                  image: AssetImage('assets/logo_BlueTransparent.png'),
                  height: 110,
                ),
                const SizedBox(height: 16),

                // carte verre
                _GlassCard(
                  padding: const EdgeInsets.fromLTRB(22, 22, 22, 26),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // tabs
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            GestureDetector(
                              onTap: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const LoginScreen()),
                                );
                              },
                child: Text(
                  'login'.tr(),
                  style: const TextStyle(
                    fontSize: 16, color: Colors.black87),
                  ),
                            ),
                            const SizedBox(width: 20),
                            _GlassTab(
                              label: 'signup'.tr(),
                              isActive: true,
                              underlineColor: const Color(0xFFEE6B33),
                            ),
                          ],
                        ),

                        const SizedBox(height: 22),
                        _GlassTextField(
                          controller: fullNameController,
                          hint: 'fullName'.tr(),
                          icon: Icons.person,
                          validator: (v) {
                            final text = (v ?? '').trim();
                            if (text.isEmpty) return 'requiredField'.tr();
                            if (!RegExp(r'^\S+\s+\S+').hasMatch(text)) {
                              return 'enterFullName'.tr();
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        _GlassTextField(
                          controller: emailController,
                          hint: 'email'.tr(),
                          icon: Icons.email,
                          keyboardType: TextInputType.emailAddress,
                          validator: _required,
                        ),
                        const SizedBox(height: 12),

                       _GlassPhoneField(
  controller: phoneController,
  onChanged: (v) => setState(() => completePhoneNumber = v),
  hint: 'phoneNumber'.tr(),
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
                              _obscurePassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: Colors.black87,
                            ),
                            onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _GlassTextField(
                          controller: confirmPasswordController,
                          hint: 'rePassword'.tr(),
                          icon: Icons.lock_outline,
                          obscure: _obscureConfirm,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'requiredField'.tr();
                            }
                            if (v != passwordController.text) {
                              return 'passwordMismatch'.tr();
                            }
                            return null;
                          },
                          trailing: IconButton(
                            icon: Icon(
                              _obscureConfirm
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: Colors.black87,
                            ),
                            onPressed: () =>
                                setState(() => _obscureConfirm = !_obscureConfirm),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // date
                        _GlassTappable(
                          onTap: () => _pickDate(context),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_month,
                                  color: Colors.black87),
                              const SizedBox(width: 12),
                              Text(formattedDate,
                                  style: const TextStyle(fontSize: 16)),
                            ],
                          ),
                        ),

                        const SizedBox(height: 22),
                        _GlassButton(
                          label: 'signUpBtn'.tr(),
                          color: const Color(0xFFEE6B33),
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
                              final isEgypt = completePhoneNumber!.startsWith('+20');
                              if (isEgypt) {
                                final egyptianRegex = RegExp(r'^(?:\+20|0)(10|11|12|15)\d{8}$');
                                if (!egyptianRegex.hasMatch(completePhoneNumber!)) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('validEgyptPhone'.tr())),
                                  );
                                  return;
                                }
                              } else {
                                if (completePhoneNumber!.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('validPhone'.tr())),
                                  );
                                  return;
                                }
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
                              onTap: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const LoginScreen()),
                                );
                              },
                              child: Text(
                                'login'.tr(),
                                style: const TextStyle(
                                  color: Color(0xFFEE6B33),
                                  fontWeight: FontWeight.bold,
                                ),
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
      ],
    ),
  );
}


  String? _required(String? v) =>
      v == null || v.trim().isEmpty ? 'Required field' : null;
}

/* -------------------- Glass widgets -------------------- */

class _GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const _GlassCard(
      {required this.child, this.padding = const EdgeInsets.all(20)});
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
              BoxShadow(
                color: Colors.black.withOpacity(.08),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
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

  const _GlassTextField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.validator,
    this.trailing,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
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
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(color: Colors.white.withOpacity(.7)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(color: Colors.white.withOpacity(.6)),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(18)),
              borderSide: BorderSide(color: Color(0xFFEE6B33), width: 1.4),
            ),
          ),
        ),
      ),
    );
  }
}


class _GlassPhoneField extends StatelessWidget {
  final TextEditingController controller;
  final void Function(String completeNumber) onChanged;
  final String hint;

  const _GlassPhoneField({
    required this.controller,
    required this.onChanged,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    final textDirection = Directionality.of(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(.45),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withOpacity(.7)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: IntlPhoneField(
            controller: controller,
            initialCountryCode: 'EG',   // 🇪🇬 Égypte par défaut
            showDropdownIcon: true,
            disableLengthCheck: true,
            searchText: 'searchCountry'.tr(),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: hint,
              hintStyle: const TextStyle(fontSize: 16),
              hintTextDirection: textDirection, // ✅ RTL si arabe, LTR si anglais
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
            onChanged: (phone) => onChanged(phone.completeNumber),
          ),
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
            padding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
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
  final VoidCallback onPressed;
  const _GlassButton({
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: color.withOpacity(.9),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              elevation: 6,
              shadowColor: color.withOpacity(.35),
            ),
            onPressed: onPressed,
            child: Text(
              label,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isActive ? underlineColor : Colors.black87,
          ),
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
          boxShadow: [
            BoxShadow(color: color, blurRadius: 90, spreadRadius: 40),
          ],
        ),
      ),
    );
  }
}
