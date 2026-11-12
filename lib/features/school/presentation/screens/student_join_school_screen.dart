import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../auth/presentation/auth_controller.dart';

class StudentJoinSchoolScreen extends ConsumerStatefulWidget {
  const StudentJoinSchoolScreen({super.key});

  @override
  ConsumerState<StudentJoinSchoolScreen> createState() =>
      _StudentJoinSchoolScreenState();
}

class _StudentJoinSchoolScreenState
    extends ConsumerState<StudentJoinSchoolScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _schoolCodeController = TextEditingController();
  final TextEditingController _studentIdController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authControllerProvider).user;
      if (user != null && _nameController.text.isEmpty) {
        _nameController.text = user.name;
      }
    });
  }

  @override
  void dispose() {
    _schoolCodeController.dispose();
    _studentIdController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleJoin() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(authControllerProvider.notifier).joinSchoolAsStudent(
      schoolCode: _schoolCodeController.text.trim(),
      studentId: _studentIdController.text.trim(),
      studentName: _nameController.text.trim(),
      phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
    );

    if (success && mounted) {
      _showSuccessDialog();
    } else if (mounted) {
      final error = ref.read(authControllerProvider).errorMessage ?? 'Gagal bergabung ke sekolah. Periksa kembali kode sekolah.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showSuccessDialog() {
    final authState = ref.read(authControllerProvider);
    final schoolName = authState.currentSchool?.name ?? 'Sekolah';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: AppColors.successLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 38,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Berhasil Bergabung!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sekolah: $schoolName',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Status: Terdaftar di Sekolah',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF059669),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Pilih rombongan belajar / kelas Anda melalui Beranda atau halaman Profil.',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AppColors.slate500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              AppButton(
                text: 'Mulai Masuk Beranda',
                onPressed: () {
                  Navigator.pop(ctx);
                  context.go('/student');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Gabung ke Sekolah'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.infoLight,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.infoBorder),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.shield_outlined, color: AppColors.info, size: 22),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Data laporan dan aspirasi Anda hanya akan terhubung dengan Guru BK di sekolah ini. Identitas Anda dijaga secara ketat dan aman.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textPrimary,
                            height: 1.45,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                if (authState.errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.lightRed,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.redBorder),
                    ),
                    child: Text(
                      authState.errorMessage!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.darkRed,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                AppTextField(
                  label: 'Kode Sekolah *',
                  hint: 'misal: SMK-TN82',
                  controller: _schoolCodeController,
                  textCapitalization: TextCapitalization.characters,
                  helperText: 'Dapatkan kode ini dari Guru BK atau pihak sekolah',
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Kode sekolah wajib diisi';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                AppTextField(
                  label: 'Nomor Induk Siswa (NIS) *',
                  hint: 'misal: 12345',
                  controller: _studentIdController,
                  keyboardType: TextInputType.number,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'NIS wajib diisi untuk verifikasi siswa';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                AppTextField(
                  label: 'Nama Lengkap Siswa *',
                  hint: 'Nama lengkap Anda',
                  controller: _nameController,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Nama lengkap wajib diisi';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                AppTextField(
                  label: 'Nomor WhatsApp / HP',
                  hint: '08xxxxxxxxxx (opsional)',
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 32),

                AppButton(
                  text: 'Gabung Sekarang',
                  isLoading: authState.isLoading,
                  onPressed: _handleJoin,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
