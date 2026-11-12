import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:suara_siswa/core/constants/app_colors.dart';
import 'package:suara_siswa/features/auth/presentation/auth_controller.dart';
import 'package:suara_siswa/features/classes/data/class_repository.dart';
import 'package:suara_siswa/shared/widgets/app_button.dart';
import 'package:suara_siswa/shared/widgets/modern_card.dart';
import 'package:suara_siswa/shared/widgets/section_header.dart';
import 'package:suara_siswa/shared/widgets/suara_siswa_app_bar.dart';
import 'package:suara_siswa/features/classes/presentation/widgets/select_class_modal.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  final bool isCounselor;

  const ProfileScreen({super.key, required this.isCounselor});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.logout_rounded, color: AppColors.primary, size: 24),
              ),
              const SizedBox(height: 14),
              const Text(
                'Keluar Akun',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.slate900),
              ),
              const SizedBox(height: 6),
              const Text(
                'Apakah Anda yakin ingin keluar dari sesi aplikasi Suara Siswa?',
                style: TextStyle(fontSize: 12.5, color: AppColors.slate600, height: 1.4),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Batal', style: TextStyle(color: AppColors.slate700, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        Navigator.pop(ctx);
                        await ref.read(authControllerProvider.notifier).logout();
                        if (context.mounted) {
                          context.go('/welcome');
                        }
                      },
                      child: const Text('Keluar', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmStudentLeaveClass(BuildContext context, String? className, String? schoolName) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.meeting_room_outlined, color: AppColors.error, size: 24),
              ),
              const SizedBox(height: 14),
              const Text(
                'Keluar dari Kelas?',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.slate900),
              ),
              const SizedBox(height: 6),
              Text(
                'Apakah Anda yakin ingin keluar dari kelas ${className ?? "saat ini"}? Anda tidak lagi terdaftar di rombel ini dan perlu memasukkan kode kelas baru untuk bergabung kembali.',
                style: const TextStyle(fontSize: 12.5, color: AppColors.slate600, height: 1.4),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Batal', style: TextStyle(color: AppColors.slate700, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        Navigator.pop(ctx);
                        final res = await ref.read(classRepositoryProvider).studentLeaveClass();
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(res.success ? 'Berhasil keluar dari kelas.' : 'Gagal keluar dari kelas.'),
                            backgroundColor: res.success ? AppColors.success : AppColors.error,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        if (res.success) {
                          ref.read(authControllerProvider.notifier).clearStudentClass();
                          await ref.read(authControllerProvider.notifier).checkSession();
                        }
                      },
                      child: const Text('Keluar Kelas', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmCounselorLeaveSchool(BuildContext context, String? schoolName) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.domain_disabled_rounded, color: AppColors.error, size: 24),
              ),
              const SizedBox(height: 14),
              const Text(
                'Keluar dari Sekolah?',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.slate900),
              ),
              const SizedBox(height: 6),
              Text(
                'Apakah Anda yakin ingin keluar dari status Guru BK di ${schoolName ?? "sekolah ini"}? Anda tidak lagi dapat mengelola laporan atau kelas di sekolah ini.',
                style: const TextStyle(fontSize: 12.5, color: AppColors.slate600, height: 1.4),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Batal', style: TextStyle(color: AppColors.slate700, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        final router = GoRouter.of(context);
                        Navigator.pop(ctx);
                        final res = await ref.read(classRepositoryProvider).counselorLeaveSchool();
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(res.success ? 'Berhasil keluar dari sekolah.' : 'Gagal keluar dari sekolah.'),
                            backgroundColor: res.success ? AppColors.success : AppColors.error,
                          ),
                        );
                        if (res.success) {
                          await ref.read(authControllerProvider.notifier).logout();
                          router.go('/welcome');
                        }
                      },
                      child: const Text('Keluar Sekolah', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.user;
    final student = authState.studentProfile;
    final counselor = authState.counselorProfile;
    final school = authState.currentSchool;

    final isCounselor = widget.isCounselor || authState.isCounselor;

    final displayName = isCounselor
        ? (counselor?.name ?? user?.name ?? 'Guru BK')
        : (student?.name ?? user?.name ?? 'Siswa');

    final schoolName = school?.name ?? 'Belum Terdaftar di Sekolah';
    final userEmail = user?.email ?? '-';
    final idNumber = isCounselor
        ? (counselor?.employeeId != null ? 'NIP: ${counselor!.employeeId}' : 'NIP: -')
        : (student?.studentId != null ? 'NIS: ${student!.studentId}' : 'NIS: -');

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: const SuaraSiswaTopBar(),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            await ref.read(authControllerProvider.notifier).checkSession();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            child: Column(
              children: [
              // ─── 1. Avatar with Verified Checkmark ─────────────────────────
              Center(
                child: Stack(
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isCounselor
                              ? const Color(0xFFFECDD3)
                              : const Color(0xFFDBEAFE),
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0F172A).withOpacity(0.08),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: user?.photoUrl != null &&
                                user!.photoUrl!.isNotEmpty
                            ? Image.network(
                                user.photoUrl!,
                                width: 90,
                                height: 90,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    _buildDefaultAvatar(
                                        isCounselor, displayName),
                              )
                            : _buildDefaultAvatar(isCounselor, displayName),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF059669),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.verified_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // ─── 2. User Name & Email ──────────────────────────────────────
              Text(
                displayName,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: AppColors.slate900,
                  letterSpacing: -0.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 3),
              Text(
                userEmail,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: AppColors.slate500,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 10),

              // ─── 3. Verified Role Pill (Overflow-Safe) ─────────────────────
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: isCounselor
                      ? const Color(0xFFFEF2F2)
                      : const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isCounselor
                        ? const Color(0xFFFECACA)
                        : const Color(0xFFBFDBFE),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isCounselor
                          ? Icons.workspace_premium_rounded
                          : Icons.school_rounded,
                      size: 13,
                      color: isCounselor
                          ? AppColors.primary
                          : const Color(0xFF2563EB),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isCounselor
                          ? 'Pendidik / Guru BK Terverifikasi'
                          : 'Siswa Terdaftar ($idNumber)',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isCounselor
                            ? AppColors.primary
                            : const Color(0xFF2563EB),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // School Pill
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border:
                      Border.all(color: const Color(0xFFE2E8F0), width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.school_outlined,
                        size: 13, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        schoolName,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.slate800,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // ─── Management Options (For Counselor) ─────────────────────
              if (isCounselor) ...[
                SectionHeader(
                  title: 'Manajemen Sekolah & BK',
                  padding: EdgeInsets.zero,
                ),
                const SizedBox(height: 10),
                ModernCard(
                  borderRadius: 20,
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      _buildMenuItem(
                        icon: Icons.qr_code_2_rounded,
                        accentColor: const Color(0xFFDC2626),
                        title: 'Kode Bergabung Sekolah',
                        subtitle:
                            'Salin kode: ${school?.schoolCode ?? "-"}',
                        onTap: () {
                          if (school?.schoolCode != null) {
                            Clipboard.setData(
                                ClipboardData(text: school!.schoolCode));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Kode sekolah disalin!'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          }
                        },
                      ),
                      Container(height: 1, color: const Color(0xFFF8FAFC)),
                      _buildMenuItem(
                        icon: Icons.meeting_room_outlined,
                        accentColor: const Color(0xFF2563EB),
                        title: 'Daftar Kelas & Siswa',
                        subtitle: 'Kelola rombel dan siswa sekolah',
                        onTap: () => context.push('/counselor/classes'),
                      ),
                      Container(height: 1, color: const Color(0xFFF8FAFC)),
                      _buildMenuItem(
                        icon: Icons.group_add_outlined,
                        accentColor: const Color(0xFF059669),
                        title: 'Undang Rekan Guru BK',
                        subtitle: 'Bagikan kode akses konselor sekolah',
                        onTap: () => context.push('/counselor/invitations'),
                      ),
                      Container(height: 1, color: const Color(0xFFF8FAFC)),
                      _buildMenuItem(
                        icon: Icons.domain_disabled_rounded,
                        accentColor: AppColors.error,
                        title: 'Keluar dari Sekolah',
                        subtitle: 'Nonaktifkan status Guru BK di ${school?.name ?? "-"}',
                        onTap: () => _confirmCounselorLeaveSchool(context, school?.name),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // ─── 5b. Class Membership (For Student) ─────────────────────────
              if (!isCounselor) ...[
                SectionHeader(
                  title: 'Keanggotaan Kelas',
                  padding: EdgeInsets.zero,
                ),
                const SizedBox(height: 10),
                ModernCard(
                  borderRadius: 20,
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        child: Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: (student?.hasClass == true)
                                    ? const Color(0xFF2563EB).withOpacity(0.08)
                                    : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.school_outlined,
                                color: (student?.hasClass == true)
                                    ? const Color(0xFF2563EB)
                                    : AppColors.slate500,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    (student?.hasClass == true && student?.className != null)
                                        ? student!.className!
                                        : 'Belum Ada Kelas',
                                    style: const TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.slate900,
                                    ),
                                  ),
                                  const SizedBox(height: 1),
                                  Text(
                                    'NIS: ${student?.studentId ?? "-"} • ${school?.name ?? "-"}',
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      color: AppColors.slate500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(height: 1, color: const Color(0xFFF8FAFC)),
                      if (student?.hasClass == true) ...[
                        _buildMenuItem(
                          icon: Icons.swap_horiz_rounded,
                          accentColor: const Color(0xFF2563EB),
                          title: 'Ganti Kelas',
                          subtitle: 'Pindah ke rombel / kelas lain di sekolah ini',
                          onTap: () => showSelectClassModal(context, ref),
                        ),
                        Container(height: 1, color: const Color(0xFFF8FAFC)),
                        _buildMenuItem(
                          icon: Icons.logout_rounded,
                          accentColor: AppColors.error,
                          title: 'Keluar dari Kelas',
                          subtitle: 'Tinggalkan rombel ${student?.className ?? ""}',
                          onTap: () => _confirmStudentLeaveClass(context, student?.className, school?.name),
                        ),
                      ] else ...[
                        _buildMenuItem(
                          icon: Icons.add_circle_outline_rounded,
                          accentColor: const Color(0xFF2563EB),
                          title: 'Pilih & Gabung Kelas',
                          subtitle: 'Pilih rombel resmi yang dibuat oleh Guru BK',
                          onTap: () => showSelectClassModal(context, ref),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // ─── 6. General Settings & Preferences ─────────────────────────
              SectionHeader(
                title: 'Pengaturan & Bantuan',
                padding: EdgeInsets.zero,
              ),
              const SizedBox(height: 10),
              ModernCard(
                borderRadius: 20,
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _buildMenuItem(
                      icon: Icons.notifications_none_rounded,
                      accentColor: const Color(0xFF2563EB),
                      title: 'Preferensi Notifikasi',
                      subtitle: 'Pemberitahuan laporan & percakapan',
                      onTap: () => context.push('/settings/notifications'),
                    ),
                    Container(height: 1, color: const Color(0xFFF8FAFC)),
                    _buildMenuItem(
                      icon: Icons.verified_user_outlined,
                      accentColor: const Color(0xFF059669),
                      title: 'Kebijakan Privasi & Kode Etik BK',
                      subtitle: 'Standar kerahasiaan & hukum perlindungan',
                      onTap: () => context.push('/settings/privacy'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ─── 7. Logout Button ──────────────────────────────────────────
              AppButton(
                text: 'Keluar dari Akun',
                variant: AppButtonVariant.outline,
                icon: const Icon(Icons.logout_rounded,
                    size: 18, color: AppColors.primary),
                height: 48,
                borderRadius: 24,
                onPressed: () => _showLogoutDialog(context),
              ),

              // Spacing to keep content cleanly above the floating bottom navigation bar
              const SizedBox(height: 96),
            ],
          ),
        ),
      ),
    ),
  );
}


  Widget _buildMenuItem({
    required IconData icon,
    required Color accentColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: accentColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.slate900,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.slate500,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 13,
              color: AppColors.slate400,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultAvatar(bool isCounselor, String name) {
    return Container(
      color: isCounselor ? AppColors.lightRed : const Color(0xFFEFF6FF),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : 'U',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: isCounselor ? AppColors.primary : const Color(0xFF2563EB),
          ),
        ),
      ),
    );
  }
}
