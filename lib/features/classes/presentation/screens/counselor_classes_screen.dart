import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:suara_siswa/core/constants/app_colors.dart';
import 'package:suara_siswa/core/network/api_response.dart';
import 'package:suara_siswa/features/classes/data/class_repository.dart';
import 'package:suara_siswa/shared/models/class_model.dart';
import 'package:suara_siswa/shared/models/user_model.dart';
import 'package:suara_siswa/shared/widgets/app_text_field.dart';
import 'package:suara_siswa/shared/widgets/empty_state_view.dart';
import 'package:suara_siswa/shared/widgets/modern_card.dart';

class CounselorClassesScreen extends ConsumerStatefulWidget {
  const CounselorClassesScreen({super.key});

  @override
  ConsumerState<CounselorClassesScreen> createState() =>
      _CounselorClassesScreenState();
}

class _CounselorClassesScreenState extends ConsumerState<CounselorClassesScreen> {
  late Future<ApiResponse<List<SchoolClassModel>>> _classesFuture;

  @override
  void initState() {
    super.initState();
    _refreshClasses();
  }

  void _refreshClasses() {
    setState(() {
      _classesFuture = ref.read(classRepositoryProvider).getClasses();
    });
  }

  void _showAddClassDialog(BuildContext context) {
    final nameController = TextEditingController();
    final gradeController = TextEditingController(text: 'X');
    final descController = TextEditingController();
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text(
                'Tambah Kelas Baru',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppTextField(
                      label: 'Nama Rombel / Kelas *',
                      hint: 'misal: XI RPL 1, X TKJ 2',
                      controller: nameController,
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      label: 'Tingkat / Grade *',
                      hint: 'X, XI, atau XII',
                      controller: gradeController,
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      label: 'Keterangan (Opsional)',
                      hint: 'Jurusan / Wali Kelas',
                      controller: descController,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(ctx),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: isSaving
                      ? null
                      : () async {
                          final name = nameController.text.trim();
                          final grade = gradeController.text.trim();
                          if (name.isEmpty || grade.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Nama kelas dan tingkatan wajib diisi!'),
                                backgroundColor: AppColors.primary,
                              ),
                            );
                            return;
                          }

                          setDialogState(() => isSaving = true);
                          final messenger = ScaffoldMessenger.of(context);

                          final res = await ref.read(classRepositoryProvider).addClass(
                                name: name,
                                grade: grade,
                                description: descController.text.trim().isEmpty
                                    ? null
                                    : descController.text.trim(),
                              );

                          if (ctx.mounted) Navigator.pop(ctx);

                          if (!mounted) return;

                          if (res.success) {
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text('Kelas "$name" berhasil ditambahkan!'),
                                backgroundColor: AppColors.success,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                            _refreshClasses();
                          } else {
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Gagal menambah kelas: ${res.error?.message ?? "Terjadi kesalahan"}',
                                ),
                                backgroundColor: AppColors.primary,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                  child: isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmRemoveStudent(BuildContext context, SchoolClassModel cls, StudentProfileModel student, void Function() onRemoved) {
    showDialog(
      context: context,
      builder: (dlgCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.person_remove_rounded, color: AppColors.error, size: 24),
            SizedBox(width: 8),
            Expanded(child: Text('Keluarkan Siswa?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
          ],
        ),
        content: Text(
          'Apakah Anda yakin ingin mengeluarkan "${student.name}" (NIS: ${student.studentId}) dari kelas ${cls.name}? Akun siswa tidak akan dihapus, namun siswa tidak lagi menjadi anggota kelas ini.',
          style: const TextStyle(fontSize: 13, color: AppColors.slate700),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dlgCtx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(dlgCtx);
              final res = await ref.read(classRepositoryProvider).removeStudentFromClass(
                    classId: cls.id,
                    studentId: student.id,
                  );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(res.success ? 'Siswa berhasil dikeluarkan dari kelas.' : 'Gagal mengeluarkan siswa.'),
                    backgroundColor: res.success ? AppColors.success : AppColors.error,
                  ),
                );
              }
              onRemoved();
              _refreshClasses();
            },
            child: const Text('Keluarkan'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteClass(BuildContext context, SchoolClassModel cls) {
    showDialog(
      context: context,
      builder: (dlgCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 24),
            SizedBox(width: 8),
            Expanded(child: Text('Hapus Kelas?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
          ],
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus kelas "${cls.name}"? Kelas akan dinonaktifkan di remote database dan seluruh anggota di dalamnya akan dilepas dari kelas ini.',
          style: const TextStyle(fontSize: 13, color: AppColors.slate700),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dlgCtx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(dlgCtx);
              final res = await ref.read(classRepositoryProvider).deleteClass(cls.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(res.success ? 'Kelas berhasil dihapus.' : 'Gagal menghapus kelas.'),
                    backgroundColor: res.success ? AppColors.success : AppColors.error,
                  ),
                );
              }
              _refreshClasses();
            },
            child: const Text('Hapus Kelas'),
          ),
        ],
      ),
    );
  }

  void _showClassStudentsSheet(BuildContext context, SchoolClassModel cls) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.65,
              maxChildSize: 0.9,
              minChildSize: 0.4,
              expand: false,
              builder: (_, scrollController) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.border,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Daftar Siswa — ${cls.name}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Kode Kelas: ${cls.joinCode ?? "-"} • Tingkat: ${cls.grade}',
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: FutureBuilder(
                          future: ref.read(classRepositoryProvider).getClassStudents(cls.id),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                            }

                            final students = snapshot.data?.data ?? [];

                            if (students.isEmpty) {
                              return const EmptyStateView(
                                icon: Icons.people_outline,
                                title: 'Belum Ada Siswa',
                                description: 'Bagikan kode kelas kepada siswa untuk bergabung ke kelas ini.',
                              );
                            }

                            return ListView.separated(
                              controller: scrollController,
                              itemCount: students.length,
                              separatorBuilder: (_, _) => const Divider(height: 1, color: AppColors.border),
                              itemBuilder: (context, index) {
                                final s = students[index];
                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: CircleAvatar(
                                    backgroundColor: AppColors.lightRed,
                                    child: Text(
                                      s.name.isNotEmpty ? s.name[0].toUpperCase() : 'S',
                                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                  title: Text(
                                    s.name,
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                                  ),
                                  subtitle: Text(
                                    'NIS: ${s.studentId} • WA: ${s.phone ?? "-"}',
                                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.person_remove_outlined, color: AppColors.error, size: 20),
                                    tooltip: 'Keluarkan Siswa',
                                    onPressed: () {
                                      _confirmRemoveStudent(context, cls, s, () {
                                        setModalState(() {});
                                      });
                                    },
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Kelola Kelas & Siswa'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: AppColors.textPrimary),
            tooltip: 'Tambah Kelas',
            onPressed: () => _showAddClassDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
            tooltip: 'Segarkan',
            onPressed: _refreshClasses,
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async => _refreshClasses(),
        child: FutureBuilder(
          future: _classesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: AppColors.primary));
            }

            final classes = snapshot.data?.data ?? [];

            if (classes.isEmpty) {
              return EmptyStateView(
                icon: Icons.meeting_room_outlined,
                title: 'Belum Ada Kelas',
                description: 'Buat kelas pertama Anda agar siswa dapat bergabung menggunakan kode kelas.',
                buttonText: 'Tambah Kelas Pertama',
                onButtonPressed: () => _showAddClassDialog(context),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.only(left: 18, right: 18, top: 14, bottom: 96),
              itemCount: classes.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final cls = classes[index];

                return ModernCard(
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
                              cls.name,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: AppColors.slate900,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFBFDBFE), width: 0.8),
                            ),
                            child: Text(
                              '${cls.studentCount} Siswa',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF2563EB),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (cls.description != null && cls.description!.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          cls.description!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11.5, color: AppColors.slate500),
                        ),
                      ],
                      const SizedBox(height: 10),
                      Container(height: 1, color: const Color(0xFFF1F5F9)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'Kode: ',
                                  style: TextStyle(fontSize: 11.5, color: AppColors.slate500),
                                ),
                                Flexible(
                                  child: Text(
                                    cls.joinCode ?? '-',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.primary,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                InkWell(
                                  borderRadius: BorderRadius.circular(6),
                                  onTap: () {
                                    if (cls.joinCode != null) {
                                      Clipboard.setData(ClipboardData(text: cls.joinCode!));
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Kode kelas berhasil disalin!'),
                                          duration: Duration(seconds: 1),
                                        ),
                                      );
                                    }
                                  },
                                  child: const Padding(
                                    padding: EdgeInsets.all(4),
                                    child: Icon(Icons.copy_rounded, size: 14, color: AppColors.primary),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () => _showClassStudentsSheet(context, cls),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.lightRed,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Siswa',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  SizedBox(width: 2),
                                  Icon(Icons.arrow_forward_ios_rounded, size: 9, color: AppColors.primary),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () => _confirmDeleteClass(context, cls),
                            child: const Padding(
                              padding: EdgeInsets.all(4),
                              child: Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.error),
                            ),
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
      ),
    );
  }
}
