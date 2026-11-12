import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../models/report_model.dart';
import '../models/user_model.dart';

class AppBadge extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color textColor;
  final IconData? icon;
  final Border? border;

  const AppBadge({
    super.key,
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    this.icon,
    this.border,
  });

  factory AppBadge.status(ReportStatus status) {
    Color bg;
    Color text;
    IconData icon;

    switch (status) {
      case ReportStatus.submitted:
        bg = AppColors.infoLight;
        text = AppColors.infoDark;
        icon = Icons.send_rounded;
        break;
      case ReportStatus.underReview:
        bg = AppColors.warningLight;
        text = AppColors.warningDark;
        icon = Icons.visibility_rounded;
        break;
      case ReportStatus.inProgress:
        bg = AppColors.purpleLight;
        text = AppColors.purpleDark;
        icon = Icons.sync_rounded;
        break;
      case ReportStatus.waitingForInfo:
        bg = AppColors.warningLight;
        text = AppColors.warningDark;
        icon = Icons.help_outline_rounded;
        break;
      case ReportStatus.resolved:
        bg = AppColors.successLight;
        text = AppColors.successDark;
        icon = Icons.check_circle_rounded;
        break;
      case ReportStatus.closed:
        bg = const Color(0xFFF1F5F9);
        text = const Color(0xFF64748B);
        icon = Icons.lock_outline_rounded;
        break;
      case ReportStatus.transferred:
        bg = AppColors.lightRed;
        text = AppColors.primary;
        icon = Icons.forward_rounded;
        break;
    }

    return AppBadge(
      label: status.label,
      backgroundColor: bg,
      textColor: text,
      icon: icon,
    );
  }

  factory AppBadge.priority(ReportPriority priority) {
    Color bg;
    Color text;
    Border? border;

    switch (priority) {
      case ReportPriority.urgent:
        bg = const Color(0xFFFEF2F2);
        text = const Color(0xFFDC2626);
        border = Border.all(color: const Color(0xFFFECACA), width: 0.8);
        break;
      case ReportPriority.tinggi:
        bg = const Color(0xFFFFFBEB);
        text = const Color(0xFFD97706);
        border = Border.all(color: const Color(0xFFFDE68A), width: 0.8);
        break;
      case ReportPriority.normal:
        bg = const Color(0xFFF8FAFC);
        text = const Color(0xFF64748B);
        border = Border.all(color: const Color(0xFFE2E8F0), width: 0.8);
        break;
    }

    return AppBadge(
      label: priority.label,
      backgroundColor: bg,
      textColor: text,
      border: border,
    );
  }

  factory AppBadge.type(ReportType type) {
    Color bg;
    Color text;
    IconData icon;

    switch (type) {
      case ReportType.bullying:
        bg = const Color(0xFFFEF2F2);
        text = const Color(0xFFDC2626);
        icon = Icons.shield_rounded;
        break;
      case ReportType.konseling:
        bg = const Color(0xFFECFDF5);
        text = const Color(0xFF059669);
        icon = Icons.volunteer_activism_rounded;
        break;
      case ReportType.aspirasi:
        bg = const Color(0xFFEFF6FF);
        text = const Color(0xFF2563EB);
        icon = Icons.lightbulb_rounded;
        break;
      case ReportType.kritikSaran:
        bg = const Color(0xFFF5F3FF);
        text = const Color(0xFF7C3AED);
        icon = Icons.chat_bubble_outline_rounded;
        break;
    }

    return AppBadge(
      label: type.label,
      backgroundColor: bg,
      textColor: text,
      icon: icon,
    );
  }

  factory AppBadge.role(UserRole role) {
    if (role == UserRole.counselor) {
      return const AppBadge(
        label: 'Guru BK',
        backgroundColor: AppColors.lightRed,
        textColor: AppColors.primary,
        icon: Icons.psychology_outlined,
      );
    }
    return const AppBadge(
      label: 'Siswa',
      backgroundColor: AppColors.infoLight,
      textColor: AppColors.infoDark,
      icon: Icons.school_outlined,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(9),
        border: border,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: textColor),
            const SizedBox(width: 3.5),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
