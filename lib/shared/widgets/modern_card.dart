import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

enum ModernCardVariant {
  elevated,
  flat,
  glass,
  dark,
  crimson,
}

class ModernCard extends StatefulWidget {
  final Widget child;
  final ModernCardVariant variant;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final VoidCallback? onTap;
  final Border? customBorder;
  final double? width;
  final double? height;
  final Clip clipBehavior;

  const ModernCard({
    super.key,
    required this.child,
    this.variant = ModernCardVariant.elevated,
    this.padding,
    this.margin,
    this.borderRadius = 20,
    this.onTap,
    this.customBorder,
    this.width,
    this.height,
    this.clipBehavior = Clip.antiAlias,
  });

  @override
  State<ModernCard> createState() => _ModernCardState();
}

class _ModernCardState extends State<ModernCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final br = BorderRadius.circular(widget.borderRadius);

    BoxDecoration decoration;
    switch (widget.variant) {
      case ModernCardVariant.elevated:
        decoration = BoxDecoration(
          color: Colors.white,
          borderRadius: br,
          border: widget.customBorder ??
              Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
          boxShadow: AppColors.elevation2,
        );
        break;
      case ModernCardVariant.flat:
        decoration = BoxDecoration(
          color: Colors.white,
          borderRadius: br,
          border: widget.customBorder ??
              Border.all(color: const Color(0xFFF1F5F9), width: 1),
          boxShadow: AppColors.elevation1,
        );
        break;
      case ModernCardVariant.glass:
        decoration = BoxDecoration(
          color: Colors.white.withOpacity(0.85),
          borderRadius: br,
          border: widget.customBorder ??
              Border.all(color: Colors.white.withOpacity(0.7), width: 1.5),
          boxShadow: AppColors.elevation2,
        );
        break;
      case ModernCardVariant.dark:
        decoration = BoxDecoration(
          gradient: AppColors.darkCardGradient,
          borderRadius: br,
          border: widget.customBorder ??
              Border.all(color: AppColors.darkBorder.withOpacity(0.8), width: 1.2),
          boxShadow: AppColors.darkCardShadow,
        );
        break;
      case ModernCardVariant.crimson:
        decoration = BoxDecoration(
          gradient: AppColors.crimsonCardGradient,
          borderRadius: br,
          border: widget.customBorder ??
              Border.all(color: Colors.white.withOpacity(0.2), width: 1.2),
          boxShadow: AppColors.redCardShadow,
        );
        break;
    }

    Widget content = Container(
      width: widget.width,
      height: widget.height,
      padding: widget.padding ?? const EdgeInsets.all(16),
      child: widget.child,
    );

    if (widget.variant == ModernCardVariant.glass) {
      content = ClipRRect(
        borderRadius: br,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: content,
        ),
      );
    }

    Widget cardWidget = AnimatedScale(
      scale: _isPressed && widget.onTap != null ? 0.98 : 1.0,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeInOut,
      child: Container(
        margin: widget.margin,
        decoration: decoration,
        clipBehavior: widget.clipBehavior,
        child: content,
      ),
    );

    if (widget.onTap != null) {
      return GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: cardWidget,
      );
    }

    return cardWidget;
  }
}
