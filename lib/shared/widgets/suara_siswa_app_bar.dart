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
      scrolledUnderElevation: 0,
      titleSpacing: 18,
      leading: (showBack || Navigator.of(context).canPop())
          ? IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: AppColors.slate800),
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
              color: AppColors.slate900,
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
                    top: 10,
                    right: 10,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
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
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.borderStrong, width: 1.2),
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
        child: Divider(height: 1, thickness: 1, color: AppColors.borderStrong),
      ),
    );
  }

  Widget _buildInitial(String name) {
    return Center(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : 'S',
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
      ),
    );
  }
}
