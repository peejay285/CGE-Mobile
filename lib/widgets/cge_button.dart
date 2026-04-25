import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';

enum CgeButtonVariant { primary, secondary, magenta, ghost, danger }
enum CgeButtonSize { sm, md, lg }

/// Linear-style button with 0.97 scale press feedback.
/// Minimum 44x44pt touch target on all sizes.
class CgeButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final CgeButtonVariant variant;
  final CgeButtonSize size;
  final IconData? icon;
  final bool isLoading;
  final bool fullWidth;

  const CgeButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = CgeButtonVariant.primary,
    this.size = CgeButtonSize.md,
    this.icon,
    this.isLoading = false,
    this.fullWidth = false,
  });

  @override
  State<CgeButton> createState() => _CgeButtonState();
}

class _CgeButtonState extends State<CgeButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80), // 80ms press down
      reverseDuration: const Duration(milliseconds: 120), // 120ms release
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double get _height {
    switch (widget.size) {
      case CgeButtonSize.sm:
        return 36;
      case CgeButtonSize.md:
        return 44; // 44pt minimum
      case CgeButtonSize.lg:
        return 48;
    }
  }

  double get _fontSize {
    switch (widget.size) {
      case CgeButtonSize.sm:
        return 12;
      case CgeButtonSize.md:
        return 13;
      case CgeButtonSize.lg:
        return 15;
    }
  }

  Color get _backgroundColor {
    switch (widget.variant) {
      case CgeButtonVariant.primary:
        return AppColors.accent;
      case CgeButtonVariant.secondary:
        return Colors.transparent;
      case CgeButtonVariant.magenta:
        return AppColors.magenta;
      case CgeButtonVariant.ghost:
        return Colors.transparent;
      case CgeButtonVariant.danger:
        return AppColors.error;
    }
  }

  Color get _foregroundColor {
    switch (widget.variant) {
      case CgeButtonVariant.primary:
        return AppColors.base;
      case CgeButtonVariant.secondary:
        return AppColors.text;
      case CgeButtonVariant.magenta:
        return Colors.white;
      case CgeButtonVariant.ghost:
        return AppColors.accent;
      case CgeButtonVariant.danger:
        return Colors.white;
    }
  }

  BoxBorder? get _border {
    if (widget.variant == CgeButtonVariant.secondary) {
      return Border.all(color: AppColors.border, width: 1);
    }
    if (widget.variant == CgeButtonVariant.ghost) {
      return null;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.onPressed == null || widget.isLoading;

    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTapDown: isDisabled ? null : (_) {
          _controller.forward();
          HapticFeedback.lightImpact(); // subtle haptic on press
        },
        onTapUp: isDisabled ? null : (_) => _controller.reverse(),
        onTapCancel: isDisabled ? null : () => _controller.reverse(),
        onTap: isDisabled ? null : widget.onPressed,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 150),
          opacity: isDisabled ? 0.4 : 1.0,
          child: Container(
            height: _height,
            width: widget.fullWidth ? double.infinity : null,
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            padding: EdgeInsets.symmetric(
              horizontal: widget.size == CgeButtonSize.sm ? 12 : 16,
            ),
            decoration: BoxDecoration(
              color: _backgroundColor,
              borderRadius: BorderRadius.circular(8),
              border: _border,
            ),
            child: Row(
              mainAxisSize:
                  widget.fullWidth ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.isLoading) ...[
                  SizedBox(
                    width: _fontSize,
                    height: _fontSize,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: _foregroundColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                if (widget.icon != null && !widget.isLoading) ...[
                  Icon(widget.icon, size: _fontSize + 2, color: _foregroundColor),
                  const SizedBox(width: 8),
                ],
                Text(
                  widget.label,
                  style: AppTypography.label.copyWith(
                    fontSize: _fontSize,
                    color: _foregroundColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
