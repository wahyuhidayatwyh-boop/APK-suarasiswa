import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../features/auth/presentation/auth_controller.dart';
import '../../features/notifications/data/notification_repository.dart';

class SuaraSiswaTopBar extends ConsumerWidget implements PreferredSizeWidget {
  final bool showBack;
  final VoidCallback? onAvatarTap;

  const SuaraSiswaTopBar({
    super.key,
    this.showBack = false,
    this.onAvatarTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      titleSpacing: 20,
      leading: (showBack || Navigator.of(context).canPop())
          ? IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
              onPressed: () => Navigator.of(context).maybePop(),
            )
          : null,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.asset(
              'assets/images/logo.png',
              width: 24,
              height: 24,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.shield_rounded,
                color: AppColors.primary,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'SuaraSiswa',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
      actions: [
        Consumer(
          builder: (context, ref, _) {
            final unreadCount = ref.watch(unreadNotificationsCountProvider);
            return Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.notifications_none_rounded,
                    color: AppColors.slate700,
                    size: 22,
                  ),
                  tooltip: 'Notifikasi',
                  onPressed: () => context.push('/notifications'),
                ),
                if (unreadCount > 0)
                  Positioned(
                    top: 8,
                    right: 8,
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
        Consumer(
          builder: (context, ref, _) {
            final authState = ref.watch(authControllerProvider);
            final user = authState.user;
            final photoUrl = user?.photoUrl;
            final name = authState.studentProfile?.name ?? user?.name ?? 'Siswa';

            return Padding(
              padding: const EdgeInsets.only(right: 16, left: 4),
              child: InkWell(
                onTap: onAvatarTap,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
                    color: AppColors.lightRed,
                  ),
                  child: ClipOval(
                    child: (photoUrl != null && photoUrl.isNotEmpty)
                        ? Image.network(
                            photoUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => _buildInitial(name),
                          )
                        : _buildInitial(name),
                  ),
                ),
              ),
            );
          },
        ),
      ],
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
      ),
    );
  }

  Widget _buildInitial(String name) {
    return Center(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : 'S',
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
      ),
    );
  }
}
