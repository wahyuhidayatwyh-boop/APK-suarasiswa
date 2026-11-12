import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:suara_siswa/core/constants/app_colors.dart';
import '../../../../shared/models/class_model.dart';
import '../../../auth/presentation/auth_controller.dart';
import '../../data/class_repository.dart';

Future<void> showSelectClassModal(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => const _SelectClassBottomSheet(),
  );
}

class _SelectClassBottomSheet extends ConsumerStatefulWidget {
  const _SelectClassBottomSheet();

  @override
  ConsumerState<_SelectClassBottomSheet> createState() => _SelectClassBottomSheetState();
}

class _SelectClassBottomSheetState extends ConsumerState<_SelectClassBottomSheet> {
  bool _isLoading = true;
  bool _isActionInProgress = false;
  String? _errorMessage;
  List<SchoolClassModel> _classes = [];

  @override
  void initState() {
    super.initState();
    _fetchClasses();
  }

  Future<void> _fetchClasses() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final res = await ref.read(classRepositoryProvider).getClasses();
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (res.success && res.data != null) {
          _classes = res.data!;
        } else {
          _errorMessage = res.error?.message ?? 'Gagal memuat daftar kelas dari server.';
        }
      });
    }
  }

  Future<void> _onSelectClass(SchoolClassModel cls) async {
    if (_isActionInProgress) return;

    final currentClassId = ref.read(authControllerProvider).studentProfile?.classId;
    if (currentClassId == cls.id) {
      Navigator.pop(context);
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);

    setState(() => _isActionInProgress = true);
    final res = await ref.read(classRepositoryProvider).studentSelectClass(cls.id);

    if (mounted) {
      setState(() => _isActionInProgress = false);
      if (res.success && res.data != null) {
        ref.read(authControllerProvider.notifier).updateStudentProfile(res.data!);
        await ref.read(authControllerProvider.notifier).checkSession();
        if (mounted) nav.pop();
        messenger.showSnackBar(
          SnackBar(
            content: Text('Berhasil memilih kelas ${cls.name}.'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        messenger.showSnackBar(
          SnackBar(
            content: Text(res.error?.message ?? 'Gagal memperbarui kelas.'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _onLeaveClass() async {
    if (_isActionInProgress) return;

    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Keluar dari Kelas?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: const Text(
          'Anda akan melepaskan keanggotaan rombel kelas saat ini. Akun dan sekolah Anda tetap tersimpan.',
          style: TextStyle(fontSize: 13, color: AppColors.slate600),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(color: AppColors.slate600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Keluar Kelas', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isActionInProgress = true);
    final res = await ref.read(classRepositoryProvider).studentLeaveClass();

    if (mounted) {
      setState(() => _isActionInProgress = false);
      if (res.success) {
        ref.read(authControllerProvider.notifier).clearStudentClass();
        await ref.read(authControllerProvider.notifier).checkSession();
        if (mounted) nav.pop();
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Berhasil keluar dari kelas.'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        messenger.showSnackBar(
          SnackBar(
            content: Text(res.error?.message ?? 'Gagal keluar dari kelas.'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentStudent = ref.watch(authControllerProvider).studentProfile;
    final currentClassId = currentStudent?.classId;
    final currentSchool = ref.watch(authControllerProvider).currentSchool;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.82,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 14,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.school_rounded, color: Color(0xFF2563EB), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pilih Rombongan Belajar / Kelas',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.slate900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      currentSchool?.name ?? 'Sekolah Anda',
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.slate500,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.slate500),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Subtitle info
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline_rounded, size: 14, color: AppColors.slate500),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Pilih kelas resmi yang dibuat oleh Guru BK di sekolah Anda. Satu siswa hanya dapat aktif di 1 kelas.',
                    style: TextStyle(fontSize: 11, color: AppColors.slate600, height: 1.35),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Content
          Flexible(
            child: _buildContent(currentClassId),
          ),

          // If student already has a class, provide Leave Class button
          if (currentClassId != null && currentClassId.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: Color(0xFFFECACA)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isActionInProgress ? null : _onLeaveClass,
                icon: const Icon(Icons.logout_rounded, size: 16),
                label: const Text(
                  'Keluar dari Kelas Saat Ini',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContent(String? currentClassId) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2.5),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 36, color: AppColors.slate400),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: AppColors.slate600),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: _fetchClasses,
                icon: const Icon(Icons.refresh_rounded, size: 14),
                label: const Text('Coba Lagi', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ),
      );
    }

    if (_classes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.meeting_room_outlined, size: 28, color: AppColors.slate400),
              ),
              const SizedBox(height: 12),
              const Text(
                'Belum Ada Kelas di Sekolah Ini',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.slate800),
              ),
              const SizedBox(height: 4),
              const Text(
                'Guru BK belum menambahkan rombongan belajar. Silakan hubungi Guru BK Anda agar membuat kelas terlebih dahulu.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11.5, color: AppColors.slate500, height: 1.4),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const BouncingScrollPhysics(),
      itemCount: _classes.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final cls = _classes[index];
        final isSelected = cls.id == currentClassId;

        return InkWell(
          onTap: _isActionInProgress ? null : () => _onSelectClass(cls),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      cls.grade.isNotEmpty ? cls.grade : 'KLS',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: isSelected ? Colors.white : AppColors.slate700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cls.name,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? const Color(0xFF1E3A8A) : AppColors.slate900,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${cls.studentCount} Siswa terdaftar${(cls.joinCode != null && cls.joinCode!.isNotEmpty) ? " • Kode: ${cls.joinCode}" : ""}',
                        style: const TextStyle(fontSize: 11, color: AppColors.slate500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (isSelected)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_rounded, size: 12, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          'Kelas Anda',
                          style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  )
                else
                  const Icon(Icons.arrow_forward_ios_rounded, size: 13, color: AppColors.slate400),
              ],
            ),
          ),
        );
      },
    );
  }
}
