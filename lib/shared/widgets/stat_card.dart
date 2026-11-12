import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import 'modern_card.dart';

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color? iconBgColor;
  final VoidCallback? onTap;
  final bool isDark;
  final String? subtitle;
  final Widget? trailing;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.iconColor = AppColors.primary,
    this.iconBgColor,
    this.onTap,
    this.isDark = false,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveIconBg = iconBgColor ??
        (isDark
            ? iconColor.withOpacity(0.2)
            : iconColor.withOpacity(0.1));

    return ModernCard(
      variant: isDark ? ModernCardVariant.dark : ModernCardVariant.elevated,
      borderRadius: 16,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: effectiveIconBg,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withOpacity(0.08)
                        : iconColor.withOpacity(0.18),
                    width: 1,
                  ),
                ),
                child: Icon(
                  icon,
                  size: 16,
                  color: iconColor,
                ),
              ),
              if (trailing != null)
                trailing!
              else if (onTap != null)
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 11,
                  color: isDark ? AppColors.darkTextMuted : AppColors.slate400,
                ),
            ],
          ),
          const SizedBox(height: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : AppColors.slate900,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkTextMuted : AppColors.slate600,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 1),
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white54 : AppColors.slate400,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
