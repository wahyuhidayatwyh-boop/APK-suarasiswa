import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../auth/presentation/auth_controller.dart';

class CounselorInvitesScreen extends ConsumerStatefulWidget {
  const CounselorInvitesScreen({super.key});

  @override
  ConsumerState<CounselorInvitesScreen> createState() =>
      _CounselorInvitesScreenState();
}

class _CounselorInvitesScreenState extends ConsumerState<CounselorInvitesScreen> {
  bool _isLoading = true;
  bool _isGenerating = false;
  List<Map<String, dynamic>> _invites = [];
  List<Map<String, dynamic>> _activeCounselors = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final apiClient = ref.read(apiClientProvider);

    try {
      final counselorsRes = await apiClient.get<dynamic>('/api/counselors');
      final invitesRes = await apiClient.get<dynamic>('/api/counselors/invites');

      if (mounted) {
        setState(() {
          _isLoading = false;
          if (counselorsRes.success && counselorsRes.data is List) {
            _activeCounselors = List<Map<String, dynamic>>.from(counselorsRes.data as List);
          }
          if (invitesRes.success && invitesRes.data is List) {
            _invites = List<Map<String, dynamic>>.from(invitesRes.data as List);
          }
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _generateNewInvite() async {
    if (_isGenerating) return;

    setState(() => _isGenerating = true);
    final apiClient = ref.read(apiClientProvider);

    try {
      final res = await apiClient.post<Map<String, dynamic>>('/api/counselors/invites');
      if (mounted) {
        setState(() => _isGenerating = false);
        if (res.success && res.data != null) {
          final code = res.data!['invite_code'] as String? ?? 'BK-BARU';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Kode undangan $code berhasil dibuat di server!'),
              backgroundColor: AppColors.success,
              duration: const Duration(seconds: 2),
            ),
          );
          _loadData();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(res.error?.message ?? 'Gagal membuat kode undangan.'),
              backgroundColor: AppColors.primary,
            ),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Undangan Rekan Guru BK'),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _loadData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info Card
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
                      Icon(Icons.shield_outlined, color: AppColors.purple, size: 22),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Kode undangan ini khusus untuk rekan Guru BK yang bertugas di sekolah Anda. Hanya Guru BK yang memiliki kode ini yang dapat mengakses laporan sekolah.',
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
                const SizedBox(height: 20),

                // Generate Button
                AppButton(
                  text: _isGenerating ? 'Membuat Kode...' : 'Buat Kode Undangan Baru',
                  icon: const Icon(Icons.add, size: 18),
                  onPressed: _isGenerating ? null : _generateNewInvite,
                ),
                const SizedBox(height: 24),

                // Active Invitations
                const Text(
                  'Kode Undangan Aktif',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                if (_isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(color: AppColors.primary),
                    ),
                  )
                else if (_invites.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Text(
                      'Belum ada kode undangan aktif. Tekan tombol di atas untuk membuat kode.',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                  )
                else
                  ..._invites.map((inv) {
                    final code = inv['code'] as String? ?? '-';
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                code,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                  letterSpacing: 1.1,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'Status: AKTIF • Berlaku 7 hari',
                                style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                          IconButton(
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: code));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Kode undangan disalin!'),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            },
                            icon: const Icon(Icons.copy_rounded, color: AppColors.primary),
                            tooltip: 'Salin Kode',
                          ),
                        ],
                      ),
                    );
                  }),
                const SizedBox(height: 24),

                // Active Counselors List
                const Text(
                  'Guru BK Terdaftar di Sekolah Ini',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                if (!_isLoading && _activeCounselors.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Text(
                      'Belum ada data Guru BK lain yang terdaftar.',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                  )
                else
                  ..._activeCounselors.map((c) {
                    final name = c['name'] as String? ?? 'Guru BK';
                    final nip = c['employee_id'] as String? ?? '-';
                    final isOwner = c['is_owner'] == 1 || c['is_owner'] == true;
                    final role = isOwner ? 'Penanggung Jawab (Owner)' : 'Guru BK Anggota';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: AppColors.lightRed,
                            child: Text(
                              name.isNotEmpty ? name[0].toUpperCase() : 'G',
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'NIP: $nip • $role',
                                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
