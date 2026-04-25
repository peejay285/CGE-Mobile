import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/theme/app_colors.dart';

class CgeAvatar extends StatelessWidget {
  final String? imageUrl;
  final String? name;
  final double size;

  const CgeAvatar({
    super.key,
    this.imageUrl,
    this.name,
    this.size = 40,
  });

  static const _fallbackColors = [
    AppColors.cyan,
    AppColors.magenta,
    AppColors.gold,
  ];

  String get _initials {
    if (name == null || name!.isEmpty) return '?';
    final parts = name!.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  Color get _fallbackColor {
    if (name == null || name!.isEmpty) return _fallbackColors[0];
    return _fallbackColors[name!.length % _fallbackColors.length];
  }

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: imageUrl != null && imageUrl!.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: imageUrl!,
                fit: BoxFit.cover,
                placeholder: (_, _) => _initialsWidget(),
                errorWidget: (_, _, _) => _initialsWidget(),
              )
            : _initialsWidget(),
      ),
    );
  }

  Widget _initialsWidget() {
    return Container(
      color: _fallbackColor.withValues(alpha: 0.2),
      alignment: Alignment.center,
      child: Text(
        _initials,
        style: TextStyle(
          fontFamily: 'Rajdhani',
          fontSize: size * 0.4,
          fontWeight: FontWeight.w600,
          color: _fallbackColor,
        ),
      ),
    );
  }
}
