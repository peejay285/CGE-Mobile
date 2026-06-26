import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../core/theme/app_colors.dart';

/// Skeleton loader — always prefer over spinners for async content.
class CgeSkeleton extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const CgeSkeleton({
    super.key,
    this.width = double.infinity,
    required this.height,
    this.borderRadius = 6,
  });

  const CgeSkeleton.card({super.key})
    : width = double.infinity,
      height = 160,
      borderRadius = 8;

  const CgeSkeleton.text({super.key, this.width = 120})
    : height = 12,
      borderRadius = 4;

  const CgeSkeleton.avatar({super.key, double size = 36})
    : width = size,
      height = size,
      borderRadius = size / 2;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Shimmer.fromColors(
      baseColor: colors.surfaceRaised,
      highlightColor: colors.border,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: colors.surfaceRaised,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}
