import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final bool isLight;

  const AppLogo({
    super.key,
    this.size = 56,
    this.showText = true,
    this.isLight = false,
  });

  @override
  Widget build(BuildContext context) {
    final iconWidget = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isLight ? Colors.white : Colors.white,
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.28),
        child: Image.asset(
          'assets/images/logo.png',
          width: size,
          height: size,
          fit: BoxFit.contain,
        ),
      ),
    );

    if (!showText) return iconWidget;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        iconWidget,
        const SizedBox(height: 12),
        RichText(
          text: TextSpan(
            text: 'Suara',
            style: TextStyle(
              fontSize: size * 0.42,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
            children: const [
              TextSpan(
                text: 'Siswa',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Berani bersuara, bersama mencari solusi.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: size * 0.22,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}
