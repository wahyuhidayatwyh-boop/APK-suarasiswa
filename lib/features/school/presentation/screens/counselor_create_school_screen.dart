import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../auth/presentation/auth_controller.dart';

class CounselorCreateSchoolScreen extends ConsumerStatefulWidget {
  const CounselorCreateSchoolScreen({super.key});

  @override
  ConsumerState<CounselorCreateSchoolScreen> createState() =>
      _CounselorCreateSchoolScreenState();
}

class _CounselorCreateSchoolScreenState
    extends ConsumerState<CounselorCreateSchoolScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _schoolNameController = TextEditingController();
  final TextEditingController _counselorNameController = TextEditingController();
  final TextEditingController _nipController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Default counselor name to logged in Google User name
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authControllerProvider).user;
      if (user != null && _counselorNameController.text.isEmpty) {
        _counselorNameController.text = user.name;
      }
    });
  }

  @override
  void dispose() {
    _schoolNameController.dispose();
    _counselorNameController.dispose();
    _nipController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _handleCreateSchool() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(authControllerProvider.notifier).createSchool(
      schoolName: _schoolNameController.text.trim(),
      counselorName: _counselorNameController.text.trim(),
      nip: _nipController.text.trim().isEmpty ? null : _nipController.text.trim(),
      phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
      address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
    );

    if (success && mounted) {
      context.go('/counselor/school-setup');
    } else if (mounted) {
      // Re-verify session in case the school was actually created before any network glitch
      await ref.read(authControllerProvider.notifier).checkSession();
      if (!mounted) return;
      final authState = ref.read(authControllerProvider);
      if (authState.hasSchool && authState.isCounselor) {
        context.go('/counselor/school-setup');
        return;
      }

      final error = ref.read(authControllerProvider).errorMessage ?? 'Gagal membuat ruang sekolah.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Buat Ruang Sekolah'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info Banner
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.lightRed,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.redBorder),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline, color: AppColors.primary, size: 22),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Sebagai pembuat ruang, Anda akan menjadi penanggung jawab (Owner) ruang sekolah ini. Anda dapat mengundang Guru BK lain dan mengelola kelas.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.darkRed,
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

                // School Info Section
                const Text(
                  'Informasi Sekolah',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                AppTextField(
                  label: 'Nama Resmi Sekolah *',
                  hint: 'misal: SMK Negeri 1 Surabaya',
                  controller: _schoolNameController,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Nama sekolah wajib diisi';
                    }
                    if (val.trim().length < 3) {
                      return 'Nama sekolah minimal 3 karakter';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                AppTextField(
                  label: 'Alamat Sekolah',
                  hint: 'misal: Jl. Raya Pendidikan No. 12',
                  controller: _addressController,
                ),
                const SizedBox(height: 24),

                // Counselor Info Section
                const Text(
                  'Profil Guru BK (Penanggung Jawab)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                AppTextField(
                  label: 'Nama Lengkap & Gelar *',
                  hint: 'misal: Siti Nurhaliza, S.Pd',
                  controller: _counselorNameController,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Nama Guru BK wajib diisi';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                AppTextField(
                  label: 'NIP / Nomor Identitas Guru',
                  hint: 'Nomor Pegawai atau NIP (opsional)',
                  controller: _nipController,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 14),
                AppTextField(
                  label: 'Nomor WhatsApp / HP',
                  hint: '08xxxxxxxxxx',
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 32),

                AppButton(
                  text: 'Buat Ruang Sekolah Sekarang',
                  isLoading: authState.isLoading,
                  onPressed: _handleCreateSchool,
                ),
                const SizedBox(height: 12),
                Center(
                  child: TextButton(
                    onPressed: () => context.push('/counselor/join-school'),
                    child: const Text(
                      'Sudah punya Kode Undangan Guru BK? Gabung di sini',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
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
