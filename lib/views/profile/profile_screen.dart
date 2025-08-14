import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontendemart/viewmodels/auth_viewmodel.dart';
import 'package:frontendemart/views/profile/personal_information_screen.dart';
import 'package:frontendemart/views/profile/change_password_screen.dart';
import 'package:frontendemart/views/homeAdmin/custom_bottom_navbar.dart';
import 'package:frontendemart/routes/routes.dart';

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
    final vm = context.watch<AuthViewModel>();
    final user = vm.userData;

    return Scaffold(
      backgroundColor: const Color(0xFFFCF4F4),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
        title: const Text(
          'Profile',
          style: TextStyle(
            color: Color(0xFFEE6B33),
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: vm.isLoading
          ? const Center(child: CircularProgressIndicator())
          : user == null
              ? const Center(child: Text("Aucune donnée utilisateur trouvée."))
              : SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    child: Column(
                      children: [
                        // HEADER
                        _HeaderCard(name: '${user['username'] ?? 'User'}'),

                        const SizedBox(height: 16),

                        // SECTION 1 — Compte
                        _SectionCard(
                          title: 'Compte',
                          children: [
                            _Cell(
                              icon: Icons.person_outline,
                              text: 'Personal Information',
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const EditProfileScreen(),
                                ),
                              ),
                            ),
                            _Cell(
                              icon: Icons.lock_outline,
                              text: 'Update Password',
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ChangePasswordScreen(),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // SECTION 2 — Services
                        _SectionCard(
                          title: 'Services',
                          children: const [
                            _Cell(
                              icon: Icons.account_balance_wallet_outlined,
                              text: 'Banks and Cards',
                            ),
                            _Cell(
                              icon: Icons.message_outlined,
                              text: 'Message Center',
                            ),
                            _Cell(
                              icon: Icons.settings_outlined,
                              text: 'Settings',
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // SECTION 3 — Alertes
                        _SectionCard(
                          title: 'Alertes',
                          children: const [
                            _Cell(
                              icon: Icons.notifications_none_outlined,
                              text: 'Notifications',
                              badge: '2',
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // LOGOUT
                       _LogoutButton(
  onTap: () {
    context.read<AuthViewModel>().logout(context);
  },
),

                      ],
                    ),
                  ),
                ),
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 4),
    );
  }
}

/* ----------------------------- UI Components ----------------------------- */

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.name});
  final String name;

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
        gradient: const LinearGradient(
          colors: [Color(0xFFFCF4F4), Color.fromARGB(255, 215, 146, 117)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 12, offset: Offset(0, 6)),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white,
            child: Text(
              _initials(name),
              style: TextStyle(
                color: Colors.orange.shade700,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
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
          const Icon(Icons.chevron_right, color: Colors.black45),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          // Titre de section
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: const BoxDecoration(
                    color: Color(0xFFEE6B33),
                    shape: BoxShape.circle,
                  ),
                ),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Items
          ..._withDividers(children),
        ],
      ),
    );
  }

  List<Widget> _withDividers(List<Widget> cells) {
    final widgets = <Widget>[];
    for (var i = 0; i < cells.length; i++) {
      widgets.add(cells[i]);
      if (i != cells.length - 1) {
        widgets.add(const Divider(height: 1, indent: 56)); // indent pour aligner
      }
    }
    return widgets;
  }
}

class _Cell extends StatelessWidget {
  const _Cell({
    required this.icon,
    required this.text,
    this.onTap,
    this.badge,
  });

  final IconData icon;
  final String text;
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
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE8D8),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                Positioned.fill(
                  child: Align(
                    alignment: Alignment.center,
                    child: Icon(icon, color: const Color(0xFFEE6B33), size: 20),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w500),
              ),
            ),
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badge!,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
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
  const _LogoutButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.logout, color: Colors.white),
        label: const Text(
          'Logout',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFEE6B33),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
      ),
    );
  }
}
