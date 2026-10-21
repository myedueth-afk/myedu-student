import 'package:eschool/utils/svgColorSwap.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// A single-colour SVG icon painted in the theme's primary colour, so it
/// follows the colour a school is built with. Pass [color] where the icon sits
/// on a coloured surface and needs the contrasting colour.
class AppIcon extends StatelessWidget {
  final String assetPath;
  final double? size;
  final Color? color;
  final BoxFit fit;

  const AppIcon(
    this.assetPath, {
    Key? key,
    this.size,
    this.color,
    this.fit = BoxFit.contain,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      assetPath,
      width: size,
      height: size,
      fit: fit,
      colorFilter: ColorFilter.mode(
        color ?? Theme.of(context).colorScheme.primary,
        BlendMode.srcIn,
      ),
    );
  }
}

/// A menu icon on its rounded tile: the tile is a tint of the icon's colour.
class AppIconTile extends StatelessWidget {
  final String assetPath;
  final double size;
  final Color? color;

  static const double defaultSize = 58;

  //The icon's share of the tile and the tile's corner, as designed at 58
  static const double _iconScale = 42 / defaultSize;
  static const double _radiusScale = 12 / defaultSize;
  static const double _tileOpacity = 0.08;

  const AppIconTile(
    this.assetPath, {
    Key? key,
    this.size = defaultSize,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final iconColor = color ?? Theme.of(context).colorScheme.primary;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: _tileOpacity),
        borderRadius: BorderRadius.circular(size * _radiusScale),
      ),
      child: AppIcon(assetPath, size: size * _iconScale, color: iconColor),
    );
  }
}

/// A two-tone bottom navigation icon: the outline takes the theme's secondary
/// colour and the selected icon's fill takes the onPrimary accent colour.
class BottomNavIcon extends StatelessWidget {
  final String assetPath;
  final double size;

  const BottomNavIcon(this.assetPath, {Key? key, this.size = 24})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SvgPicture.asset(
      assetPath,
      width: size,
      height: size,
      colorMapper: SvgColorSwap({
        SvgSourceColors.navOutline: colorScheme.secondary,
        SvgSourceColors.accent: colorScheme.onPrimary,
      }),
    );
  }
}

/// A multi-colour illustration whose brand-coloured parts follow the theme's
/// primary colour; skin, hair and the other colours stay as drawn. A second
/// brand tone becomes a lighter primary, so two-tone artwork stays two-tone.
class AppIllustration extends StatelessWidget {
  final String assetPath;
  final double? width;
  final double? height;
  final BoxFit fit;

  const AppIllustration(
    this.assetPath, {
    Key? key,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
  }) : super(key: key);

  static const double _secondToneOpacity = 0.5;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return SvgPicture.asset(
      assetPath,
      width: width,
      height: height,
      fit: fit,
      colorMapper: SvgColorSwap({
        SvgSourceColors.brand: primary,
        SvgSourceColors.legacyBrand: primary,
        SvgSourceColors.accent: primary.withValues(alpha: _secondToneOpacity),
      }),
    );
  }
}
