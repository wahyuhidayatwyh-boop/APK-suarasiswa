import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../auth/presentation/auth_controller.dart';

class CounselorSchoolSetupScreen extends ConsumerWidget {
  const CounselorSchoolSetupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final school = authState.currentSchool;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            children: [
              const Spacer(),
              // Success Mark
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: AppColors.successLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  size: 40,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Ruang Sekolah Siap Digunakan',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.slate900,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                school?.name ?? 'Sekolah Anda',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 28),

              // School Code Display Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.slate50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderStrong),
                ),
                child: Column(
                  children: [
                    const Text(
                      'KODE BERGABUNG SEKOLAH',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.slate500,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          school?.schoolCode ?? 'SMK-TN82',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: AppColors.slate900,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(width: 10),
                        IconButton(
                          onPressed: () {
                            if (school?.schoolCode != null) {
                              Clipboard.setData(
                                  ClipboardData(text: school!.schoolCode));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content:
                                      Text('Kode sekolah berhasil disalin!'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.copy_rounded,
                              size: 20, color: AppColors.primary),
                          tooltip: 'Salin Kode Sekolah',
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Bagikan kode ini kepada siswa saat mendaftar akun agar terhubung ke ruang sekolah Anda.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.slate600,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),

              // Next Steps Checklist
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.borderStrong),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rekomendasi Langkah Awal:',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.slate900,
                      ),
                    ),
                    SizedBox(height: 10),
                    _StepItem(
                      icon: Icons.meeting_room_outlined,
                      text: 'Buat kelas pertama Anda (misal: X RPL 1)',
                    ),
                    SizedBox(height: 8),
                    _StepItem(
                      icon: Icons.qr_code_rounded,
                      text: 'Bagikan kode sekolah atau kelas ke siswa',
                    ),
                    SizedBox(height: 8),
                    _StepItem(
                      icon: Icons.group_add_outlined,
                      text: 'Undang rekan Guru BK lain bila bertugas bersama',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              AppButton(
                text: 'Masuk ke Dashboard Guru BK',
                onPressed: () {
                  context.go('/counselor');
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _StepItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.slate500),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 12, color: AppColors.slate700),
          ),
        ),
      ],
    );
  }
}
