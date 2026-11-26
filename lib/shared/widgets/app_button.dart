import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

enum AppButtonVariant { primary, secondary, outline, text, danger, dark }

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Widget? icon;
  final AppButtonVariant variant;
  final double? width;
  final double height;
  final double borderRadius;

  const AppButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.variant = AppButtonVariant.primary,
    this.width,
    this.height = 46,
    this.borderRadius = 12,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveOnPressed = isLoading ? null : onPressed;
    final isEnabled = effectiveOnPressed != null;

    Widget buttonChild;
    if (isLoading) {
      buttonChild = SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2.2,
          valueColor: AlwaysStoppedAnimation<Color>(
            variant == AppButtonVariant.outline ||
                    variant == AppButtonVariant.text
                ? AppColors.primary
                : Colors.white,
          ),
        ),
      );
    } else if (icon != null) {
      buttonChild = Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          icon!,
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
          ),
        ],
      );
    } else {
      buttonChild = Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
      );
    }

    final br = BorderRadius.circular(borderRadius);

    Widget container;
    switch (variant) {
      case AppButtonVariant.primary:
        container = AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: isEnabled ? AppColors.primary : AppColors.slate200,
            borderRadius: br,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: br,
              onTap: effectiveOnPressed,
              child: Center(
                child: DefaultTextStyle(
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14.5,
                  ),
                  child: buttonChild,
                ),
              ),
            ),
          ),
        );
        break;

      case AppButtonVariant.secondary:
        container = Container(
          decoration: BoxDecoration(
            color: AppColors.lightRed,
            borderRadius: br,
            border: Border.all(
              color: AppColors.redBorder,
              width: 1,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: br,
              onTap: effectiveOnPressed,
              child: Center(
                child: DefaultTextStyle(
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14.5,
                  ),
                  child: buttonChild,
                ),
              ),
            ),
          ),
        );
        break;

      case AppButtonVariant.outline:
        container = Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: br,
            border: Border.all(color: AppColors.borderStrong, width: 1.2),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: br,
              onTap: effectiveOnPressed,
              child: Center(
                child: DefaultTextStyle(
                  style: const TextStyle(
                    color: AppColors.slate800,
                    fontWeight: FontWeight.w700,
                    fontSize: 14.5,
                  ),
                  child: buttonChild,
                ),
              ),
            ),
          ),
        );
        break;

      case AppButtonVariant.danger:
        container = Container(
          decoration: BoxDecoration(
            color: AppColors.darkRed,
            borderRadius: br,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: br,
              onTap: effectiveOnPressed,
              child: Center(
                child: DefaultTextStyle(
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14.5,
                  ),
                  child: buttonChild,
                ),
              ),
            ),
          ),
        );
        break;

      case AppButtonVariant.dark:
        container = Container(
          decoration: BoxDecoration(
            color: AppColors.slate900,
            borderRadius: br,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: br,
              onTap: effectiveOnPressed,
              child: Center(
                child: DefaultTextStyle(
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14.5,
                  ),
                  child: buttonChild,
                ),
              ),
            ),
          ),
        );
        break;

      case AppButtonVariant.text:
        return SizedBox(
          width: width,
          height: height,
          child: TextButton(
            onPressed: effectiveOnPressed,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: br),
            ),
            child: buttonChild,
          ),
        );
    }

    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: container,
    );
  }
}
