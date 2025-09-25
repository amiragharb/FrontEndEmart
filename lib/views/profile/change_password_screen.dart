import 'package:flutter/material.dart';
import 'package:frontendemart/viewmodels/auth_viewmodel.dart';
import 'package:frontendemart/viewmodels/Config_ViewModel.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AuthViewModel>();
    final config = context.watch<ConfigViewModel>().config;
    final primaryColor = (config?.ciPrimaryColor != null && config!.ciPrimaryColor!.isNotEmpty)
        ? Color(int.parse('FF${config.ciPrimaryColor}', radix: 16))
        : const Color(0xFFEE6B33);

    return Scaffold(
      backgroundColor: const Color(0xFFFCF4F4),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
        title: Text(
          'change_password'.tr(),
          style: TextStyle(
            color: primaryColor,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        iconTheme: IconThemeData(color: primaryColor),
      ),
      body: vm.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Stack(
                children: [
                  SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
                    child: Column(
                      children: [
                        // Petit header
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            gradient: LinearGradient(
                              colors: [Colors.white.withOpacity(0.9), primaryColor.withOpacity(0.3)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: const [
                              BoxShadow(color: Colors.black12, blurRadius: 12, offset: Offset(0, 6)),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(Icons.lock_reset, color: primaryColor),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'secure_account'.tr(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Formulaire
                        Container(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: const [
                              BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4)),
                            ],
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                _PasswordRow(
                                  label: 'new_password'.tr(),
                                  controller: _passwordController,
                                  obscure: _obscurePassword,
                                  primaryColor: primaryColor,
                                  onToggle: () => setState(() => _obscurePassword = !_obscurePassword),
                                ),
                                const _DividerInset(),
                                _PasswordRow(
                                  label: 'confirm_password'.tr(),
                                  controller: _confirmController,
                                  obscure: _obscureConfirm,
                                  primaryColor: primaryColor,
                                  onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
                                  confirmAgainst: _passwordController,
                                ),
                                const SizedBox(height: 8),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Bouton
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 24,
                    child: SizedBox(
                      height: 54,
                      child: ElevatedButton.icon(
                        onPressed: vm.isLoading ? null : _submit,
                        icon: const Icon(Icons.save_alt, color: Colors.white),
                        label: Text(
                          'save'.tr(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  void _submit() {
    final vm = context.read<AuthViewModel>();
    if (!_formKey.currentState!.validate()) return;
    vm.updatePassword(_passwordController.text.trim(), context);
  }
}

/* --------------------------- UI helper widgets --------------------------- */

class _PasswordRow extends StatelessWidget {
  const _PasswordRow({
    required this.label,
    required this.controller,
    required this.obscure,
    required this.onToggle,
    required this.primaryColor,
    this.confirmAgainst,
  });

  final String label;
  final TextEditingController controller;
  final bool obscure;
  final VoidCallback onToggle;
  final Color primaryColor;
  final TextEditingController? confirmAgainst;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _LeadingIcon(icon: Icons.lock_outline, primaryColor: primaryColor),
          const SizedBox(width: 8),
          Expanded(
            child: TextFormField(
              controller: controller,
              obscureText: obscure,
              validator: (v) {
                if (v == null || v.trim().length < 6) {
                  return 'min_characters'.tr();
                }
                if (confirmAgainst != null && v.trim() != confirmAgainst!.text.trim()) {
                  return 'passwords_not_match'.tr();
                }
                return null;
              },
              decoration: InputDecoration(
                hintText: label,
                isDense: true,
                filled: true,
                fillColor: const Color(0xFFF7F7F7),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: IconButton(
                  onPressed: onToggle,
                  icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LeadingIcon extends StatelessWidget {
  const _LeadingIcon({required this.icon, required this.primaryColor});
  final IconData icon;
  final Color primaryColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: primaryColor),
    );
  }
}

class _DividerInset extends StatelessWidget {
  const _DividerInset();

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, indent: 50);
  }
}
