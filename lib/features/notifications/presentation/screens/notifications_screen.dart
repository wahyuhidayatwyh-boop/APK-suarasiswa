import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/models/notification_model.dart';
import '../../../../shared/utils/date_formatter.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/modern_card.dart';
import '../../../../shared/widgets/suara_siswa_app_bar.dart';
import '../../../auth/presentation/auth_controller.dart';
import '../../data/notification_repository.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  String _selectedFilter = 'ALL';

  @override
  Widget build(BuildContext context) {
    final notifsAsync = ref.watch(notificationsFutureProvider);
    final authState = ref.watch(authControllerProvider);
    final isStudent = authState.isStudent;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: const SuaraSiswaTopBar(),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            ref.invalidate(notificationsFutureProvider);
          },
          child: notifsAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(
                  color: AppColors.primary, strokeWidth: 2.5),
            ),
            error: (err, stack) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        size: 48, color: Color(0xFFDC2626)),
                    const SizedBox(height: 12),
                    const Text(
                      'Gagal memuat notifikasi',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      err.toString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.slate500),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () =>
                          ref.invalidate(notificationsFutureProvider),
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            ),
            data: (allNotifs) {
              final unreadCount = allNotifs.where((n) => !n.isRead).length;

              // Filter
              final filteredNotifs = allNotifs.where((n) {
                if (_selectedFilter == 'ALL') return true;
                if (_selectedFilter == 'COUNSELOR') {
                  return n.type == 'NEW_MESSAGE' || n.type == 'FOLLOWUP';
                }
                if (_selectedFilter == 'STATUS') {
                  return n.type == 'REPORT_UPDATE' ||
                      n.type == 'STATUS_CHANGE';
                }
                return true;
              }).toList();

              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Clean & Minimalist Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Notifikasi',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: AppColors.slate900,
                                letterSpacing: -0.4,
                              ),
                            ),
                            if (unreadCount > 0) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2.5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF2F2),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                      color: const Color(0xFFFECACA),
                                      width: 1),
                                ),
                                child: Text(
                                  '$unreadCount baru',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (allNotifs.isNotEmpty)
                          PopupMenuButton<String>(
                            tooltip: 'Opsi Notifikasi',
                            icon: Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: const Color(0xFFE2E8F0)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.03),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.more_horiz_rounded,
                                size: 18,
                                color: AppColors.slate700,
                              ),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 4,
                            onSelected: (val) async {
                              if (val == 'read_all') {
                                await ref
                                    .read(notificationRepositoryProvider)
                                    .markAllAsRead();
                                ref.invalidate(notificationsFutureProvider);
                              } else if (val == 'delete_all') {
                                _showDeleteAllConfirmation(context);
                              }
                            },
                            itemBuilder: (ctx) => [
                              if (unreadCount > 0)
                                const PopupMenuItem(
                                  value: 'read_all',
                                  child: Row(
                                    children: [
                                      Icon(Icons.done_all_rounded,
                                          size: 18, color: AppColors.primary),
                                      SizedBox(width: 10),
                                      Text(
                                        'Tandai Semua Dibaca',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.slate800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              const PopupMenuItem(
                                value: 'delete_all',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete_outline_rounded,
                                        size: 18, color: Color(0xFFEF4444)),
                                    SizedBox(width: 10),
                                    Text(
                                      'Hapus Semua',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFFEF4444),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Information banner
                    ModernCard(
                      variant: ModernCardVariant.flat,
                      borderRadius: 16,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      child: const Row(
                        children: [
                          Icon(Icons.shield_outlined,
                              size: 16, color: Color(0xFF059669)),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Kanal komunikasi aman & terenkripsi. Pemberitahuan langsung terhubung dengan Guru BK.',
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
                    const SizedBox(height: 14),

                    // Filter Pills
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterPill('ALL', 'Semua'),
                          const SizedBox(width: 8),
                          _buildFilterPill('COUNSELOR', 'Guru BK & Pesan'),
                          const SizedBox(width: 8),
                          _buildFilterPill('STATUS', 'Status Laporan'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (filteredNotifs.isEmpty)
                      EmptyStateView(
                        icon: Icons.notifications_off_outlined,
                        title: 'Tidak Ada Notifikasi',
                        description: _selectedFilter == 'ALL'
                            ? 'Belum ada notifikasi baru untuk saat ini.'
                            : 'Tidak ada notifikasi dalam filter ini.',
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filteredNotifs.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final notif = filteredNotifs[index];
                          return _buildNotificationCard(notif, isStudent);
                        },
                      ),

                    // Spacing to keep content cleanly above the floating bottom navigation bar
                    const SizedBox(height: 96),
                  ],
                ),
              );
            },
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

  Widget _buildNotificationCard(NotificationModel notif, bool isStudent) {
    IconData iconData = Icons.notifications_outlined;
    Color iconColor = AppColors.primary;
    Color iconBg = AppColors.lightRed;

    switch (notif.type) {
      case 'NEW_MESSAGE':
        iconData = Icons.chat_bubble_outline_rounded;
        iconColor = const Color(0xFF7C3AED);
        iconBg = const Color(0xFFF5F3FF);
        break;
      case 'REPORT_UPDATE':
      case 'STATUS_CHANGE':
        iconData = Icons.sync_alt_rounded;
        iconColor = const Color(0xFF2563EB);
        iconBg = const Color(0xFFEFF6FF);
        break;
      case 'FOLLOWUP':
        iconData = Icons.assignment_turned_in_outlined;
        iconColor = const Color(0xFF059669);
        iconBg = const Color(0xFFECFDF5);
        break;
      default:
        iconData = Icons.notifications_none_rounded;
        iconColor = AppColors.primary;
        iconBg = AppColors.lightRed;
        break;
    }

    return ModernCard(
      borderRadius: 16,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      onTap: () async {
        if (!notif.isRead) {
          await ref
              .read(notificationRepositoryProvider)
              .markAsRead(notif.id);
          ref.invalidate(notificationsFutureProvider);
        }

        if (notif.referenceId != null && mounted) {
          final prefix = isStudent ? '/student' : '/counselor';
          if (notif.type == 'NEW_MESSAGE') {
            context.push('$prefix/reports/${notif.referenceId}/chat');
          } else {
            context.push('$prefix/reports/${notif.referenceId}');
          }
        }
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(iconData, color: iconColor, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        notif.title,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: notif.isRead
                              ? FontWeight.w600
                              : FontWeight.w800,
                          color: AppColors.slate900,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (!notif.isRead) ...[
                      const SizedBox(width: 6),
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                    const SizedBox(width: 4),
                    InkWell(
                      onTap: () => _deleteSingleNotification(notif.id),
                      borderRadius: BorderRadius.circular(10),
                      child: const Padding(
                        padding: EdgeInsets.all(3),
                        child: Icon(Icons.close_rounded,
                            size: 15, color: AppColors.slate400),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  notif.body,
                  style: TextStyle(
                    fontSize: 12,
                    color: notif.isRead
                        ? AppColors.slate500
                        : AppColors.slate700,
                    height: 1.35,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.access_time_rounded,
                              size: 11, color: AppColors.slate400),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              AppDateFormatter.formatRelative(notif.createdAt),
                              style: const TextStyle(
                                fontSize: 10.5,
                                color: AppColors.slate400,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (notif.referenceId != null) ...[
                      const SizedBox(width: 8),
                      const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Lihat Detail',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                          SizedBox(width: 2),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 9,
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteSingleNotification(String id) async {
    try {
      await ref.read(notificationRepositoryProvider).deleteNotification(id);
      ref.invalidate(notificationsFutureProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notifikasi telah dihapus'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menghapus notifikasi: $e')),
        );
      }
    }
  }

  Future<void> _showDeleteAllConfirmation(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Hapus Semua Notifikasi?',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Semua notifikasi Anda akan dibersihkan. Tindakan ini tidak dapat dibatalkan.',
          style: TextStyle(fontSize: 13, color: AppColors.slate600),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal', style: TextStyle(color: AppColors.slate600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              elevation: 0,
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
        await ref.read(notificationRepositoryProvider).deleteAllNotifications();
        ref.invalidate(notificationsFutureProvider);
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Semua notifikasi berhasil dibersihkan'),
            duration: Duration(seconds: 2),
          ),
        );
      } catch (e) {
        messenger.showSnackBar(
          SnackBar(content: Text('Gagal menghapus semua notifikasi: $e')),
        );
      }
    }
  }
}
