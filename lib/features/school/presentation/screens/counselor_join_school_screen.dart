import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../auth/presentation/auth_controller.dart';

class CounselorJoinSchoolScreen extends ConsumerStatefulWidget {
  const CounselorJoinSchoolScreen({super.key});

  @override
  ConsumerState<CounselorJoinSchoolScreen> createState() =>
      _CounselorJoinSchoolScreenState();
}

class _CounselorJoinSchoolScreenState
    extends ConsumerState<CounselorJoinSchoolScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _inviteCodeController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _nipController = TextEditingController();
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
    _inviteCodeController.dispose();
    _nameController.dispose();
    _nipController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleJoin() async {
    if (!_formKey.currentState!.validate()) return;

    final success =
        await ref.read(authControllerProvider.notifier).joinSchoolAsCounselor(
              inviteCode: _inviteCodeController.text.trim(),
              counselorName: _nameController.text.trim(),
              nip: _nipController.text.trim().isEmpty ? null : _nipController.text.trim(),
              phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
            );

    if (success && mounted) {
      context.go('/counselor');
    } else if (mounted) {
      final error = ref.read(authControllerProvider).errorMessage ?? 'Gagal bergabung. Periksa kode undangan Guru BK.';
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
        title: const Text('Gabung sebagai Guru BK'),
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
                    color: AppColors.purpleLight,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.purple.withOpacity(0.3)),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.vpn_key_outlined, color: AppColors.purple, size: 22),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Untuk menjaga kerahasiaan siswa, akses Guru BK memerlukan Kode Undangan Resmi (Invitation Code) yang digenerate oleh Guru BK Pemilik Sekolah.',
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
                  label: 'Kode Undangan Guru BK *',
                  hint: 'misal: BK-SCH001-X92K',
                  controller: _inviteCodeController,
                  textCapitalization: TextCapitalization.characters,
                  helperText: 'Dapatkan kode rahasia ini dari Guru BK utama di sekolah Anda',
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Kode undangan wajib diisi';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                AppTextField(
                  label: 'Nama Lengkap Guru BK *',
                  hint: 'Nama lengkap & gelar',
                  controller: _nameController,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Nama wajib diisi';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                AppTextField(
                  label: 'NIP / Nomor Pegawai',
                  hint: 'Nomor identitas guru (opsional)',
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
                  text: 'Verifikasi & Gabung',
                  isLoading: authState.isLoading,
                  onPressed: _handleJoin,
                ),
                const SizedBox(height: 12),
                Center(
                  child: TextButton(
                    onPressed: () => context.push('/counselor/create-school'),
                    child: const Text(
                      'Ingin mendaftarkan sekolah baru? Buat di sini',
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
