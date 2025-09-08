import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:frontendemart/l10n/app_localizations.dart';
import 'package:frontendemart/views/homeAdmin/home_screen.dart';
import 'package:frontendemart/views/profile/profile_screen.dart';

/// Bottom bar "glass + sliding capsule"
// … même imports

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  const CustomBottomNavBar({super.key, required this.currentIndex});

  static const _accent = Color(0xFFEE6B33);

  void _navigate(BuildContext context, int index) {
    // garde-fou
    final safeIndex = index.clamp(0, 4);
    index = safeIndex;

    Widget dest;
    switch (index) {
      case 0: dest = const HomeScreen(); break;
      case 1: dest = const Center(child: Text('PromoScreen')); break;
      case 2: dest = const Center(child: Text('ProductScreen')); break;
      case 3: dest = const Center(child: Text('StoreScreen')); break;
      case 4: dest = const ProfileScreen(); break;
      default: dest = const HomeScreen();
    }

    final current = ModalRoute.of(context)?.settings.name;
    final target = dest.runtimeType.toString();
    if (current != target) {
      // petit haptique sympa
      Feedback.forTap(context);
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          settings: RouteSettings(name: target),
          transitionDuration: const Duration(milliseconds: 220),
          pageBuilder: (_, __, ___) => dest,
          transitionsBuilder: (_, a, __, child) =>
              FadeTransition(opacity: CurvedAnimation(parent: a, curve: Curves.easeOutCubic), child: child),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

final items = [
  _NavItem(Icons.home_outlined, l10n.navHome),
  _NavItem(Icons.discount_outlined, l10n.navPromo),
  _NavItem(Icons.shopping_bag_outlined, l10n.navShop),
  _NavItem(Icons.storefront_outlined, l10n.navStores),
  _NavItem(Icons.person_outline, l10n.navProfile),
];


    final idx = currentIndex.clamp(0, items.length - 1);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.18),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white.withOpacity(.40), width: 1),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(.08), blurRadius: 18, offset: const Offset(0, 10)),
              ],
            ),
            child: _SlidingCapsule(
              index: idx,
              itemCount: items.length,
              child: Row(
                children: List.generate(items.length, (i) {
                  final selected = i == idx;
                  return Expanded(
                    child: _BarItem(
                      item: items[i],
                      selected: selected,
                      onTap: () => _navigate(context, i),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}


/// Fond "capsule" qui glisse sous l’onglet actif
class _SlidingCapsule extends StatelessWidget {
  final int index;
  final int itemCount;
  final Widget child;
  const _SlidingCapsule({
    required this.index,
    required this.itemCount,
    required this.child,
  });

  /// Map l’index -> align -1.0 .. 1.0
  double get _alignmentX =>
      itemCount <= 1 ? 0 : (index / (itemCount - 1)) * 2 - 1;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AnimatedAlign(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          alignment: Alignment(_alignmentX, 0),
          child: FractionallySizedBox(
            widthFactor: 1 / itemCount,
            heightFactor: 1,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.28),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white.withOpacity(.45), width: 1),
                ),
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

/// Un item de la barre
class _BarItem extends StatelessWidget {
  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;
  const _BarItem({required this.item, required this.selected, required this.onTap});

  static const _accent = CustomBottomNavBar._accent;

  @override
  Widget build(BuildContext context) {
    final inactive = Colors.black.withOpacity(.45);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      splashColor: _accent.withOpacity(.12),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeOutCubic,
        child: selected
            ? Row(
                key: const ValueKey('selected'),
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedScale(
                    duration: const Duration(milliseconds: 180),
                    scale: 1.1,
                    child: Icon(item.icon, color: _accent, size: 24),
                  ),
                  const SizedBox(width: 8),
                  // Label visible uniquement pour l’actif
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 180),
                    style: const TextStyle(
                      color: _accent,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      letterSpacing: .2,
                    ),
                    child: Text(item.label),
                  ),
                ],
              )
            : Center(
                key: const ValueKey('idle'),
                child: Icon(item.icon, color: inactive, size: 24),
              ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem(this.icon, this.label);
}
