import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/pockii_colors.dart';

/// A glassmorphic card widget inspired by Revolut's design system.
///
/// Creates a frosted-glass effect using BackdropFilter with blur,
/// a semi-transparent background, and a subtle border.
///
/// Usage:
/// ```dart
/// GlassmorphicCard(
///   child: Text('Hello'),
/// )
/// ```
class GlassmorphicCard extends StatelessWidget {
  const GlassmorphicCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.borderRadius = 20,
    this.blur = 12,
    this.backgroundColor,
    this.borderColor,
    this.gradient,
    this.width,
    this.height,
    this.onTap,
    this.margin,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final double blur;
  final Color? backgroundColor;
  final Color? borderColor;
  final Gradient? gradient;
  final double? width;
  final double? height;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    Widget card = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            gradient: gradient,
            color: gradient == null
                ? (backgroundColor ?? AppColors.glassOverlay)
                : null,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: borderColor ?? AppColors.glassBorder,
              width: 1.0,
            ),
          ),
          padding: padding,
          child: child,
        ),
      ),
    );

    if (margin != null) {
      card = Padding(padding: margin!, child: card);
    }

    if (onTap != null) {
      card = GestureDetector(onTap: onTap, child: card);
    }

    return card;
  }
}

/// A Revolut-style card that adapts to light/dark theme.
class RevolutCard extends StatelessWidget {
  const RevolutCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.borderRadius = 20,
    this.backgroundColor,
    this.borderColor,
    this.gradient,
    this.width,
    this.height,
    this.onTap,
    this.margin,
    this.elevation = 0,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final Color? backgroundColor;
  final Color? borderColor;
  final Gradient? gradient;
  final double? width;
  final double? height;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? margin;
  final double elevation;

  @override
  Widget build(BuildContext context) {
    final effectiveBg = backgroundColor ?? context.pockii.surface;
    final effectiveBorder = borderColor ?? context.pockii.border;

    Widget card = Material(
      color: Colors.transparent,
      elevation: elevation,
      borderRadius: BorderRadius.circular(borderRadius),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          gradient: gradient,
          color: gradient == null ? effectiveBg : null,
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(color: effectiveBorder, width: 1.0),
        ),
        padding: padding,
        child: child,
      ),
    );

    if (margin != null) {
      card = Padding(padding: margin!, child: card);
    }

    if (onTap != null) {
      card = InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        splashColor: AppColors.glassOverlay,
        child: card,
      );
    }

    return card;
  }
}
