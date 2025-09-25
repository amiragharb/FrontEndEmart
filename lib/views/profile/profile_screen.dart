import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import 'package:frontendemart/viewmodels/auth_viewmodel.dart';
import 'package:frontendemart/views/profile/personal_information_screen.dart';
import 'package:frontendemart/views/profile/change_password_screen.dart';
import 'package:frontendemart/views/homeAdmin/custom_bottom_navbar.dart';
import 'package:frontendemart/views/homeAdmin/home_screen.dart';
import 'package:frontendemart/viewmodels/Config_ViewModel.dart';
import 'package:frontendemart/change_langue/change_language.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<AuthViewModel>().loadUserProfile(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final _ = context.locale; // pour rebuild sur changement de langue
    final vm = context.watch<AuthViewModel>();
    final user = vm.userData;

    // Couleur primaire dynamique
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
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: primaryColor),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const HomeScreen()),
            );
          },
        ),
        title: Text(
          'profile'.tr(),
          style: TextStyle(
            color: primaryColor,
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: vm.isLoading
          ? const Center(child: CircularProgressIndicator())
          : user == null || user['username'] == null
              ? Center(child: Text("no_user_data_found".tr()))
              : SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    child: Column(
                      children: [
                        _HeaderCard(name: (user['username'] as String?)?.isNotEmpty == true ? user['username'] : 'User', primaryColor: primaryColor),
                        const SizedBox(height: 16),
                        _SectionCard(
                          titleKey: 'account',
                          primaryColor: primaryColor,
                          children: [
                            _Cell(
                              icon: Icons.person_outline,
                              textKey: 'personal_information',
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                              ),
                            ),
                            _Cell(
                              icon: Icons.lock_outline,
                              textKey: 'update_password',
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _SectionCard(
                          titleKey: 'services',
                          primaryColor: primaryColor,
                          children: [
                            _Cell(icon: Icons.account_balance_wallet_outlined, textKey: 'banks_and_cards'),
                            _Cell(icon: Icons.message_outlined, textKey: 'message_center'),
                            _Cell(icon: Icons.settings_outlined, textKey: 'settings'),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _SectionCard(
                          titleKey: 'alerts',
                          primaryColor: primaryColor,
                          children: [
                            _Cell(icon: Icons.notifications_none_outlined, textKey: 'notifications', badge: '2'),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _LogoutButton(onTap: () => context.read<AuthViewModel>().logout(context), primaryColor: primaryColor),
                      ],
                    ),
                  ),
                ),
      bottomNavigationBar: CustomBottomNavBar(currentIndex: 4),
    );
  }
}

/* ----------------------------- UI Components ----------------------------- */

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.name, required this.primaryColor});
  final String name;
  final Color primaryColor;

  String _initials(String n) {
    final parts = n.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [Colors.white.withOpacity(0.9), primaryColor.withOpacity(0.3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 12, offset: Offset(0, 6))],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white,
            child: Text(
              _initials(name),
              style: TextStyle(color: primaryColor, fontSize: 20, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ),
          Consumer<LocaleProvider>(
            builder: (context, localeProvider, _) {
              return PopupMenuButton<Locale>(
                onSelected: (locale) async {
                  await context.setLocale(locale);
                  localeProvider.setLocale(locale);
                },
                tooltip: 'change_language'.tr(),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                itemBuilder: (context) => [
                  PopupMenuItem(value: const Locale('en'), child: Row(children: [const Text("🇺🇸 "), const SizedBox(width: 8), Text("English".tr())])),
                  PopupMenuItem(value: const Locale('ar'), child: Row(children: [const Text("🇪🇬 "), const SizedBox(width: 8), Text("العربية".tr())])),
                ],
                child: Container(
                  width: 44,
                  height: 44,
                  margin: const EdgeInsets.only(left: 8),
                  decoration: BoxDecoration(
                    color: primaryColor,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 8, offset: const Offset(0, 4))],
                  ),
                  child: const Icon(Icons.language, color: Colors.white),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.titleKey, required this.children, required this.primaryColor});
  final String titleKey;
  final List<Widget> children;
  final Color primaryColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              children: [
                Container(width: 6, height: 6, margin: const EdgeInsets.only(right: 8), decoration: BoxDecoration(color: primaryColor, shape: BoxShape.circle)),
                Text(titleKey.tr(), style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.black87)),
              ],
            ),
          ),
          const Divider(height: 1),
          ..._withDividers(children),
        ],
      ),
    );
  }

  List<Widget> _withDividers(List<Widget> cells) {
    final widgets = <Widget>[];
    for (var i = 0; i < cells.length; i++) {
      widgets.add(cells[i]);
      if (i != cells.length - 1) widgets.add(const Divider(height: 1, indent: 56));
    }
    return widgets;
  }
}

class _Cell extends StatelessWidget {
  const _Cell({required this.icon, required this.textKey, this.onTap, this.badge});
  final IconData icon;
  final String textKey;
  final VoidCallback? onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
        child: Row(
          children: [
            Stack(
              children: [
                Container(width: 36, height: 36, decoration: BoxDecoration(color: const Color.fromARGB(255, 255, 255, 255), borderRadius: BorderRadius.circular(10))),
                Positioned.fill(child: Align(alignment: Alignment.center, child: Icon(icon, color: const Color.fromARGB(255, 24, 20, 18), size: 20))),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(textKey.tr(), style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w500))),
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10)),
                child: Text(badge!, style: const TextStyle(color: Colors.white, fontSize: 12)),
              ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right, color: Colors.black38),
          ],
        ),
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  const _LogoutButton({required this.onTap, required this.primaryColor});
  final VoidCallback onTap;
  final Color primaryColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.logout, color: Colors.white),
        label: Text('logout'.tr(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
      ),
    );
  }
}
