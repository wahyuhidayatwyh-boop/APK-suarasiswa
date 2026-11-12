import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:suara_siswa/core/constants/app_colors.dart';
import 'package:suara_siswa/core/constants/api_endpoints.dart';
import 'package:suara_siswa/features/auth/presentation/auth_controller.dart';
import 'package:suara_siswa/features/education/data/content_repository.dart';
import 'package:suara_siswa/shared/models/content_model.dart';
import 'package:suara_siswa/shared/widgets/app_button.dart';
import 'package:suara_siswa/shared/widgets/app_text_field.dart';
import 'package:suara_siswa/shared/widgets/empty_state_view.dart';

class CounselorContentScreen extends ConsumerStatefulWidget {
  const CounselorContentScreen({super.key});

  @override
  ConsumerState<CounselorContentScreen> createState() =>
      _CounselorContentScreenState();
}

class _CounselorContentScreenState extends ConsumerState<CounselorContentScreen> {
  ContentType? _selectedTypeFilter;

  void _showAddContentSheet(BuildContext context) {
    final titleController = TextEditingController();
    final shortDescController = TextEditingController();
    final bodyController = TextEditingController();
    final stepsController = TextEditingController();
    ContentType selectedType = ContentType.education;
    ContentStatus selectedStatus = ContentStatus.published;
    String? imageUrl;
    bool isUploadingImage = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
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
                    const Text(
                      'Tambah Konten / Materi Edukasi',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 16),
                    // Type selector
                    const Text('Jenis Konten *',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<ContentType>(
                          isExpanded: true,
                          value: selectedType,
                          items: ContentType.values.map((t) {
                            return DropdownMenuItem(
                              value: t,
                              child: Text(t.label, style: const TextStyle(fontSize: 13)),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setSheetState(() => selectedType = val);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    AppTextField(
                      label: 'Judul Konten *',
                      hint: 'misal: Panduan Menghadapi Cyberbullying',
                      controller: titleController,
                    ),
                    const SizedBox(height: 14),

                    AppTextField(
                      label: 'Deskripsi Singkat / Ringkasan *',
                      hint: 'Ringkasan 1-2 kalimat yang tampil pada kartu banner',
                      controller: shortDescController,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 14),

                    AppTextField(
                      label: 'Isi Lengkap Artikel',
                      hint: 'Tuliskan panduan, artikel edukasi, atau detail pengumuman...',
                      controller: bodyController,
                      maxLines: 4,
                    ),
                    const SizedBox(height: 14),

                    AppTextField(
                      label: 'Langkah / Panduan Tambahan (Opsional)',
                      hint: '1. Tetap tenang\n2. Tangkap layar bukti\n3. Lapor ke Guru BK',
                      controller: stepsController,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 14),

                    // Image Upload & Preview Section
                    const Text('Cover / Banner Gambar',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    if (imageUrl != null) ...[
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.network(
                              imageUrl!,
                              width: double.infinity,
                              height: 140,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: GestureDetector(
                              onTap: () => setSheetState(() => imageUrl = null),
                              child: Container(
                                padding: const EdgeInsets.all(5),
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close_rounded,
                                    color: Colors.white, size: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                    ],
                    OutlinedButton.icon(
                      onPressed: isUploadingImage
                          ? null
                          : () async {
                              final image = await ImagePicker().pickImage(
                                source: ImageSource.gallery,
                                imageQuality: 80,
                              );
                              if (image == null) return;
                              setSheetState(() => isUploadingImage = true);
                              try {
                                final bytes = await image.readAsBytes();
                                final result = await ref
                                    .read(apiClientProvider)
                                    .uploadBytes(ApiEndpoints.uploads, bytes, fileName: image.name);
                                if (!context.mounted) return;
                                final url = result.data?['url'] as String?;
                                if (result.success && url != null) {
                                  setSheetState(() {
                                    isUploadingImage = false;
                                    imageUrl = url.startsWith('http')
                                        ? url
                                        : '${ApiEndpoints.baseUrl}$url';
                                  });
                                } else {
                                  setSheetState(() => isUploadingImage = false);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(result.error?.message ??
                                            'Upload gambar gagal.')),
                                  );
                                }
                              } catch (e) {
                                setSheetState(() => isUploadingImage = false);
                              }
                            },
                      icon: isUploadingImage
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.image_outlined),
                      label: Text(imageUrl == null
                          ? 'Pilih Gambar Cover/Banner'
                          : 'Ganti Gambar'),
                    ),
                    const SizedBox(height: 14),

                    // Status (Draft vs Published)
                    Row(
                      children: [
                        const Text('Status: ',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        ChoiceChip(
                          label: const Text('Langsung Terbitkan'),
                          selected: selectedStatus == ContentStatus.published,
                          onSelected: (_) => setSheetState(
                              () => selectedStatus = ContentStatus.published),
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('Simpan Draft'),
                          selected: selectedStatus == ContentStatus.draft,
                          onSelected: (_) =>
                              setSheetState(() => selectedStatus = ContentStatus.draft),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: () {
                              if (titleController.text.trim().isEmpty) return;
                              showDialog(
                                context: context,
                                builder: (dlgCtx) => AlertDialog(
                                  title: Text(titleController.text.trim()),
                                  content: SingleChildScrollView(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (imageUrl != null)
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: Image.network(imageUrl!, height: 120, width: double.infinity, fit: BoxFit.cover),
                                          ),
                                        const SizedBox(height: 8),
                                        Text(shortDescController.text.trim(), style: const TextStyle(fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 8),
                                        Text(bodyController.text.trim()),
                                        if (stepsController.text.trim().isNotEmpty) ...[
                                          const SizedBox(height: 8),
                                          const Text('Panduan / Langkah:', style: TextStyle(fontWeight: FontWeight.bold)),
                                          Text(stepsController.text.trim()),
                                        ],
                                      ],
                                    ),
                                  ),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(dlgCtx), child: const Text('Tutup')),
                                  ],
                                ),
                              );
                            },
                            child: const Text('Pratinjau'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: AppButton(
                            text: 'Simpan ke Server',
                            onPressed: () async {
                              final title = titleController.text.trim();
                              final shortDesc = shortDescController.text.trim();
                              if (title.isEmpty || shortDesc.isEmpty) return;

                              Navigator.pop(ctx);

                              String fullBody = bodyController.text.trim();
                              if (stepsController.text.trim().isNotEmpty) {
                                fullBody = '$fullBody\n\n### Langkah & Panduan:\n${stepsController.text.trim()}';
                              }

                              await ref.read(contentRepositoryProvider).createContent(
                                    type: selectedType,
                                    title: title,
                                    shortDescription: shortDesc,
                                    body: fullBody.isEmpty ? null : fullBody,
                                    imageUrl: imageUrl,
                                    status: selectedStatus,
                                  );
                              setState(() {});
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showEditContentSheet(BuildContext context, ContentModel item) {
    final titleController = TextEditingController(text: item.title);
    final shortDescController = TextEditingController(text: item.shortDescription);

    String mainBody = item.body ?? '';
    String stepsPart = '';
    if (mainBody.contains('### Langkah & Panduan:')) {
      final parts = mainBody.split('### Langkah & Panduan:');
      mainBody = parts[0].trim();
      if (parts.length > 1) {
        stepsPart = parts[1].trim();
      }
    }

    final bodyController = TextEditingController(text: mainBody);
    final stepsController = TextEditingController(text: stepsPart);
    ContentType selectedType = item.type;
    ContentStatus selectedStatus = item.status;
    String? imageUrl = item.imageUrl;
    bool isUploadingImage = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
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
                    const Text(
                      'Edit Konten / Materi Edukasi',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 16),
                    // Type selector
                    const Text('Jenis Konten *',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<ContentType>(
                          isExpanded: true,
                          value: selectedType,
                          items: ContentType.values.map((t) {
                            return DropdownMenuItem(
                              value: t,
                              child: Text(t.label, style: const TextStyle(fontSize: 13)),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setSheetState(() => selectedType = val);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    AppTextField(
                      label: 'Judul Konten *',
                      hint: 'misal: Panduan Menghadapi Cyberbullying',
                      controller: titleController,
                    ),
                    const SizedBox(height: 14),

                    AppTextField(
                      label: 'Deskripsi Singkat / Ringkasan *',
                      hint: 'Ringkasan 1-2 kalimat yang tampil pada kartu banner',
                      controller: shortDescController,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 14),

                    AppTextField(
                      label: 'Isi Lengkap Artikel',
                      hint: 'Tuliskan panduan, artikel edukasi, atau detail pengumuman...',
                      controller: bodyController,
                      maxLines: 4,
                    ),
                    const SizedBox(height: 14),

                    AppTextField(
                      label: 'Langkah / Panduan Tambahan (Opsional)',
                      hint: '1. Tetap tenang\n2. Tangkap layar bukti\n3. Lapor ke Guru BK',
                      controller: stepsController,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 14),

                    // Image Upload & Preview Section
                    const Text('Cover / Banner Gambar',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    if (imageUrl != null && imageUrl!.isNotEmpty) ...[
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.network(
                              imageUrl!,
                              width: double.infinity,
                              height: 140,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                height: 140,
                                color: Colors.grey.shade200,
                                child: const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: GestureDetector(
                              onTap: () => setSheetState(() => imageUrl = null),
                              child: Container(
                                padding: const EdgeInsets.all(5),
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close_rounded,
                                    color: Colors.white, size: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                    ],
                    OutlinedButton.icon(
                      onPressed: isUploadingImage
                          ? null
                          : () async {
                              final image = await ImagePicker().pickImage(
                                source: ImageSource.gallery,
                                imageQuality: 80,
                              );
                              if (image == null) return;
                              setSheetState(() => isUploadingImage = true);
                              try {
                                final bytes = await image.readAsBytes();
                                final result = await ref
                                    .read(apiClientProvider)
                                    .uploadBytes(ApiEndpoints.uploads, bytes, fileName: image.name);
                                if (!context.mounted) return;
                                final url = result.data?['url'] as String?;
                                if (result.success && url != null) {
                                  setSheetState(() {
                                    isUploadingImage = false;
                                    imageUrl = url.startsWith('http')
                                        ? url
                                        : '${ApiEndpoints.baseUrl}$url';
                                  });
                                } else {
                                  setSheetState(() => isUploadingImage = false);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(result.error?.message ??
                                            'Upload gambar gagal.')),
                                  );
                                }
                              } catch (e) {
                                setSheetState(() => isUploadingImage = false);
                              }
                            },
                      icon: isUploadingImage
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.image_outlined),
                      label: Text(imageUrl == null
                          ? 'Pilih Gambar Cover/Banner'
                          : 'Ganti Gambar'),
                    ),
                    const SizedBox(height: 14),

                    // Status (Draft vs Published)
                    Row(
                      children: [
                        const Text('Status: ',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        ChoiceChip(
                          label: const Text('Terbitkan'),
                          selected: selectedStatus == ContentStatus.published,
                          onSelected: (_) => setSheetState(
                              () => selectedStatus = ContentStatus.published),
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('Draft'),
                          selected: selectedStatus == ContentStatus.draft,
                          onSelected: (_) =>
                              setSheetState(() => selectedStatus = ContentStatus.draft),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Batal'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: AppButton(
                            text: 'Simpan Perubahan',
                            onPressed: () async {
                              final title = titleController.text.trim();
                              final shortDesc = shortDescController.text.trim();
                              if (title.isEmpty || shortDesc.isEmpty) return;

                              Navigator.pop(ctx);

                              String fullBody = bodyController.text.trim();
                              if (stepsController.text.trim().isNotEmpty) {
                                fullBody = '$fullBody\n\n### Langkah & Panduan:\n${stepsController.text.trim()}';
                              }

                              final res = await ref.read(contentRepositoryProvider).updateContent(
                                    id: item.id,
                                    title: title,
                                    shortDescription: shortDesc,
                                    body: fullBody.isEmpty ? null : fullBody,
                                    imageUrl: imageUrl,
                                  );

                              if (item.status != selectedStatus) {
                                await ref.read(contentRepositoryProvider).updateStatus(
                                      id: item.id,
                                      status: selectedStatus,
                                    );
                              }

                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(res.success
                                        ? 'Konten berhasil diperbarui.'
                                        : 'Gagal memperbarui konten: ${res.error?.message}'),
                                    backgroundColor: res.success ? AppColors.success : AppColors.error,
                                  ),
                                );
                              }
                              setState(() {});
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _confirmDeleteContent(BuildContext context, ContentModel item) {
    showDialog(
      context: context,
      builder: (dlgCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 24),
            SizedBox(width: 8),
            Expanded(child: Text('Hapus Konten?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
          ],
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus materi "${item.title}"? Tindakan ini akan menghapus materi dari remote database.',
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
              final res = await ref.read(contentRepositoryProvider).deleteContent(item.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(res.success ? 'Konten berhasil dihapus.' : 'Gagal menghapus konten.'),
                    backgroundColor: res.success ? AppColors.success : AppColors.error,
                  ),
                );
              }
              setState(() {});
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final contentRepo = ref.watch(contentRepositoryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Kelola Konten & Edukasi'),
      ),
      body: Column(
        children: [
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _buildFilterChip(null, 'Semua Konten'),
                const SizedBox(width: 8),
                _buildFilterChip(ContentType.education, 'Materi Edukasi'),
                const SizedBox(width: 8),
                _buildFilterChip(ContentType.banner, 'Banner'),
                const SizedBox(width: 8),
                _buildFilterChip(ContentType.announcement, 'Pengumuman'),
                const SizedBox(width: 8),
                _buildFilterChip(ContentType.counseling, 'Tips BK'),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),

          // Content List
          Expanded(
            child: FutureBuilder(
              future: contentRepo.getContents(type: _selectedTypeFilter),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                }

                final contents = snapshot.data?.data ?? [];

                if (contents.isEmpty) {
                  return EmptyStateView(
                    icon: Icons.article_outlined,
                    title: 'Belum Ada Konten',
                    description: 'Tambahkan materi edukasi, banner, atau pengumuman untuk siswa sekolah Anda.',
                    buttonText: 'Tambah Konten Pertama',
                    onButtonPressed: () => _showAddContentSheet(context),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: contents.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = contents[index];

                    return InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => _showEditContentSheet(context, item),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.lightRed,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    item.type.label,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                                Row(
                                  children: [
                                    Text(
                                      item.status.label,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: item.status == ContentStatus.published
                                            ? AppColors.success
                                            : AppColors.warning,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    InkWell(
                                      onTap: () => _showEditContentSheet(context, item),
                                      child: const Icon(Icons.edit_outlined,
                                          size: 18, color: AppColors.primary),
                                    ),
                                    const SizedBox(width: 8),
                                    InkWell(
                                      onTap: () => _confirmDeleteContent(context, item),
                                      child: const Icon(Icons.delete_outline,
                                          size: 18, color: AppColors.error),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            if (item.imageUrl != null && item.imageUrl!.isNotEmpty) ...[
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.network(
                                  item.imageUrl!,
                                  height: 110,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                                ),
                              ),
                              const SizedBox(height: 10),
                            ],
                            Text(
                              item.title,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.shortDescription,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: () => _showAddContentSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('Tambah Konten'),
      ),
    );
  }

  Widget _buildFilterChip(ContentType? type, String label) {
    final isSelected = _selectedTypeFilter == type;
    return InkWell(
      onTap: () => setState(() => _selectedTypeFilter = type),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

