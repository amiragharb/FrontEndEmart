import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:frontendemart/viewmodels/auth_viewmodel.dart';
import 'package:provider/provider.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final emailOrPhoneController = TextEditingController();
  final passwordController = TextEditingController();
  final _forgotEmailCtrl = TextEditingController();

  bool _obscurePassword = true;

  @override
  void dispose() {
    emailOrPhoneController.dispose();
    passwordController.dispose();
    _forgotEmailCtrl.dispose();
    super.dispose();
  }

  // Regex email
  final _emailRx = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  // Regex téléphone égyptien: +20 / 0 + (10|11|12|15) + 8 chiffres
  final _egPhoneRx = RegExp(r'^(?:\+20|0)(10|11|12|15)\d{8}$');
  final _egLocalRx = RegExp(r'^0(10|11|12|15)\d{8}$'); // pour normaliser en +20...

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFFEFE6), Color(0xFFFDE2D6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Positioned(
            top: -80,
            left: -40,
            child:
                _Blob(color: const Color(0xFFFFA26B).withOpacity(.25), size: 220),
          ),
          Positioned(
            bottom: -60,
            right: -30,
            child:
                _Blob(color: const Color(0xFF2E64C5).withOpacity(.18), size: 240),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 16),
                    const Image(
                      image: AssetImage('assets/logo_BlueTransparent.png'),
                      height: 120,
                    ),
                    const SizedBox(height: 16),

                    // GLASS CARD
                    _GlassCard(
                      width: screen.width * .9,
                      padding: const EdgeInsets.fromLTRB(22, 22, 22, 26),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _GlassTab(
                                  label: 'Login',
                                  isActive: true,
                                  underlineColor: const Color(0xFFEE6B33),
                                ),
                                const SizedBox(width: 20),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) => const SignUpScreen()),
                                    );
                                  },
                                  child: const Text(
                                    'Sign-up',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.black87,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 22),
                            _GlassTextField(
                              controller: emailOrPhoneController,
                              hint: 'Email or Egyptian phone',
                              icon: Icons.alternate_email,
                              validator: (v) {
                                final value = (v ?? '').trim();
                                if (value.isEmpty) return 'Required field';
                                final isEmail = _emailRx.hasMatch(value);
                                final isEgPhone = _egPhoneRx.hasMatch(value);
                                if (!isEmail && !isEgPhone) {
                                  return 'Enter a valid email or Egyptian phone';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            _GlassTextField(
                              controller: passwordController,
                              hint: 'Password',
                              icon: Icons.lock,
                              obscure: _obscurePassword,
                              validator: (v) =>
                                  v == null || v.trim().isEmpty
                                      ? 'Required field'
                                      : null,
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

                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: _showForgotPasswordDialog,
                                child: const Text(
                                  'Forget Password?',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 6),
                            _GlassButton(
                              label: 'Login',
                              color: const Color(0xFFEE6B33),
                              onPressed: () {
                                if (_formKey.currentState!.validate()) {
                                  final vm = Provider.of<AuthViewModel>(context,
                                      listen: false);

                                  // Normaliser le téléphone local égyptien -> +20...
                                  String id = emailOrPhoneController.text.trim();
                                  if (_egLocalRx.hasMatch(id)) {
                                    id = '+20${id.substring(1)}';
                                  }

                                  vm.login(
                                    id, // email OU phone (normalisé)
                                    passwordController.text,
                                    context,
                                  );
                                }
                              },
                            ),

                            const SizedBox(height: 16),
                            Row(
                              children: const [
                                Expanded(child: Divider(thickness: .8)),
                                Padding(
                                  padding:
                                      EdgeInsets.symmetric(horizontal: 10),
                                  child: Text(
                                    'Or sign in with',
                                    style: TextStyle(color: Colors.black54),
                                  ),
                                ),
                                Expanded(child: Divider(thickness: .8)),
                              ],
                            ),
                            const SizedBox(height: 14),

                            // Social: cliquables
                            Consumer<AuthViewModel>(
                              builder: (_, vm, __) => Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _GlassCircleIcon(
  icon: FontAwesomeIcons.google,
  iconColor: const Color(0xFFDB4437),
  onTap: () {
    debugPrint('[UI] Google icon tapped'); // ✅ trace UI
    Provider.of<AuthViewModel>(context, listen: false).signInWithGoogle(context);
  },
),

                                  const SizedBox(width: 18),
                                  _GlassCircleIcon(
                                    icon: FontAwesomeIcons.facebookF,
                                    iconColor: const Color(0xFF3b5998),
                                    onTap: () => vm.signInWithFacebook(context),
                                  ),
                                ],
                              ),
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

  /* ---------------- Forgot password ---------------- */

  void _showForgotPasswordDialog() {
    final formKey = GlobalKey<FormState>();
    bool sending = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(.25),
      builder: (_) {
        return StatefulBuilder(
          builder: (ctx, setState) => Dialog(
            insetPadding: const EdgeInsets.symmetric(horizontal: 24),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  color: Colors.white.withOpacity(0.92),
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Reset password',
                            style: TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 18)),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _forgotEmailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) {
                            final email = v?.trim() ?? '';
                            final ok = _emailRx.hasMatch(email);
                            if (email.isEmpty) return 'Email required';
                            if (!ok) return 'Invalid email';
                            return null;
                          },
                          decoration: InputDecoration(
                            hintText: 'Your email',
                            prefixIcon: const Icon(Icons.email_outlined),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            TextButton(
                              onPressed:
                                  sending ? null : () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            const Spacer(),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFEE6B33),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: sending
                                  ? null
                                  : () async {
                                      if (!formKey.currentState!.validate()) {
                                        return;
                                      }
                                      setState(() => sending = true);

                                      final email =
                                          _forgotEmailCtrl.text.trim();
                                      final vm =
                                          Provider.of<AuthViewModel>(context,
                                              listen: false);
                                      final ok = await vm.requestPasswordReset(
                                          context, email);

                                      if (!mounted) return;
                                      if (ok) {
                                        final nav = Navigator.of(context,
                                            rootNavigator: true);
                                        nav.pop(); // fermer 1ère popup
                                        await Future.delayed(
                                            const Duration(milliseconds: 50));
                                        if (!mounted) return;
                                        _showCodeDialog(email); // ouvrir 2ème
                                      } else {
                                        setState(() => sending = false);
                                      }
                                    },
                              child: sending
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    )
                                  : const Text('Send'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showCodeDialog(String email) {
    final codeCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text("Entrez le code reçu par email"),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: codeCtrl,
            autofocus: true,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Code requis' : null,
            decoration: const InputDecoration(
              hintText: "Code",
              prefixIcon: Icon(Icons.lock_outline),
            ),
            onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final vm =
                  Provider.of<AuthViewModel>(context, listen: false);
              await vm.verifyResetCode(
                  context, email, codeCtrl.text.trim());
            },
            child: const Text("Verify"),
          ),
        ],
      ),
    );
  }
}

/* ---------- components ---------- */

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

class _GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double width;
  const _GlassCard({
    required this.child,
    required this.width,
    this.padding = const EdgeInsets.all(20),
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          width: width,
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

  const _GlassTextField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.validator,
    this.trailing,
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
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassCircleIcon extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  const _GlassCircleIcon({
    required this.icon,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      height: 56,
      child: Material( // ✅ Surface Material pour capter les taps
        type: MaterialType.transparency,
        shape: const CircleBorder(),
        child: Ink( // ✅ support du splash + hit test
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(.55),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(.7)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.08),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Center(
              child: Icon(icon, color: iconColor, size: 26),
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
            width: 46,
            decoration: BoxDecoration(
              color: underlineColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
      ],
    );
  }
}
