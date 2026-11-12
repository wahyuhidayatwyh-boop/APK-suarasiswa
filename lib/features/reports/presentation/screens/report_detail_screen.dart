import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:suara_siswa/core/constants/app_colors.dart';
import 'package:suara_siswa/core/constants/api_endpoints.dart';
import 'package:suara_siswa/features/auth/presentation/auth_controller.dart';
import 'package:suara_siswa/features/reports/data/report_repository.dart';
import 'package:suara_siswa/shared/models/report_model.dart';
import 'package:suara_siswa/shared/utils/date_formatter.dart';
import 'package:suara_siswa/shared/widgets/app_badge.dart';
import 'package:suara_siswa/shared/widgets/app_button.dart';
import 'package:suara_siswa/shared/widgets/app_text_field.dart';
import 'package:suara_siswa/shared/widgets/milestone_stepper.dart';
import 'package:suara_siswa/shared/widgets/modern_card.dart';

class ReportDetailScreen extends ConsumerStatefulWidget {
  final String reportId;

  const ReportDetailScreen({super.key, required this.reportId});

  @override
  ConsumerState<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends ConsumerState<ReportDetailScreen> {
  final TextEditingController _internalNotesController =
      TextEditingController();
  bool _isSavingNotes = false;

  void _showUpdateStatusSheet(BuildContext context, ReportModel report) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.75,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.slate300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Perbarui Status Laporan',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.slate900,
                    ),
                  ),
                  const SizedBox(height: 14),
                  ...ReportStatus.values.map((status) {
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: AppBadge.status(status),
                      title: Text(
                        status.label,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.slate800,
                        ),
                      ),
                      trailing: report.status == status
                          ? const Icon(Icons.check_circle_rounded,
                              color: AppColors.primary)
                          : null,
                      onTap: () async {
                        Navigator.pop(ctx);
                        await ref
                            .read(reportRepositoryProvider)
                            .updateReportStatus(
                              reportId: report.id,
                              status: status,
                            );
                        setState(() {});
                      },
                    );
                  }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showUpdatePrioritySheet(BuildContext context, ReportModel report) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.75,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.slate300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Ubah Tingkat Urgensi',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.slate900,
                    ),
                  ),
                  const SizedBox(height: 14),
                  ...ReportPriority.values.map((p) {
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: AppBadge.priority(p),
                      title: Text(
                        p.label,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.slate800,
                        ),
                      ),
                      trailing: report.priority == p
                          ? const Icon(Icons.check_circle_rounded,
                              color: AppColors.primary)
                          : null,
                      onTap: () async {
                        Navigator.pop(ctx);
                        await ref
                            .read(reportRepositoryProvider)
                            .updateReportPriority(
                              reportId: report.id,
                              priority: p,
                            );
                        setState(() {});
                      },
                    );
                  }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  int _calculateMilestoneStep(ReportStatus status) {
    switch (status) {
      case ReportStatus.submitted:
        return 0;
      case ReportStatus.underReview:
        return 1;
      case ReportStatus.inProgress:
      case ReportStatus.waitingForInfo:
      case ReportStatus.transferred:
        return 2;
      case ReportStatus.resolved:
      case ReportStatus.closed:
        return 3;
    }
  }

  @override
  void dispose() {
    _internalNotesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isCounselor = authState.isCounselor;
    final reportRepo = ref.watch(reportRepositoryProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Detail Laporan',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: AppColors.slate900,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.slate700),
            onPressed: () => setState(() {}),
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
        ),
      ),
      body: FutureBuilder(
        future: reportRepo.getReportDetail(widget.reportId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                  color: AppColors.primary, strokeWidth: 2.5),
            );
          }

          final report = snapshot.data?.data;
          if (report == null) {
            return const Center(
              child: Text(
                'Laporan tidak ditemukan.',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.slate500,
                ),
              ),
            );
          }

          if (_internalNotesController.text.isEmpty &&
              report.internalCounselorNotes != null) {
            _internalNotesController.text = report.internalCounselorNotes!;
          }

          final currentStep = _calculateMilestoneStep(report.status);

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ─── 1. Header Card (Code, Urgency, Status, Quick Actions) ──
                  ModernCard(
                    borderRadius: 16,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                report.reportCode,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            AppBadge.status(report.status),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Text(
                              'Tingkat Urgensi: ',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.slate500,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            AppBadge.priority(report.priority),
                          ],
                        ),
                        if (isCounselor) ...[
                          const SizedBox(height: 10),
                          Container(
                              height: 1, color: const Color(0xFFF1F5F9)),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              SizedBox(
                                width: (MediaQuery.of(context).size.width - 68) / 2 > 120
                                    ? (MediaQuery.of(context).size.width - 68) / 2
                                    : double.infinity,
                                child: AppButton(
                                  text: 'Perbarui Status',
                                  variant: AppButtonVariant.outline,
                                  height: 38,
                                  borderRadius: 10,
                                  icon: const Icon(Icons.edit_note_rounded,
                                      size: 15),
                                  onPressed: () =>
                                      _showUpdateStatusSheet(context, report),
                                ),
                              ),
                              SizedBox(
                                width: (MediaQuery.of(context).size.width - 68) / 2 > 120
                                    ? (MediaQuery.of(context).size.width - 68) / 2
                                    : double.infinity,
                                child: AppButton(
                                  text: 'Ubah Urgensi',
                                  variant: AppButtonVariant.outline,
                                  height: 38,
                                  borderRadius: 10,
                                  icon: const Icon(Icons.priority_high_rounded,
                                      size: 15),
                                  onPressed: () =>
                                      _showUpdatePrioritySheet(context, report),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // ─── 2. Milestone Stepper (Progress UI) ─────────────────────
                  MilestoneStepper(
                    currentStepIndex: currentStep,
                    steps: const [
                      MilestoneStep(title: 'Terkirim'),
                      MilestoneStep(title: 'Ditinjau'),
                      MilestoneStep(title: 'Penanganan'),
                      MilestoneStep(title: 'Selesai'),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // ─── 3. Reporter & Student Info (for Counselor) ─────────────
                  if (isCounselor) ...[
                    ModernCard(
                      borderRadius: 16,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(7),
                                ),
                                child: const Icon(Icons.badge_outlined,
                                    size: 15, color: Color(0xFF2563EB)),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Identitas Pelapor (Rahasia BK)',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.slate900,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          _buildDetailRow(
                              'Nama Siswa', report.studentName ?? '-'),
                          _buildDetailRow('Kelas', report.className ?? '-'),
                          _buildDetailRow('Peran', report.reporterType),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],

                  // ─── 4. Incident Details Card ──────────────────────────────
                  ModernCard(
                    borderRadius: 16,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF2F2),
                                borderRadius: BorderRadius.circular(7),
                              ),
                              child: const Icon(Icons.event_note_rounded,
                                  size: 15, color: AppColors.primary),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Rincian Kejadian',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.slate900,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _buildDetailRow('Kategori', report.category),
                        _buildDetailRow(
                          'Waktu Dilaporkan',
                          AppDateFormatter.formatDateTimeWibSingleLine(report.createdAt),
                        ),
                        _buildDetailRow(
                          'Waktu Kejadian',
                          AppDateFormatter.formatDateTimeWibSingleLine(report.incidentDate),
                        ),
                        _buildDetailRow('Lokasi', report.incidentLocation),
                        const SizedBox(height: 10),
                        const Text(
                          'Kronologi / Deskripsi:',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.slate800,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: const Color(0xFFE2E8F0), width: 1),
                          ),
                          child: Text(
                            report.description,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: AppColors.slate800,
                              height: 1.45,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // ─── 5. Attachments ────────────────────────────────────────
                  if (report.attachmentUrls.isNotEmpty) ...[
                    ModernCard(
                      borderRadius: 16,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.attach_file_rounded,
                                  size: 16, color: AppColors.primary),
                              SizedBox(width: 6),
                              Text(
                                'Bukti Terlampir',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.slate900,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: report.attachmentUrls.map((rawUrl) {
                              final fullUrl = rawUrl.startsWith('http')
                                  ? rawUrl
                                  : '${ApiEndpoints.baseUrl}$rawUrl';

                              return GestureDetector(
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (ctx) => Dialog(
                                      backgroundColor: Colors.transparent,
                                      insetPadding: const EdgeInsets.all(16),
                                      child: Stack(
                                        alignment: Alignment.topRight,
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(16),
                                            child: Image.network(
                                              fullUrl,
                                              fit: BoxFit.contain,
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.close_rounded,
                                                color: Colors.white, size: 28),
                                            onPressed: () => Navigator.pop(ctx),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                          color: const Color(0xFFE2E8F0)),
                                    ),
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        Image.network(
                                          fullUrl,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) =>
                                              const Center(
                                            child: Icon(
                                                Icons.broken_image_rounded,
                                                color: AppColors.slate400),
                                          ),
                                        ),
                                        Positioned(
                                          bottom: 4,
                                          right: 4,
                                          child: Container(
                                            padding: const EdgeInsets.all(3),
                                            decoration: BoxDecoration(
                                              color: Colors.black54,
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: const Icon(
                                                Icons.fullscreen_rounded,
                                                color: Colors.white,
                                                size: 13),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],

                  // ─── 6. Internal Counselor Notes (for Counselor) ────────────
                  if (isCounselor) ...[
                    ModernCard(
                      borderRadius: 16,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.lock_person_outlined,
                                  size: 16, color: Color(0xFFD97706)),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Catatan Internal Guru BK (Rahasia)',
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.slate900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Catatan ini tidak dapat dilihat oleh siswa pelapor.',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.slate500,
                            ),
                          ),
                          const SizedBox(height: 10),
                          AppTextField(
                            label: 'Tulis Catatan / Tindak Lanjut',
                            hint: 'Koordinasi dengan wali kelas, orang tua, dll.',
                            controller: _internalNotesController,
                            maxLines: 3,
                          ),
                          const SizedBox(height: 10),
                          Align(
                            alignment: Alignment.centerRight,
                            child: AppButton(
                              text: 'Simpan Catatan',
                              isLoading: _isSavingNotes,
                              width: 140,
                              height: 38,
                              borderRadius: 10,
                              onPressed: () async {
                                final messenger = ScaffoldMessenger.of(context);
                                setState(() => _isSavingNotes = true);
                                try {
                                  await ref
                                      .read(reportRepositoryProvider)
                                      .updateInternalNotes(
                                        reportId: report.id,
                                        internalNotes:
                                            _internalNotesController.text,
                                      );
                                  if (!mounted) return;
                                  messenger.showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Catatan internal berhasil disimpan.'),
                                      backgroundColor: Color(0xFF059669),
                                    ),
                                  );
                                } finally {
                                  if (mounted) {
                                    setState(() => _isSavingNotes = false);
                                  }
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],

                  // ─── 7. Chat Action Button (Pill Button) ─────────────────────
                  AppButton(
                    text: 'Buka Percakapan / Konseling',
                    icon: const Icon(Icons.chat_bubble_outline_rounded,
                        size: 17, color: Colors.white),
                    height: 46,
                    borderRadius: 23,
                    onPressed: () {
                      final chatRoute = isCounselor
                          ? '/counselor/reports/${report.id}/chat'
                          : '/student/reports/${report.id}/chat';
                      context.push(chatRoute);
                    },
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.slate500,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppColors.slate800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
