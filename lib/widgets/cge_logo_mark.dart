import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

class CgeLogoMark extends StatelessWidget {
  static const double _logoAspectRatio = 1193 / 808;

  final double height;
  final EdgeInsetsGeometry? padding;
  final double outlineWidth;

  const CgeLogoMark({
    super.key,
    this.height = 40,
    this.padding,
    this.outlineWidth = 1.35,
  });

  Widget _logoImage() {
    return Image.asset(
      'assets/images/cge_logo.png',
      height: height,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
    );
  }

  Widget _edgeLayer(Color color, Offset offset) {
    return Transform.translate(
      offset: offset,
      child: ColorFiltered(
        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
        child: _logoImage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final stroke = isLight ? outlineWidth : outlineWidth * 0.55;
    final softStroke = stroke * 1.75;
    final outlineColor = isLight
        ? const Color(0xFF07111F).withValues(alpha: 0.9)
        : Colors.black.withValues(alpha: 0.38);

    final edgeOffsets = <Offset>[
      Offset(-stroke, 0),
      Offset(stroke, 0),
      Offset(0, -stroke),
      Offset(0, stroke),
      Offset(-stroke, -stroke),
      Offset(stroke, -stroke),
      Offset(-stroke, stroke),
      Offset(stroke, stroke),
    ];

    final softEdgeOffsets = <Offset>[
      Offset(-softStroke, 0),
      Offset(softStroke, 0),
      Offset(0, -softStroke),
      Offset(0, softStroke),
      Offset(-softStroke, -softStroke),
      Offset(softStroke, -softStroke),
      Offset(-softStroke, softStroke),
      Offset(softStroke, softStroke),
    ];

    final mark = SizedBox(
      width: (height * _logoAspectRatio) + (softStroke * 4),
      height: height + (softStroke * 4),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          if (isLight)
            for (final offset in softEdgeOffsets)
              _edgeLayer(AppColors.cyan.withValues(alpha: 0.13), offset),
          if (isLight)
            _edgeLayer(
              Colors.black.withValues(alpha: 0.18),
              Offset(0, stroke * 2.1),
            ),
          for (final offset in edgeOffsets) _edgeLayer(outlineColor, offset),
          _logoImage(),
        ],
      ),
    );

    if (padding == null) return mark;
    return Padding(padding: padding!, child: mark);
  }
}
