import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme/app_colors.dart';

/// Compact card: 16px padding, 8px radius. Press feedback on tap.
class CgeCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final bool showGlow;
  final Color glowColor;

  const CgeCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.showGlow = false,
    this.glowColor = AppColors.accent,
  });

  @override
  State<CgeCard> createState() => _CgeCardState();
}

class _CgeCardState extends State<CgeCard> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
      reverseDuration: const Duration(milliseconds: 120),
    );
    _scale = Tween(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: widget.padding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: widget.showGlow
              ? widget.glowColor.withValues(alpha: 0.5)
              : AppColors.border,
          width: 1,
        ),
      ),
      child: widget.child,
    );

    if (widget.onTap == null) return card;

    return ScaleTransition(
      scale: _scale,
      child: GestureDetector(
        onTapDown: (_) {
          _ctrl.forward();
          HapticFeedback.selectionClick();
        },
        onTapUp: (_) => _ctrl.reverse(),
        onTapCancel: () => _ctrl.reverse(),
        onTap: widget.onTap,
        child: card,
      ),
    );
  }
}
