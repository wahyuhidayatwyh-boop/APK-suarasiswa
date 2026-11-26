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
    this.borderRadius = 16,
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
              Border.all(color: AppColors.borderStrong, width: 1),
          boxShadow: [
            BoxShadow(
              color: AppColors.slate900.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        );
        break;
      case ModernCardVariant.flat:
        decoration = BoxDecoration(
          color: Colors.white,
          borderRadius: br,
          border: widget.customBorder ??
              Border.all(color: AppColors.borderStrong, width: 1),
        );
        break;
      case ModernCardVariant.glass:
        decoration = BoxDecoration(
          color: Colors.white,
          borderRadius: br,
          border: widget.customBorder ??
              Border.all(color: AppColors.borderStrong, width: 1),
          boxShadow: AppColors.elevation1,
        );
        break;
      case ModernCardVariant.dark:
        decoration = BoxDecoration(
          gradient: AppColors.darkCardGradient,
          borderRadius: br,
          border: widget.customBorder ??
              Border.all(color: AppColors.darkBorder, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        );
        break;
      case ModernCardVariant.crimson:
        decoration = BoxDecoration(
          gradient: AppColors.crimsonCardGradient,
          borderRadius: br,
          border: widget.customBorder ??
              Border.all(color: Colors.white.withOpacity(0.15), width: 1),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.18),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        );
        break;
    }

    final content = Container(
      width: widget.width,
      height: widget.height,
      padding: widget.padding ?? const EdgeInsets.all(16),
      child: widget.child,
    );

    final cardWidget = AnimatedScale(
      scale: _isPressed && widget.onTap != null ? 0.985 : 1.0,
      duration: const Duration(milliseconds: 100),
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
