import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:suara_siswa/core/constants/app_colors.dart';
import 'package:suara_siswa/core/network/api_response.dart';
import 'package:suara_siswa/features/reports/data/report_repository.dart';
import 'package:suara_siswa/shared/models/report_model.dart';
import 'package:suara_siswa/shared/utils/date_formatter.dart';
import 'package:suara_siswa/shared/widgets/app_badge.dart';
import 'package:suara_siswa/shared/widgets/empty_state_view.dart';
import 'package:suara_siswa/shared/widgets/modern_card.dart';
import 'package:suara_siswa/shared/widgets/suara_siswa_app_bar.dart';

class ReportListScreen extends ConsumerStatefulWidget {
  final bool isCounselor;
  final String? initialStatus;

  const ReportListScreen({
    super.key,
    required this.isCounselor,
    this.initialStatus,
  });

  @override
  ConsumerState<ReportListScreen> createState() => _ReportListScreenState();
}

class _ReportListScreenState extends ConsumerState<ReportListScreen> {
  String _selectedFilter = 'ALL'; // ALL, IN_PROGRESS, RESOLVED, DRAFT
  late Future<ApiResponse<List<ReportModel>>> _reportsFuture;

  @override
  void initState() {
    super.initState();
    if (widget.initialStatus != null && widget.initialStatus!.isNotEmpty) {
      _selectedFilter = widget.initialStatus!;
    }
    _refreshReports();
  }

  void _refreshReports() {
    setState(() {
      _reportsFuture = ref.read(reportRepositoryProvider).getReports();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: const SuaraSiswaTopBar(),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            _refreshReports();
            await _reportsFuture;
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            child: FutureBuilder<ApiResponse<List<ReportModel>>>(
              future: _reportsFuture,
              builder: (context, snapshot) {
                final allReportsRaw = snapshot.data?.data ?? [];
                final now = DateTime.now();

                // 21 days (3 weeks) auto-cleanup for resolved/closed reports
                final allReports = allReportsRaw.where((item) {
                  if (item.status == ReportStatus.resolved ||
                      item.status == ReportStatus.closed) {
                    final finishDate = item.resolvedAt ?? item.createdAt;
                    if (now.difference(finishDate).inDays >= 21) {
                      return false;
                    }
                  }
                  return true;
                }).toList();

                final underReviewCount = allReports.where((r) =>
                    r.status == ReportStatus.submitted ||
                    r.status == ReportStatus.underReview).length;
                final inProgressCount = allReports
                    .where((r) => r.status == ReportStatus.inProgress)
                    .length;
                final resolvedCount = allReports.where((r) =>
                    r.status == ReportStatus.resolved ||
                    r.status == ReportStatus.closed).length;
                final allCount = allReports.length;

                // Apply current filter
                final reports = allReports.where((item) {
                  if (_selectedFilter == 'UNDER_REVIEW') {
                    return item.status == ReportStatus.submitted ||
                        item.status == ReportStatus.underReview;
                  }
                  if (_selectedFilter == 'IN_PROGRESS') {
                    return item.status == ReportStatus.inProgress;
                  }
                  if (_selectedFilter == 'RESOLVED') {
                    return item.status == ReportStatus.resolved ||
                        item.status == ReportStatus.closed;
                  }
                  return true;
                }).toList();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ─── Header ──────────────────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          widget.isCounselor ? 'Laporan Siswa' : 'Riwayat Laporan',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppColors.slate900,
                            letterSpacing: -0.4,
                          ),
                        ),
                        if (allReports.isNotEmpty)
                          InkWell(
                            onTap: () => _showDeleteAllConfirmation(context),
                            borderRadius: BorderRadius.circular(8),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.delete_outline_rounded,
                                      size: 15, color: Color(0xFFEF4444)),
                                  SizedBox(width: 4),
                                  Text(
                                    'Hapus Semua',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFFEF4444),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.isCounselor
                          ? 'Daftar pengaduan & aspirasi yang masuk dari siswa sekolah.'
                          : 'Pantau proses penanganan pengaduan yang telah kamu kirimkan.',
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.slate500,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ─── Filter Pills ────────────────────────────────────
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterPill('ALL', 'Semua ($allCount)'),
                          const SizedBox(width: 8),
                          _buildFilterPill('UNDER_REVIEW', 'Ditinjau ($underReviewCount)'),
                          const SizedBox(width: 8),
                          _buildFilterPill('IN_PROGRESS', 'Diproses ($inProgressCount)'),
                          const SizedBox(width: 8),
                          _buildFilterPill('RESOLVED', 'Selesai ($resolvedCount)'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ─── Reports List from Cloudflare D1 ─────────────────
                    if (snapshot.connectionState == ConnectionState.waiting)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Center(
                          child: CircularProgressIndicator(
                              color: AppColors.primary, strokeWidth: 2.5),
                        ),
                      )
                    else if (snapshot.hasError)
                      EmptyStateView(
                        icon: Icons.error_outline_rounded,
                        title: 'Gagal Memuat Laporan',
                        description: snapshot.error.toString(),
                        buttonText: 'Coba Lagi',
                        onButtonPressed: _refreshReports,
                      )
                    else if (reports.isEmpty)
                      EmptyStateView(
                        icon: widget.isCounselor
                            ? Icons.inbox_outlined
                            : Icons.assignment_outlined,
                        title: widget.isCounselor
                            ? 'Belum Ada Laporan Masuk'
                            : 'Belum Ada Laporan',
                        description: widget.isCounselor
                            ? 'Semua laporan dan aspirasi yang dikirimkan oleh siswa akan muncul di sini.'
                            : 'Kamu belum pernah membuat laporan. Bersuaralah dengan aman bersama Guru BK sekolah.',
                        buttonText: widget.isCounselor ? null : 'Buat Laporan Baru',
                        onButtonPressed: widget.isCounselor
                            ? null
                            : () => context.push('/student/create-report'),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: reports.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final item = reports[index];
                          final isBullying = item.type == ReportType.bullying ||
                              item.category.toLowerCase().contains('bully');

                          return _buildModernReportCard(
                            item: item,
                            isBullying: isBullying,
                          );
                        },
                      ),
                    const SizedBox(height: 18),

                    // ─── Security Notice Banner ──────────────────────────
                    ModernCard(
                      variant: ModernCardVariant.flat,
                      borderRadius: 16,
                      padding:
                          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.lock_outline_rounded,
                              size: 15, color: Color(0xFF059669)),
                          SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'Laporan hanya dapat diakses olehmu dan Guru BK.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 11.5,
                                color: AppColors.slate600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Spacing to keep content cleanly above the floating bottom navigation bar
                    const SizedBox(height: 96),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterPill(String key, String label) {
    final isSelected = _selectedFilter == key;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = key;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.slate900 : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isSelected ? AppColors.slate900 : const Color(0xFFE2E8F0),
            width: 1.2,
          ),
          boxShadow: isSelected ? AppColors.elevation2 : AppColors.elevation1,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.slate700,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 12.5,
          ),
        ),
      ),
    );
  }

  Widget _buildModernReportCard({
    required ReportModel item,
    required bool isBullying,
  }) {
    final routePrefix = widget.isCounselor ? '/counselor' : '/student';
    final accentColor = isBullying
        ? const Color(0xFFDC2626)
        : item.type == ReportType.konseling
            ? const Color(0xFF059669)
            : const Color(0xFF2563EB);

    return ModernCard(
      borderRadius: 18,
      padding: const EdgeInsets.all(14),
      onTap: () => context.push('$routePrefix/reports/${item.id}'),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail or Category squircle icon
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
                    const SizedBox(width: 4),
                    InkWell(
                      onTap: () => _confirmDeleteReport(item),
                      borderRadius: BorderRadius.circular(12),
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(Icons.close_rounded,
                            size: 16, color: AppColors.slate400),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  item.description.isNotEmpty
                      ? item.description
                      : 'Laporan Pengaduan',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13.5,
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
                        widget.isCounselor
                            ? '${item.studentName ?? "Siswa"} (${item.className ?? "-"})'
                            : 'Guru BK Sekolah',
                        style: const TextStyle(
                          fontSize: 10.5,
                          color: AppColors.slate500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded, size: 11, color: AppColors.slate400),
                    const SizedBox(width: 4),
                    Text(
                      AppDateFormatter.formatDateTimeWibSingleLine(item.createdAt),
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: AppColors.slate500,
                        fontWeight: FontWeight.w500,
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
  }

  Future<void> _confirmDeleteReport(ReportModel item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Hapus Riwayat Laporan?',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Laporan #${item.reportCode} akan dihapus dari riwayat Anda.',
          style: const TextStyle(fontSize: 13, color: AppColors.slate600),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal', style: TextStyle(color: AppColors.slate600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await ref.read(reportRepositoryProvider).deleteReport(item.id);
        _refreshReports();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Riwayat laporan berhasil dihapus'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal menghapus laporan: $e')),
          );
        }
      }
    }
  }

  Future<void> _showDeleteAllConfirmation(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Hapus Semua Riwayat?',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Semua riwayat laporan Anda akan dibersihkan. Tindakan ini tidak dapat dibatalkan.',
          style: TextStyle(fontSize: 13, color: AppColors.slate600),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal', style: TextStyle(color: AppColors.slate600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Hapus Semua'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final messenger = ScaffoldMessenger.of(context);
      try {
        await ref.read(reportRepositoryProvider).deleteAllReports();
        _refreshReports();
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Semua riwayat berhasil dihapus'),
            duration: Duration(seconds: 2),
          ),
        );
      } catch (e) {
        messenger.showSnackBar(
          SnackBar(content: Text('Gagal menghapus semua: $e')),
        );
      }
    }
  }
}

