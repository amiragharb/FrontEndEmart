import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:frontendemart/views/Items/ShowWishlistScreen.dart';
import 'package:frontendemart/views/Ordres/OrderSummaryScreen.dart';
import 'package:frontendemart/views/homeAdmin/home_screen.dart';
import 'package:frontendemart/views/profile/profile_screen.dart';
import 'package:frontendemart/viewmodels/Config_ViewModel.dart';
import 'package:provider/provider.dart';

class CustomBottomNavBar extends StatefulWidget {
  final int currentIndex;
  const CustomBottomNavBar({super.key, required this.currentIndex});

  @override
  State<CustomBottomNavBar> createState() => _CustomBottomNavBarState();
}

class _CustomBottomNavBarState extends State<CustomBottomNavBar> {
  void _navigate(BuildContext context, int index, List<Widget> destinations) {
    final safeIndex = index.clamp(0, destinations.length - 1);
    final dest = destinations[safeIndex];
    final current = ModalRoute.of(context)?.settings.name;
    final target = dest.runtimeType.toString();

    if (current != target) {
      Feedback.forTap(context);
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          settings: RouteSettings(name: target),
          transitionDuration: const Duration(milliseconds: 300),
          pageBuilder: (_, __, ___) => dest,
          transitionsBuilder: (_, a, __, child) {
            return FadeTransition(
              opacity: CurvedAnimation(parent: a, curve: Curves.easeInOut),
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.1),
                  end: Offset.zero,
                ).animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
                child: child,
              ),
            );
          },
        ),
      );
    }
  }

  Color _parseHexColor(String? hex, {Color fallback = const Color(0xFFEE6B33)}) {
    if (hex == null) return fallback;
    var s = hex.trim().replaceAll('#', '');
    if (s.toLowerCase().startsWith('0x')) s = s.substring(2);
    if (s.length == 6) s = 'FF$s';
    final v = int.tryParse(s, radix: 16);
    return v != null ? Color(v) : fallback;
  }

  @override
  Widget build(BuildContext context) {
    final configVM = Provider.of<ConfigViewModel>(context);
    final config = configVM.config;
    final primaryColor = _parseHexColor(config?.ciPrimaryColor);

    final items = <_NavItem>[
      _NavItem(Icons.home_rounded, Icons.home_outlined, 'home'.tr()),
      _NavItem(Icons.receipt_long_rounded, Icons.receipt_long_outlined, 'orders'.tr()),
      _NavItem(Icons.favorite_rounded, Icons.favorite_border, 'wishlist'.tr()),
      _NavItem(Icons.person_rounded, Icons.person_outline, 'account'.tr()),
    ];

    final destinations = <Widget>[
      const HomeScreen(),
      const OrderSummaryScreen(),
      const ShowWishlistScreen(),
      const ProfileScreen(),
    ];

    final idx = widget.currentIndex.clamp(0, items.length - 1);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.15),
            blurRadius: 30,
            offset: const Offset(0, 10),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: Row(
          children: List.generate(items.length, (i) {
            final selected = i == idx;
            return Expanded(
              child: _ModernBarItem(
                item: items[i],
                selected: selected,
                primaryColor: primaryColor,
                onTap: () => _navigate(context, i, destinations),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _ModernBarItem extends StatefulWidget {
  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;
  final Color primaryColor;

  const _ModernBarItem({
    required this.item,
    required this.selected,
    required this.primaryColor,
    required this.onTap,
  });

  @override
  State<_ModernBarItem> createState() => _ModernBarItemState();
}

class _ModernBarItemState extends State<_ModernBarItem> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    if (widget.selected) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(_ModernBarItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selected != oldWidget.selected) {
      if (widget.selected) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(25),
        splashColor: widget.primaryColor.withOpacity(0.1),
        highlightColor: widget.primaryColor.withOpacity(0.05),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Transform.scale(
                    scale: widget.selected ? _scaleAnimation.value : 1.0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: widget.selected
                            ? widget.primaryColor.withOpacity(0.15)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        widget.selected ? widget.item.iconFilled : widget.item.iconOutlined,
                        color: widget.selected
                            ? widget.primaryColor
                            : Colors.grey.shade600,
                        size: 24,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 2),
              Flexible(
                child: AnimatedBuilder(
                  animation: _fadeAnimation,
                  builder: (context, child) {
                    return AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: TextStyle(
                        color: widget.selected
                            ? widget.primaryColor
                            : Colors.grey.shade600,
                        fontWeight: widget.selected ? FontWeight.w600 : FontWeight.w500,
                        fontSize: widget.selected ? 11 : 10,
                      ),
                      child: Text(
                        widget.item.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData iconFilled;
  final IconData iconOutlined;
  final String label;
  const _NavItem(this.iconFilled, this.iconOutlined, this.label);
}