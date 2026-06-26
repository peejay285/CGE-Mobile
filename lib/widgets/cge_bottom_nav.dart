import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../core/theme/app_colors.dart';

/// Bottom nav: 5 items, icon + label, accent for active.
/// All primary navigation visible and reachable in one tap.
class CgeBottomNav extends StatelessWidget {
  const CgeBottomNav({super.key});

  static const _items = [
    _NavItem(icon: LucideIcons.home, label: 'Home', path: '/'),
    _NavItem(
      icon: LucideIcons.shoppingBag,
      label: 'Market',
      path: '/marketplace',
    ),
    _NavItem(icon: LucideIcons.trophy, label: 'Esports', path: '/esports'),
    _NavItem(
      icon: LucideIcons.messageCircle,
      label: 'Messages',
      path: '/messages',
    ),
    _NavItem(icon: LucideIcons.user, label: 'Profile', path: '/profile'),
  ];

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    for (int i = _items.length - 1; i >= 0; i--) {
      if (location.startsWith(_items[i].path)) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final index = _currentIndex(context);
    final colors = AppColors.of(context);

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: colors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: List.generate(_items.length, (i) {
            final item = _items[i];
            final isActive = i == index;

            return Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  if (i != index) {
                    HapticFeedback.selectionClick();
                    context.go(item.path);
                  }
                },
                child: SizedBox(
                  height: 56,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 38,
                        height: 28,
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppColors.accent.withValues(alpha: 0.14)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          item.icon,
                          size: 19,
                          color: isActive
                              ? AppColors.accent
                              : colors.textTertiary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontFamily: 'Sora',
                          fontSize: 10,
                          fontWeight: isActive
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: isActive
                              ? AppColors.accent
                              : colors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final String path;
  const _NavItem({required this.icon, required this.label, required this.path});
}
