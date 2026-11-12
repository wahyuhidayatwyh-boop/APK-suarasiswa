import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:suara_siswa/core/constants/app_colors.dart';
import 'package:suara_siswa/core/network/api_response.dart';
import 'package:suara_siswa/features/auth/presentation/auth_controller.dart';
import 'package:suara_siswa/features/education/data/content_repository.dart';
import 'package:suara_siswa/features/reports/data/report_repository.dart';
import 'package:suara_siswa/shared/models/content_model.dart';
import 'package:suara_siswa/shared/models/report_model.dart';
import 'package:suara_siswa/shared/utils/date_formatter.dart';
import 'package:suara_siswa/shared/widgets/app_badge.dart';
import 'package:suara_siswa/shared/widgets/modern_card.dart';
import 'package:suara_siswa/shared/widgets/section_header.dart';
import 'package:suara_siswa/shared/widgets/stat_card.dart';
import 'package:suara_siswa/shared/widgets/suara_siswa_app_bar.dart';
import 'package:suara_siswa/features/classes/presentation/widgets/select_class_modal.dart';

class StudentHomeScreen extends ConsumerStatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  ConsumerState<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends ConsumerState<StudentHomeScreen> {
  late Future<ApiResponse<List<ReportModel>>> _reportsFuture;
  late Future<ApiResponse<List<ContentModel>>> _educationFuture;

  int _educationIndex = 0;
  late final PageController _educationPageController = PageController(viewportFraction: 0.92);
  bool _isIdVisible = false;

  @override
  void initState() {
    super.initState();
    _loadIdVisibility();
    _refreshAll();
  }

  Future<void> _loadIdVisibility() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final val = prefs.getBool('show_student_id');
      if (val != null && mounted) {
        setState(() => _isIdVisible = val);
      }
    } catch (_) {}
  }

  Future<void> _toggleIdVisibility() async {
    setState(() => _isIdVisible = !_isIdVisible);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('show_student_id', _isIdVisible);
    } catch (_) {}
  }

  @override
  void dispose() {
    _educationPageController.dispose();
    super.dispose();
  }

  void _refreshAll() {
    _reportsFuture = ref.read(reportRepositoryProvider).getReports();
    _educationFuture = ref.read(contentRepositoryProvider).getContents(
          status: ContentStatus.published,
        );
  }

  Widget _defaultHeroImage() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.shield_rounded,
          size: 64,
          color: Colors.white.withOpacity(0.15),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.user;
    final student = authState.studentProfile;
    final school = authState.currentSchool;

    final rawName = student?.name ?? user?.name ?? 'Siswa';
    final studentName = rawName.trim().isNotEmpty ? rawName.trim() : 'Siswa';
    final firstName = studentName.split(' ').first;
    final hasSchool = school != null;
    final schoolName = school?.name ?? 'Belum Terdaftar di Sekolah';
    final hasClass = student?.hasClass ?? false;
    final className = hasClass ? (student?.className ?? 'Kelas') : null;
    final nisn = student?.studentId ?? (user?.id.isNotEmpty == true && user!.id.length >= 8 ? user.id.substring(0, 8).toUpperCase() : '2026-0001');

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: const SuaraSiswaTopBar(),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            await ref.read(authControllerProvider.notifier).checkSession();
            setState(() {
              _refreshAll();
            });
            await _reportsFuture;
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── 1. Greeting & Safe Badge ─────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Halo, $firstName 👋',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: AppColors.slate900,
                              letterSpacing: -0.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          InkWell(
                            onTap: !hasSchool
                                ? () => context.push('/student/join-school')
                                : null,
                            child: Row(
                              children: [
                                Icon(
                                  hasSchool
                                      ? Icons.school_outlined
                                      : Icons.add_business_rounded,
                                  size: 13,
                                  color: hasSchool
                                      ? AppColors.slate500
                                      : AppColors.primary,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    hasSchool
                                        ? (hasClass ? '$schoolName • $className' : '$schoolName • Belum Ada Kelas')
                                        : schoolName,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: hasSchool
                                          ? FontWeight.w500
                                          : FontWeight.w700,
                                      color: hasSchool
                                          ? AppColors.slate600
                                          : AppColors.primary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFA7F3D0), width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF10B981).withOpacity(0.12),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified_user_rounded,
                              size: 12, color: Color(0xFF059669)),
                          SizedBox(width: 4),
                          Text(
                            'Aman & Rahasia',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF059669),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ─── 2. Kartu Perlindungan Siswa ──────────────────────────────
                _buildCrimsonStudentCard(
                  studentName: studentName,
                  schoolName: schoolName,
                  className: className,
                  hasClass: hasClass,
                  nisn: nisn,
                  isIdVisible: _isIdVisible,
                  onToggleIdVisibility: _toggleIdVisibility,
                  onSelectClass: () => showSelectClassModal(context, ref),
                ),
                const SizedBox(height: 20),

                // ─── 4. Quick Action Grid (Tactile 3D Buttons) ────────────────
                Row(
                  children: [
                    Expanded(
                      child: _buildActionTile(
                        icon: Icons.shield_rounded,
                        accentColor: const Color(0xFFDC2626),
                        title: 'Laporkan Bullying',
                        subtitle: 'Pendampingan aman',
                        badge: 'Prioritas',
                        onTap: () =>
                            context.push('/student/create-report?type=BULLYING'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildActionTile(
                        icon: Icons.lightbulb_rounded,
                        accentColor: const Color(0xFF2563EB),
                        title: 'Aspirasi Siswa',
                        subtitle: 'Ide kemajuan sekolah',
                        badge: 'Suara Siswa',
                        onTap: () =>
                            context.push('/student/create-report?type=ASPIRASI'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildActionTile(
                        icon: Icons.chat_bubble_outline_rounded,
                        accentColor: const Color(0xFF7C3AED),
                        title: 'Kritik & Sarana',
                        subtitle: 'Perbaikan fasilitas',
                        onTap: () => context
                            .push('/student/create-report?type=KRITIK_SARAN'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildActionTile(
                        icon: Icons.volunteer_activism_rounded,
                        accentColor: const Color(0xFF059669),
                        title: 'Konseling Privat',
                        subtitle: 'Curhat ke Guru BK',
                        badge: 'Privat',
                        onTap: () =>
                            context.push('/student/create-report?type=KONSELING'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),

                // ─── 5. Status Statistics (Interactive 3D Cards) ──────────────
                SectionHeader(
                  title: 'Status Pengaduan',
                  subtitle: 'Pantau laporan yang sedang ditindaklanjuti',
                  actionText: 'Lihat Semua',
                  onAction: () => context.push('/student/reports?status=ALL'),
                  padding: EdgeInsets.zero,
                ),
                const SizedBox(height: 12),
                FutureBuilder<ApiResponse<List<ReportModel>>>(
                  future: _reportsFuture,
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
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 1.22,
                      children: [
                        StatCard(
                          title: 'Semua',
                          value: '$total',
                          icon: Icons.assignment_outlined,
                          iconColor: AppColors.slate900,
                          onTap: () =>
                              context.push('/student/reports?status=ALL'),
                        ),
                        StatCard(
                          title: 'Ditinjau',
                          value: '$underReview',
                          icon: Icons.visibility_rounded,
                          iconColor: const Color(0xFFD97706),
                          onTap: () => context
                              .push('/student/reports?status=UNDER_REVIEW'),
                        ),
                        StatCard(
                          title: 'Diproses',
                          value: '$inProgress',
                          icon: Icons.sync_rounded,
                          iconColor: const Color(0xFF7C3AED),
                          onTap: () => context
                              .push('/student/reports?status=IN_PROGRESS'),
                        ),
                        StatCard(
                          title: 'Selesai',
                          value: '$resolved',
                          icon: Icons.check_circle_rounded,
                          iconColor: const Color(0xFF059669),
                          onTap: () => context
                              .push('/student/reports?status=RESOLVED'),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),

                // ─── 6. Ruang Edukasi & Bimbingan BK ──────────────────────────
                SectionHeader(
                  title: 'Materi Edukasi & Bimbingan BK',
                  subtitle: 'Panduan pencegahan bullying dan kesehatan mental',
                  padding: EdgeInsets.zero,
                ),
                const SizedBox(height: 12),
                FutureBuilder<ApiResponse<List<ContentModel>>>(
                  future: _educationFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Container(
                        height: 190,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: const Center(
                          child: CircularProgressIndicator(
                              color: AppColors.primary, strokeWidth: 2.5),
                        ),
                      );
                    }

                    final contents = snapshot.data?.data ?? [];
                    if (contents.isEmpty) {
                      return ModernCard(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 20),
                        borderRadius: 20,
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(Icons.menu_book_rounded,
                                  color: Color(0xFF2563EB), size: 28),
                            ),
                            const SizedBox(width: 14),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Belum Ada Materi Edukasi',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      color: AppColors.slate900,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Guru BK akan segera membagikan panduan dan artikel bimbingan konseling.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.slate500,
                                      height: 1.35,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return Column(
                      children: [
                        SizedBox(
                          height: 195,
                          child: PageView.builder(
                            controller: _educationPageController,
                            itemCount: contents.length,
                            onPageChanged: (idx) {
                              setState(() {
                                _educationIndex = idx;
                              });
                            },
                            itemBuilder: (context, index) {
                              final item = contents[index];
                              return Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: GestureDetector(
                                  onTap: () =>
                                      context.push('/education/${item.id}'),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(22),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF0F172A)
                                              .withOpacity(0.12),
                                          blurRadius: 18,
                                          offset: const Offset(0, 6),
                                        ),
                                      ],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(22),
                                      child: Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          // Background Image or Gradient
                                          if (item.imageUrl != null &&
                                              item.imageUrl!.isNotEmpty)
                                            Image.network(
                                              item.imageUrl!,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error,
                                                      stackTrace) =>
                                                  _defaultHeroImage(),
                                            )
                                          else
                                            _defaultHeroImage(),

                                          // Rich Dark Gradient Overlay for optimal readability
                                          Container(
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.topCenter,
                                                end: Alignment.bottomCenter,
                                                colors: [
                                                  Colors.black.withOpacity(0.15),
                                                  Colors.black.withOpacity(0.40),
                                                  Colors.black.withOpacity(0.88),
                                                ],
                                                stops: const [0.0, 0.45, 1.0],
                                              ),
                                            ),
                                          ),

                                          // Content
                                          Padding(
                                            padding: const EdgeInsets.all(16),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                const SizedBox(height: 8),

                                                // Bottom Text Info
                                                Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      item.title,
                                                      maxLines: 2,
                                                      overflow: TextOverflow
                                                          .ellipsis,
                                                      style: const TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.w800,
                                                        color: Colors.white,
                                                        letterSpacing: -0.3,
                                                        height: 1.25,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      item.shortDescription,
                                                      maxLines: 1,
                                                      overflow: TextOverflow
                                                          .ellipsis,
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.white
                                                            .withOpacity(0.85),
                                                        height: 1.2,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 8),
                                                    Row(
                                                      children: [
                                                        const Text(
                                                          'Baca Panduan',
                                                          style: TextStyle(
                                                            fontSize: 11,
                                                            fontWeight:
                                                                FontWeight.w700,
                                                            color: Color(
                                                                0xFFFDA4AF),
                                                          ),
                                                        ),
                                                        const SizedBox(width: 4),
                                                        const Icon(
                                                          Icons
                                                              .arrow_forward_rounded,
                                                          size: 12,
                                                          color: Color(
                                                                0xFFFDA4AF),
                                                        ),
                                                        const Spacer(),
                                                        Text(
                                                          AppDateFormatter
                                                              .formatShort(item
                                                                  .createdAt),
                                                          style: TextStyle(
                                                            fontSize: 10,
                                                            color: Colors.white
                                                                .withOpacity(
                                                                    0.65),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        if (contents.length > 1) ...[
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(contents.length, (dotIdx) {
                              final isActive = dotIdx == _educationIndex;
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeOutCubic,
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 3),
                                width: isActive ? 22 : 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? AppColors.primary
                                      : const Color(0xFFCBD5E1),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              );
                            }),
                          ),
                        ],
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),

                // ─── 7. Laporan Masuk Terbaru (Modern 3D List) ───────────────
                SectionHeader(
                  title: 'Laporan Terbaru Kamu',
                  subtitle: 'Riwayat pengaduan dan status terkini',
                  actionText: 'Riwayat Lengkap',
                  onAction: () => context.push('/student/reports'),
                  padding: EdgeInsets.zero,
                ),
                const SizedBox(height: 12),
                FutureBuilder<ApiResponse<List<ReportModel>>>(
                  future: _reportsFuture,
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
                                decoration: BoxDecoration(
                                  color: AppColors.lightRed,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.inbox_outlined,
                                    color: AppColors.primary, size: 24),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Belum Ada Laporan Dikirim',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.slate800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Setiap suara dan aduanmu dilindungi privasinya.',
                                style: TextStyle(
                                    fontSize: 12, color: AppColors.slate500),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    final recentReports = reports.take(3).toList();
                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: recentReports.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final item = recentReports[index];
                        final isBullying = item.type == ReportType.bullying ||
                            item.category.toLowerCase().contains('bully');

                        return ModernCard(
                          borderRadius: 18,
                          onTap: () =>
                              context.push('/student/reports/${item.id}'),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                alignment: WrapAlignment.spaceBetween,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '# ${item.reportCode}',
                                        style: const TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.primary,
                                          letterSpacing: 0.2,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      AppBadge.priority(item.priority),
                                    ],
                                  ),
                                  AppBadge.status(item.status),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                item.category.isNotEmpty
                                    ? item.category
                                    : item.type.label,
                                style: const TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.slate900,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(
                                    isBullying
                                        ? Icons.shield_outlined
                                        : Icons.support_agent_rounded,
                                    size: 13,
                                    color: AppColors.slate400,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Guru BK Sekolah',
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      color: AppColors.slate500,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    AppDateFormatter.formatShort(item.createdAt),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.slate400,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    size: 11,
                                    color: AppColors.slate400,
                                  ),
                                ],
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

  // ─── 3D Crimson Student Identity Card (Inspired by Reference Mockup) ─────────
  Widget _buildCrimsonStudentCard({
    required String studentName,
    required String schoolName,
    required String? className,
    required bool hasClass,
    required String nisn,
    required bool isIdVisible,
    required VoidCallback onToggleIdVisibility,
    required VoidCallback onSelectClass,
  }) {
    return ModernCard(
      variant: ModernCardVariant.crimson,
      borderRadius: 22,
      padding: const EdgeInsets.all(20),
      child: Stack(
        children: [
          // Geometric aesthetic circle overlay
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

          // Card Content
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
                            'KARTU PERLINDUNGAN SISWA',
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
                        Icon(Icons.lock_rounded, size: 11, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          'AKTIF',
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
              const SizedBox(height: 22),

              // Student Masked / Unmasked Code with Eye Toggle Button
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isIdVisible
                        ? 'ID $nisn'
                        : 'ID •••• •••• ${nisn.length >= 4 ? nisn.substring(nisn.length - 4) : nisn}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2.2,
                    ),
                  ),
                  const SizedBox(width: 10),
                  InkWell(
                    onTap: onToggleIdVisibility,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isIdVisible
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Name & School
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
                          'NAMA SISWA',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          studentName,
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
                          'KELAS',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 3),
                        if (hasClass && className != null && className.isNotEmpty)
                          InkWell(
                            onTap: onSelectClass,
                            borderRadius: BorderRadius.circular(6),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    className,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.edit_outlined, size: 12, color: Colors.white70),
                              ],
                            ),
                          )
                        else
                          InkWell(
                            onTap: onSelectClass,
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.25),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.white.withOpacity(0.4), width: 1),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.add_circle_outline_rounded, size: 12, color: Colors.white),
                                  SizedBox(width: 4),
                                  Text(
                                    'Gabung Kelas',
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
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Tactile Quick Action Tile ──────────────────────────────────────────────
  Widget _buildActionTile({
    required IconData icon,
    required Color accentColor,
    required String title,
    required String subtitle,
    String? badge,
    required VoidCallback onTap,
  }) {
    return ModernCard(
      borderRadius: 20,
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 40,
                height: 40,
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
                child: Icon(icon, color: accentColor, size: 20),
              ),
              if (badge != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    badge,
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      color: accentColor,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              color: AppColors.slate900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.slate500,
            ),
          ),
        ],
      ),
    );
  }
}
