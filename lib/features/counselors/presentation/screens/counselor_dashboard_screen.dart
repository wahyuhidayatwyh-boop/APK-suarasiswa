import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:suara_siswa/core/constants/app_colors.dart';
import 'package:suara_siswa/core/network/api_response.dart';
import 'package:suara_siswa/features/auth/presentation/auth_controller.dart';
import 'package:suara_siswa/features/notifications/data/notification_repository.dart';
import 'package:suara_siswa/features/reports/data/report_repository.dart';
import 'package:suara_siswa/shared/models/report_model.dart';
import 'package:suara_siswa/shared/utils/date_formatter.dart';
import 'package:suara_siswa/shared/widgets/app_badge.dart';
import 'package:suara_siswa/shared/widgets/modern_card.dart';
import 'package:suara_siswa/shared/widgets/section_header.dart';
import 'package:suara_siswa/shared/widgets/stat_card.dart';

class CounselorDashboardScreen extends ConsumerStatefulWidget {
  const CounselorDashboardScreen({super.key});

  @override
  ConsumerState<CounselorDashboardScreen> createState() =>
      _CounselorDashboardScreenState();
}

class _CounselorDashboardScreenState
    extends ConsumerState<CounselorDashboardScreen> {
  bool _isCodeVisible = false;

  @override
  void initState() {
    super.initState();
    _loadCodeVisibility();
  }

  Future<void> _loadCodeVisibility() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final val = prefs.getBool('show_counselor_code');
      if (val != null && mounted) {
        setState(() => _isCodeVisible = val);
      }
    } catch (_) {}
  }

  Future<void> _toggleCodeVisibility() async {
    setState(() => _isCodeVisible = !_isCodeVisible);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('show_counselor_code', _isCodeVisible);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final school = authState.currentSchool;
    final counselor = authState.counselorProfile;

    final counselorName = counselor?.name ?? authState.user?.name ?? 'Guru BK';
    final schoolName = school?.name ?? 'Sekolah';
    final schoolCode = school?.schoolCode ?? '-';

    final reportRepo = ref.watch(reportRepositoryProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            ref.invalidate(reportRepositoryProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── 1. Top Header ───────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            schoolName,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.slate900,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            counselorName,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.slate500,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Consumer(
                      builder: (context, ref, _) {
                        final unreadCount =
                            ref.watch(unreadNotificationsCountProvider);
                        return Stack(
                          alignment: Alignment.center,
                          children: [
                            InkWell(
                              onTap: () => context.push('/notifications'),
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: const Color(0xFFE2E8F0),
                                      width: 1.2),
                                  boxShadow: AppColors.elevation1,
                                ),
                                child: const Icon(
                                  Icons.notifications_none_rounded,
                                  size: 20,
                                  color: AppColors.slate700,
                                ),
                              ),
                            ),
                            if (unreadCount > 0)
                              Positioned(
                                top: 2,
                                right: 2,
                                child: Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: const BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 16,
                                    minHeight: 16,
                                  ),
                                  child: Text(
                                    unreadCount > 9 ? '9+' : '$unreadCount',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      height: 1,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ─── 2. Kartu Konselor & Sekolah ──────────────────────────────
                _buildCrimsonCounselorCard(
                  counselorName: counselorName,
                  schoolName: schoolName,
                  schoolCode: schoolCode,
                  isCodeVisible: _isCodeVisible,
                  onToggleCodeVisibility: _toggleCodeVisibility,
                ),
                const SizedBox(height: 20),

                // ─── 4. Quick Actions Management ─────────────────────────────
                SectionHeader(
                  title: 'Kelola Sekolah & Siswa',
                  padding: EdgeInsets.zero,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildActionTile(
                        icon: Icons.meeting_room_outlined,
                        accentColor: const Color(0xFF2563EB),
                        title: 'Kelas & Siswa',
                        onTap: () => context.push('/counselor/classes'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildActionTile(
                        icon: Icons.person_add_alt_1_outlined,
                        accentColor: const Color(0xFF059669),
                        title: 'Undang Guru BK',
                        onTap: () => context.push('/counselor/invitations'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildActionTile(
                        icon: Icons.article_outlined,
                        accentColor: const Color(0xFF7C3AED),
                        title: 'Konten Edukasi',
                        onTap: () => context.push('/counselor/content'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),

                // ─── 5. Metric Stat Cards Grid ───────────────────────────────
                SectionHeader(
                  title: 'Statistik Laporan Masuk',
                  subtitle: 'Ketuk kartu untuk melihat daftar laporan',
                  actionText: 'Lihat Semua',
                  onAction: () => context.push('/counselor/reports?status=ALL'),
                  padding: EdgeInsets.zero,
                ),
                const SizedBox(height: 12),
                FutureBuilder<ApiResponse<List<ReportModel>>>(
                  future: reportRepo.getReports(),
                  builder: (context, snapshot) {
                    final reports = snapshot.data?.data ?? [];
                    final total = reports.length;
                    final underReview = reports
                        .where((r) =>
                            r.status == ReportStatus.submitted ||
                            r.status == ReportStatus.underReview)
                        .length;
                    final inProgress = reports
                        .where((r) => r.status == ReportStatus.inProgress)
                        .length;
                    final resolved = reports
                        .where((r) =>
                            r.status == ReportStatus.resolved ||
                            r.status == ReportStatus.closed)
                        .length;

                    return GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.22,
                      children: [
                        StatCard(
                          title: 'Semua',
                          value: '$total',
                          icon: Icons.assignment_outlined,
                          iconColor: AppColors.slate900,
                          onTap: () =>
                              context.push('/counselor/reports?status=ALL'),
                        ),
                        StatCard(
                          title: 'Ditinjau',
                          value: '$underReview',
                          icon: Icons.visibility_rounded,
                          iconColor: const Color(0xFFD97706),
                          onTap: () => context
                              .push('/counselor/reports?status=UNDER_REVIEW'),
                        ),
                        StatCard(
                          title: 'Diproses',
                          value: '$inProgress',
                          icon: Icons.sync_rounded,
                          iconColor: const Color(0xFF7C3AED),
                          onTap: () => context
                              .push('/counselor/reports?status=IN_PROGRESS'),
                        ),
                        StatCard(
                          title: 'Selesai',
                          value: '$resolved',
                          icon: Icons.check_circle_rounded,
                          iconColor: const Color(0xFF059669),
                          onTap: () => context
                              .push('/counselor/reports?status=RESOLVED'),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),

                // ─── 6. Laporan Masuk Terbaru ────────────────────────────────
                SectionHeader(
                  title: 'Laporan Masuk Terbaru',
                  subtitle: 'Pengaduan siswa yang membutuhkan perhatian',
                  actionText: 'Lihat Semua',
                  onAction: () => context.push('/counselor/reports?status=ALL'),
                  padding: EdgeInsets.zero,
                ),
                const SizedBox(height: 12),
                FutureBuilder<ApiResponse<List<ReportModel>>>(
                  future: reportRepo.getReports(),
                  builder: (context, snapshot) {
                    final reports = snapshot.data?.data ?? [];
                    if (reports.isEmpty) {
                      return ModernCard(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 24),
                        child: Center(
                          child: Column(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: const BoxDecoration(
                                  color: AppColors.lightRed,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.inbox_outlined,
                                    color: AppColors.primary, size: 24),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Belum Ada Laporan Masuk',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.slate800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Laporan pengaduan siswa akan muncul di sini secara real-time.',
                                style: TextStyle(
                                    fontSize: 12, color: AppColors.slate500),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    final recentReports = reports.take(4).toList();
                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: recentReports.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final item = recentReports[index];
                        final isBullying = item.type == ReportType.bullying ||
                            item.category.toLowerCase().contains('bully');
                        final accentColor = isBullying
                            ? const Color(0xFFDC2626)
                            : item.type == ReportType.konseling
                                ? const Color(0xFF059669)
                                : const Color(0xFF2563EB);

                        return ModernCard(
                          borderRadius: 18,
                          padding: const EdgeInsets.all(14),
                          onTap: () =>
                              context.push('/counselor/reports/${item.id}'),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Thumbnail or category icon
                              if (item.attachmentUrls.isNotEmpty)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    item.attachmentUrls.first,
                                    width: 52,
                                    height: 52,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      width: 52,
                                      height: 52,
                                      decoration: BoxDecoration(
                                        color: accentColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(Icons.assignment_outlined,
                                          color: accentColor, size: 22),
                                    ),
                                  ),
                                )
                              else
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: accentColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    isBullying
                                        ? Icons.shield_rounded
                                        : item.type == ReportType.konseling
                                            ? Icons.volunteer_activism_rounded
                                            : Icons.assignment_outlined,
                                    color: accentColor,
                                    size: 22,
                                  ),
                                ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            item.category.isNotEmpty
                                                ? item.category
                                                : item.type.label,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: accentColor,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        AppBadge.status(item.status),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      item.description,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.slate900,
                                        height: 1.3,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Text(
                                          '#${item.reportCode}',
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.slate400,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        const Text('•', style: TextStyle(color: AppColors.slate300, fontSize: 10)),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            '${item.studentName ?? "Siswa"} (${item.className ?? "-"})',
                                            style: const TextStyle(
                                              fontSize: 10.5,
                                              color: AppColors.slate500,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Text(
                                          AppDateFormatter.formatShort(item.createdAt),
                                          style: const TextStyle(
                                            fontSize: 10,
                                            color: AppColors.slate400,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
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

  // ─── 3D Crimson Counselor & School Card ─────────────────────────────────────
  Widget _buildCrimsonCounselorCard({
    required String counselorName,
    required String schoolName,
    required String schoolCode,
    required bool isCodeVisible,
    required VoidCallback onToggleCodeVisibility,
  }) {
    return ModernCard(
      variant: ModernCardVariant.crimson,
      borderRadius: 22,
      padding: const EdgeInsets.all(20),
      child: Stack(
        children: [
          Positioned(
            right: -30,
            bottom: -30,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.06),
              ),
            ),
          ),
          Positioned(
            right: 40,
            top: -40,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.04),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.3), width: 1),
                          ),
                          child: const Icon(
                            Icons.nfc_rounded,
                            size: 18,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Flexible(
                          child: Text(
                            'KARTU AKSES GURU BK',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified_rounded,
                            size: 11, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          'TERVERIFIKASI',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // School Join Code (Highlighted like Card Number)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'KODE BERGABUNG SEKOLAH',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            isCodeVisible
                                ? schoolCode
                                : '•••• •••• ${schoolCode.length >= 3 ? schoolCode.substring(schoolCode.length - 3) : schoolCode}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: onToggleCodeVisibility,
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isCodeVisible
                                    ? Icons.visibility_off_rounded
                                    : Icons.visibility_rounded,
                                size: 15,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: schoolCode));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Kode sekolah berhasil disalin!'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.3), width: 1),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.copy_rounded,
                              size: 13, color: Colors.white),
                          SizedBox(width: 4),
                          Text(
                            'Salin',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Counselor & School
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'NAMA KONSELOR',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          counselorName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'SEKOLAH',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          schoolName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required Color accentColor,
    required String title,
    required VoidCallback onTap,
  }) {
    return ModernCard(
      borderRadius: 18,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withOpacity(0.18),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(icon, color: accentColor, size: 22),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: AppColors.slate900,
            ),
          ),
        ],
      ),
    );
  }
}
