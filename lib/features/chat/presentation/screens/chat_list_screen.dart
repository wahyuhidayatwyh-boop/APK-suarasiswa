import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/models/report_model.dart';
import '../../../../shared/utils/date_formatter.dart';
import '../../../../shared/widgets/app_badge.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/modern_card.dart';
import '../../../../shared/widgets/suara_siswa_app_bar.dart';
import '../../../reports/data/report_repository.dart';

class ChatListScreen extends ConsumerStatefulWidget {
  final bool isCounselor;

  const ChatListScreen({super.key, required this.isCounselor});

  @override
  ConsumerState<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends ConsumerState<ChatListScreen> {
  late Future<dynamic> _reportsFuture;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
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
            _refresh();
            await _reportsFuture;
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.isCounselor
                                ? 'Pesan & Konseling Siswa'
                                : 'Pesan & Konseling BK',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: AppColors.slate900,
                              letterSpacing: -0.4,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            widget.isCounselor
                                ? 'Daftar sesi konsultasi dan percakapan rahasia dengan siswa.'
                                : 'Komunikasi privat dan pendampingan bersama Guru BK sekolah.',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.slate500,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFBFDBFE), width: 1),
                      ),
                      child: const Icon(
                        Icons.mark_chat_unread_outlined,
                        color: Color(0xFF2563EB),
                        size: 20,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Privacy Banner
                ModernCard(
                  variant: ModernCardVariant.flat,
                  borderRadius: 16,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: const Row(
                    children: [
                      Icon(Icons.lock_rounded, size: 16, color: Color(0xFF059669)),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Percakapan bersifat rahasia dan aman, dilindungi kode etik bimbingan konseling.',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: AppColors.slate600,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Conversations List
                FutureBuilder(
                  future: _reportsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                            strokeWidth: 2.5,
                          ),
                        ),
                      );
                    }

                    final reports = (snapshot.data?.data as List<ReportModel>?) ?? [];

                    if (reports.isEmpty) {
                      return EmptyStateView(
                        icon: Icons.chat_bubble_outline_rounded,
                        title: widget.isCounselor
                            ? 'Belum Ada Percakapan'
                            : 'Belum Ada Pesan Konseling',
                        description: widget.isCounselor
                            ? 'Percakapan akan otomatis muncul di sini ketika siswa menyampaikan pengaduan atau meminta konseling.'
                            : 'Kamu belum memiliki sesi percakapan. Buat laporan atau konsultasi baru untuk memulai chat privat dengan Guru BK.',
                        buttonText: widget.isCounselor ? null : 'Mulai Konseling Baru',
                        onButtonPressed: widget.isCounselor
                            ? null
                            : () => context.push('/student/create-report'),
                      );
                    }

                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: reports.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final item = reports[index];
                        final isBullying = item.type == ReportType.bullying;
                        final accentColor = isBullying
                            ? const Color(0xFFDC2626)
                            : item.type == ReportType.konseling
                                ? const Color(0xFF059669)
                                : const Color(0xFF2563EB);

                        final partnerName = widget.isCounselor
                            ? (item.studentName != null && item.studentName!.isNotEmpty
                                ? '${item.studentName} (${item.className ?? "Siswa"})'
                                : 'Siswa #${item.reportCode}')
                            : 'Guru BK Sekolah';

                        return ModernCard(
                          borderRadius: 18,
                          padding: const EdgeInsets.all(14),
                          onTap: () {
                            final chatRoute = widget.isCounselor
                                ? '/counselor/reports/${item.id}/chat'
                                : '/student/reports/${item.id}/chat';
                            context.push(chatRoute).then((_) => _refresh());
                          },
                          child: Row(
                            children: [
                              // Avatar / Icon
                              Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  color: accentColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Icon(
                                  widget.isCounselor
                                      ? Icons.person_outline_rounded
                                      : Icons.psychology_alt_outlined,
                                  color: accentColor,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),

                              // Text detail
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            partnerName,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.slate900,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          AppDateFormatter.formatChatListTime(item.createdAt),
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: AppColors.slate400,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      '#${item.reportCode} • ${item.category}',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                        color: accentColor,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      item.description,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.slate500,
                                        height: 1.3,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),

                              // Status Badge & Arrow
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  AppBadge.status(item.status),
                                  const SizedBox(height: 6),
                                  const Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    size: 12,
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

                // Spacing above bottom bar
                const SizedBox(height: 96),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
