import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:suara_siswa/core/constants/api_endpoints.dart';
import 'package:suara_siswa/core/constants/app_colors.dart';
import 'package:suara_siswa/features/auth/presentation/auth_controller.dart';
import 'package:suara_siswa/features/reports/data/report_repository.dart';
import 'package:suara_siswa/shared/models/report_model.dart';
import 'package:suara_siswa/shared/utils/date_formatter.dart';
import 'package:suara_siswa/shared/widgets/app_button.dart';
import 'package:suara_siswa/shared/widgets/app_text_field.dart';
import 'package:suara_siswa/shared/widgets/modern_card.dart';

class CreateReportScreen extends ConsumerStatefulWidget {
  final String? initialType;

  const CreateReportScreen({super.key, this.initialType});

  @override
  ConsumerState<CreateReportScreen> createState() => _CreateReportScreenState();
}

class _CreateReportScreenState extends ConsumerState<CreateReportScreen> {
  final _formKey = GlobalKey<FormState>();

  late ReportType _selectedType;
  late String _selectedCategory;
  String _reporterType = 'KORBAN';
  ReportPriority _selectedPriority = ReportPriority.normal;
  DateTime _incidentDate = DateTime.now();

  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final List<String> _attachments = [];
  bool _isSubmitting = false;
  bool _isUploading = false;

  final Map<ReportType, List<String>> _categoriesByType = {
    ReportType.bullying: [
      'Verbal (Ejekan / Julukan)',
      'Fisik (Pukulan / Dorongan)',
      'Cyberbullying (Media Sosial / Chat)',
      'Pengucilan / Diskriminasi Sosial',
      'Pemalakan / Pemerasan',
      'Ancaman / Intimidasi',
      'Lainnya',
    ],
    ReportType.konseling: [
      'Konseling Pribadi / Emosional',
      'Masalah Belajar & Akademik',
      'Hubungan Pertemanan & Sosial',
      'Kecemasan / Masalah Mental',
      'Bimbingan Minat & Karir',
      'Lainnya',
    ],
    ReportType.kritikSaran: [
      'Fasilitas & Sarana Sekolah',
      'Kebersihan & Lingkungan',
      'Kegiatan & Ekstrakurikuler',
      'Pelayanan Pembelajaran',
      'Kantin & Makanan',
      'Lainnya',
    ],
    ReportType.aspirasi: [
      'Ide Kegiatan & Program Siswa',
      'Inovasi Lingkungan Sekolah',
      'Aspirasi Minat & Bakat',
      'Organisasi Siswa (OSIS/MPK)',
      'Lainnya',
    ],
  };

  @override
  void initState() {
    super.initState();
    _selectedType = ReportType.fromString(widget.initialType);
    _selectedCategory = _categoriesByType[_selectedType]!.first;
  }

  @override
  void dispose() {
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _incidentDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _incidentDate = picked);
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final authState = ref.read(authControllerProvider);
    final school = authState.currentSchool;
    if (school == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Kamu belum tergabung dalam sekolah. Silakan gabung sekolah terlebih dahulu.'),
          backgroundColor: AppColors.primary,
        ),
      );
      return;
    }

    final finalLocation = _selectedType == ReportType.aspirasi &&
            _locationController.text.trim().isEmpty
        ? 'Lingkungan Sekolah'
        : _locationController.text.trim();
    final finalReporterType = _selectedType == ReportType.bullying
        ? _reporterType
        : 'PELAPOR';

    setState(() => _isSubmitting = true);
    try {
      final response = await ref.read(reportRepositoryProvider).createReport(
            type: _selectedType,
            category: _selectedCategory,
            description: _descriptionController.text.trim(),
            incidentDate: _incidentDate,
            incidentLocation: finalLocation,
            priority: _selectedPriority,
            reporterType: finalReporterType,
            attachmentUrls: _attachments,
          );

      if (!mounted) return;

      if (response.success && response.data != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Laporan berhasil dikirim dan tersimpan dengan aman di Guru BK.'),
            backgroundColor: Color(0xFF059669),
          ),
        );
        context.pushReplacement('/student/reports/${response.data!.id}');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                response.error?.message ?? 'Gagal mengirimkan laporan pengaduan.'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _showAttachmentSourceDialog({int? replaceIndex}) async {
    if (replaceIndex == null && _attachments.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maksimal 3 foto yang dapat dilampirkan.'),
          backgroundColor: AppColors.primary,
        ),
      );
      return;
    }

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                replaceIndex != null ? 'Ganti Foto' : 'Pilih Sumber Foto',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.slate900,
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded,
                    color: AppColors.primary),
                title: const Text('Galeri Foto',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded,
                    color: Color(0xFF2563EB)),
                title: const Text('Ambil dari Kamera',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
            ],
          ),
        ),
      ),
    );

    if (source != null) {
      await _pickAndUploadImage(source, replaceIndex: replaceIndex);
    }
  }

  Future<void> _pickAndUploadImage(ImageSource source,
      {int? replaceIndex}) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: source,
      imageQuality: 70,
      maxWidth: 1200,
    );
    if (file == null || !mounted) return;

    setState(() => _isUploading = true);
    try {
      final bytes = await file.readAsBytes();
      final response = await ref
          .read(apiClientProvider)
          .uploadBytes(ApiEndpoints.uploads, bytes, fileName: file.name);

      if (!mounted) return;
      setState(() => _isUploading = false);

      final relativeUrl = response.data?['url'] as String?;
      if (response.success && relativeUrl != null) {
        final attachmentUrl = relativeUrl.startsWith('http')
            ? relativeUrl
            : '${ApiEndpoints.baseUrl}$relativeUrl';
        setState(() {
          if (replaceIndex != null && replaceIndex < _attachments.length) {
            _attachments[replaceIndex] = attachmentUrl;
          } else {
            _attachments.add(attachmentUrl);
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto bukti berhasil diunggah ke remote server.'),
            backgroundColor: Color(0xFF059669),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                response.error?.message ?? 'Upload bukti foto gagal.'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan saat memproses gambar: $e'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  void _showImagePreviewDialog(String url, int index) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: const Icon(Icons.close_rounded,
                    color: Colors.white, size: 28),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                url,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Center(
                  child: Icon(Icons.broken_image_rounded,
                      color: Colors.white, size: 48),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.slate900,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.sync_rounded, size: 16),
                  label: const Text('Ganti Foto'),
                  onPressed: () {
                    Navigator.pop(ctx);
                    _showAttachmentSourceDialog(replaceIndex: index);
                  },
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF4444),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.delete_outline_rounded, size: 16),
                  label: const Text('Hapus'),
                  onPressed: () {
                    Navigator.pop(ctx);
                    setState(() => _attachments.removeAt(index));
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Buat Pengaduan & Konseling',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: AppColors.slate900,
          ),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── Privacy Notice Banner ───────────────────────────────────
                ModernCard(
                  variant: ModernCardVariant.flat,
                  borderRadius: 18,
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.security_rounded,
                            color: Color(0xFF059669), size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Kerahasiaan Dijamin Penuh',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Laporan hanya dapat dilihat oleh Guru BK berwenang. Kamu dapat bercerita tanpa rasa khawatir.',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: Color(0xFF475569),
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // ─── 1. Report Type Selector ─────────────────────────────────
                const Text(
                  'Jenis Pengaduan',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.slate900,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: ReportType.values.map((type) {
                    final isSelected = _selectedType == type;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _selectedType = type;
                              _selectedCategory =
                                  _categoriesByType[type]!.first;
                            });
                          },
                          borderRadius: BorderRadius.circular(14),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary
                                    : const Color(0xFFE2E8F0),
                                width: 1.2,
                              ),
                              boxShadow: isSelected
                                  ? AppColors.redCardShadow
                                  : AppColors.elevation1,
                            ),
                            child: Text(
                              type.label.split(' ').first,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.slate700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 18),

                // ─── 2. Category & Form Section in ModernCard ────────────────
                ModernCard(
                  borderRadius: 20,
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category
                      Text(
                        _selectedType == ReportType.bullying
                            ? 'Kategori Bullying *'
                            : _selectedType == ReportType.kritikSaran
                                ? 'Kategori Sarana & Fasilitas *'
                                : _selectedType == ReportType.aspirasi
                                    ? 'Kategori Aspirasi Siswa *'
                                    : 'Topik Konseling & Curhat *',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.slate800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: const Color(0xFFE2E8F0), width: 1),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: _selectedCategory,
                            items: _categoriesByType[_selectedType]!.map((cat) {
                              return DropdownMenuItem(
                                value: cat,
                                child: Text(
                                  cat,
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.slate800,
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedCategory = val);
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Status Pelapor (Hanya untuk Bullying)
                      if (_selectedType == ReportType.bullying) ...[
                        const Text(
                          'Status Pelapor *',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.slate800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _buildRadioChip(
                                  'KORBAN', 'Saya Korban Langsung'),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildRadioChip(
                                  'SAKSI', 'Saya Saksi Kejadian'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Incident Date
                      Text(
                        _selectedType == ReportType.bullying
                            ? 'Tanggal Kejadian *'
                            : _selectedType == ReportType.kritikSaran
                                ? 'Tanggal Masalah Ditemukan *'
                                : _selectedType == ReportType.aspirasi
                                    ? 'Tanggal Aspirasi *'
                                    : 'Tanggal Pengajuan Konseling *',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.slate800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: _pickDate,
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 13),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: const Color(0xFFE2E8F0), width: 1),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                AppDateFormatter.format(_incidentDate,
                                    pattern: 'dd MMMM yyyy'),
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.slate800,
                                ),
                              ),
                              const Icon(Icons.calendar_today_rounded,
                                  size: 16, color: AppColors.primary),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Location (Kecuali Aspirasi)
                      if (_selectedType != ReportType.aspirasi) ...[
                        AppTextField(
                          label: _selectedType == ReportType.bullying
                              ? 'Lokasi Kejadian *'
                              : _selectedType == ReportType.kritikSaran
                                  ? 'Nama / Lokasi Fasilitas *'
                                  : 'Waktu / Tempat Bertemu Nyaman (Opsional)',
                          hint: _selectedType == ReportType.bullying
                              ? 'misal: Kantin, Lapangan, Toilet, Kelas X RPL 1'
                              : _selectedType == ReportType.kritikSaran
                                  ? 'misal: Lab Komputer 2, Toilet Lantai 2, Lapangan Basket'
                                  : 'misal: Ruang BK Saat Jam Istirahat, Sepulang Sekolah',
                          controller: _locationController,
                          validator: (val) {
                            if (_selectedType == ReportType.konseling) {
                              return null;
                            }
                            if (val == null || val.trim().isEmpty) {
                              return 'Lokasi wajib diisi';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Urgency
                      Text(
                        _selectedType == ReportType.bullying
                            ? 'Tingkat Urgensi Penanganan'
                            : _selectedType == ReportType.kritikSaran
                                ? 'Tingkat Kerusakan Fasilitas'
                                : _selectedType == ReportType.aspirasi
                                    ? 'Prioritas Usulan Ide'
                                    : 'Kebutuhan Pendampingan',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.slate800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: ReportPriority.values.map((priority) {
                          final isSelected = _selectedPriority == priority;
                          final color = priority == ReportPriority.urgent
                              ? AppColors.primary
                              : priority == ReportPriority.tinggi
                                  ? const Color(0xFFD97706)
                                  : const Color(0xFF2563EB);

                          return Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 3),
                              child: InkWell(
                                onTap: () => setState(
                                    () => _selectedPriority = priority),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? color
                                        : const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected
                                          ? color
                                          : const Color(0xFFE2E8F0),
                                    ),
                                  ),
                                  child: Text(
                                    priority.label,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: isSelected
                                          ? Colors.white
                                          : AppColors.slate700,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),

                      // Description
                      AppTextField(
                        label: _selectedType == ReportType.bullying
                            ? 'Kronologi Kejadian Bullying *'
                            : _selectedType == ReportType.kritikSaran
                                ? 'Deskripsi Masalah & Usulan Perbaikan *'
                                : _selectedType == ReportType.aspirasi
                                    ? 'Uraian Ide & Manfaat bagi Sekolah *'
                                    : 'Hal yang Ingin Diceritakan / Dicurhatkan *',
                        hint: _selectedType == ReportType.bullying
                            ? 'Ceritakan apa yang terjadi secara jelas, siapa yang terlibat, dan kronologinya...'
                            : _selectedType == ReportType.kritikSaran
                                ? 'Jelaskan fasilitas yang rusak atau kendala yang dihadapi serta usulan solusinya...'
                                : _selectedType == ReportType.aspirasi
                                    ? 'Jelaskan ide kamu serta dampak positif yang diharapkan untuk sekolah...'
                                    : 'Tuliskan secara terbuka apa yang sedang kamu rasakan atau alami...',
                        controller: _descriptionController,
                        maxLines: 4,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Deskripsi wajib diisi';
                          }
                          if (val.trim().length < 15) {
                            return 'Berikan deskripsi yang lebih jelas (minimal 15 karakter)';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ─── 3. Attachments Card ──────────────────────────────────────
                ModernCard(
                  borderRadius: 20,
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Lampiran Bukti Foto (Maksimal 3 Foto)',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.slate900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Pilih dari galeri atau ambil langsung dari kamera (maksimal 3 foto).',
                        style:
                            TextStyle(fontSize: 11.5, color: AppColors.slate500),
                      ),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: (_isUploading || _attachments.length >= 3)
                            ? null
                            : () => _showAttachmentSourceDialog(),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: _attachments.length >= 3
                                  ? const Color(0xFFE2E8F0)
                                  : const Color(0xFFCBD5E1),
                              width: 1.2,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (_isUploading)
                                const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: AppColors.primary),
                                )
                              else ...[
                                Icon(
                                  _attachments.length >= 3
                                      ? Icons.check_circle_outline_rounded
                                      : Icons.add_photo_alternate_outlined,
                                  color: _attachments.length >= 3
                                      ? AppColors.slate400
                                      : AppColors.primary,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _attachments.length >= 3
                                      ? 'Maksimal 3 Foto Terpenuhi'
                                      : 'Tambah Foto (${_attachments.length}/3)',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: _attachments.length >= 3
                                        ? AppColors.slate500
                                        : AppColors.primary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      if (_attachments.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: List.generate(_attachments.length, (idx) {
                            final url = _attachments[idx];
                            return Stack(
                              clipBehavior: Clip.none,
                              children: [
                                GestureDetector(
                                  onTap: () => _showImagePreviewDialog(url, idx),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(14),
                                    child: Container(
                                      width: 88,
                                      height: 88,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF1F5F9),
                                        borderRadius:
                                            BorderRadius.circular(14),
                                        border: Border.all(
                                            color: const Color(0xFFCBD5E1)),
                                      ),
                                      child: Image.network(
                                        url,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                const Center(
                                          child: Icon(Icons.broken_image_rounded,
                                              color: AppColors.slate400),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: -6,
                                  right: -6,
                                  child: GestureDetector(
                                    onTap: () => setState(
                                        () => _attachments.removeAt(idx)),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: AppColors.primary,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.close_rounded,
                                          size: 13, color: Colors.white),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 4,
                                  left: 4,
                                  right: 4,
                                  child: GestureDetector(
                                    onTap: () => _showAttachmentSourceDialog(
                                        replaceIndex: idx),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.6),
                                        borderRadius:
                                            BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        'Ganti',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ─── 4. Submit Button (Modern 3D Pill Button) ─────────────────
                AppButton(
                  text: 'Kirim Laporan ke Guru BK',
                  icon: const Icon(Icons.send_rounded,
                      size: 18, color: Colors.white),
                  isLoading: _isSubmitting,
                  height: 52,
                  borderRadius: 26,
                  onPressed: _handleSubmit,
                ),

                // Spacing to keep content cleanly above the floating bottom navigation bar
                const SizedBox(height: 96),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRadioChip(String value, String label) {
    final isSelected = _reporterType == value;
    return InkWell(
      onTap: () => setState(() => _reporterType = value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF2563EB)
                : const Color(0xFFE2E8F0),
            width: isSelected ? 1.4 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_off,
              size: 15,
              color: isSelected
                  ? const Color(0xFF2563EB)
                  : const Color(0xFF94A3B8),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? const Color(0xFF1E40AF)
                      : AppColors.slate700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
