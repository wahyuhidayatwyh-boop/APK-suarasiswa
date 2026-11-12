import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/api_response.dart';
import '../../../../shared/models/report_model.dart';
import '../../../../shared/utils/date_formatter.dart';
import '../../../auth/presentation/auth_controller.dart';
import '../../../reports/data/report_repository.dart';

class ReportChatScreen extends ConsumerStatefulWidget {
  final String reportId;

  const ReportChatScreen({super.key, required this.reportId});

  @override
  ConsumerState<ReportChatScreen> createState() => _ReportChatScreenState();
}

class _ReportChatScreenState extends ConsumerState<ReportChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;
  bool _isUploadingPhoto = false;
  String? _selectedPhotoUrl;
  late Future<ApiResponse<List<ReportMessageModel>>> _messagesFuture;

  @override
  void initState() {
    super.initState();
    _refreshMessages();
  }

  void _refreshMessages() {
    setState(() {
      _messagesFuture =
          ref.read(reportRepositoryProvider).getMessages(widget.reportId);
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(ImageSource source) async {
    Navigator.of(context).pop(); // Dismiss bottom sheet
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      imageQuality: 70,
      maxWidth: 1200,
    );

    if (picked == null || !mounted) return;

    setState(() => _isUploadingPhoto = true);
    try {
      final bytes = await picked.readAsBytes();
      final res = await ref.read(apiClientProvider).uploadBytes(
            ApiEndpoints.uploads,
            bytes,
            fileName: picked.name,
          );

      if (!mounted) return;
      setState(() => _isUploadingPhoto = false);

      final relUrl = res.data?['url'] as String?;
      if (res.success && relUrl != null) {
        final fullUrl = relUrl.startsWith('http')
            ? relUrl
            : '${ApiEndpoints.baseUrl}$relUrl';
        setState(() => _selectedPhotoUrl = fullUrl);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res.error?.message ?? 'Gagal mengunggah foto.'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingPhoto = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terjadi kendala saat memproses foto: $e'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    }
  }

  void _showAttachmentPicker() {
    showModalBottomSheet(
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
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.slate300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Kirim Foto / Bukti ke Percakapan',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.slate900,
                ),
              ),
              const SizedBox(height: 14),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.camera_alt_rounded,
                      color: Color(0xFF2563EB)),
                ),
                title: const Text('Ambil Foto dari Kamera',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: const Text('Gunakan kamera langsung untuk bukti nyata',
                    style: TextStyle(fontSize: 11.5, color: AppColors.slate500)),
                onTap: () => _pickPhoto(ImageSource.camera),
              ),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.photo_library_rounded,
                      color: AppColors.primary),
                ),
                title: const Text('Pilih dari Galeri',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: const Text('Pilih screenshot atau foto yang tersimpan',
                    style: TextStyle(fontSize: 11.5, color: AppColors.slate500)),
                onTap: () => _pickPhoto(ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleSend() async {
    final text = _messageController.text.trim();
    final photo = _selectedPhotoUrl;

    if ((text.isEmpty && photo == null) || _isSending) return;

    _messageController.clear();
    setState(() {
      _isSending = true;
      _selectedPhotoUrl = null;
    });

    await ref.read(reportRepositoryProvider).sendMessage(
          reportId: widget.reportId,
          message: text.isNotEmpty ? text : 'Mengirim lampiran foto.',
          attachmentUrl: photo,
        );

    _refreshMessages();
    setState(() => _isSending = false);

    // Scroll to bottom smoothly
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showImageZoom(String url) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                url,
                fit: BoxFit.contain,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded,
                  color: Colors.white, size: 28),
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Chat Privat Konseling',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.slate900,
              ),
            ),
            Text(
              'Laporan ID: ${widget.reportId}',
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.slate500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.slate700),
            tooltip: 'Segarkan Pesan',
            onPressed: _refreshMessages,
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
        ),
      ),
      body: Column(
        children: [
          // Security / Privacy notice banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: const Color(0xFFFEF2F2),
            child: const Row(
              children: [
                Icon(Icons.lock_rounded, size: 14, color: AppColors.primary),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Pesan terenkripsi dan hanya dapat dibaca oleh Anda & Guru BK.',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.darkRed,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Messages list
          Expanded(
            child: FutureBuilder(
              future: _messagesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                      strokeWidth: 2.5,
                    ),
                  );
                }

                final messages = snapshot.data?.data ?? [];

                if (messages.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.chat_bubble_outline_rounded,
                              size: 32,
                              color: Color(0xFF2563EB),
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Belum Ada Pesan',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.slate800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Kirimkan pesan atau pertanyaan untuk memulai percakapan.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.slate500,
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];

                    // Chat Messenger Alignment Rule:
                    // Di akun masing-masing:
                    // Pesan milik sendiri -> KANAN (isMe = true)
                    // Pesan yang diterima (lawan bicara) -> KIRI (isMe = false)
                    bool isMe = false;
                    if (authState.isCounselor) {
                      // Akun Guru BK: pesan dari Guru BK di kanan, pesan siswa di kiri
                      isMe = (msg.senderRole == 'COUNSELOR');
                    } else {
                      // Akun Siswa: pesan dari Siswa di kanan, pesan Guru BK di kiri
                      isMe = (msg.senderRole == 'STUDENT');
                    }

                    final hasPhoto = msg.attachmentUrl != null &&
                        msg.attachmentUrl!.isNotEmpty;

                    final showDateDivider = index == 0 ||
                        !AppDateFormatter.isSameDay(
                            messages[index - 1].createdAt, msg.createdAt);

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (showDateDivider)
                          Center(
                            child: Container(
                              margin: const EdgeInsets.only(top: 4, bottom: 12),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE2E8F0).withOpacity(0.7),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                AppDateFormatter.formatDatePill(msg.createdAt),
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.slate600,
                                ),
                              ),
                            ),
                          ),
                        Align(
                          alignment:
                              isMe ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.76,
                            ),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: isMe ? AppColors.primaryGradient : null,
                              color: isMe ? null : Colors.white,
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(18),
                                topRight: const Radius.circular(18),
                                bottomLeft: Radius.circular(isMe ? 18 : 4),
                                bottomRight: Radius.circular(isMe ? 4 : 18),
                              ),
                              border: isMe
                                  ? null
                                  : Border.all(color: const Color(0xFFE2E8F0)),
                              boxShadow: [
                                BoxShadow(
                                  color: isMe
                                      ? const Color(0xFFDC2626).withOpacity(0.18)
                                      : Colors.black.withOpacity(0.04),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: isMe
                                  ? CrossAxisAlignment.end
                                  : CrossAxisAlignment.start,
                              children: [
                                // Sender info row
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        msg.senderName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: isMe
                                              ? Colors.white.withOpacity(0.9)
                                              : AppColors.slate700,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 1.5),
                                      decoration: BoxDecoration(
                                        color: isMe
                                            ? Colors.white.withOpacity(0.2)
                                            : const Color(0xFFEFF6FF),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        msg.senderRole == 'COUNSELOR'
                                            ? 'Guru BK'
                                            : 'Siswa',
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w700,
                                          color: isMe
                                              ? Colors.white
                                              : const Color(0xFF2563EB),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),

                                // Photo Attachment if any
                                if (hasPhoto) ...[
                                  GestureDetector(
                                    onTap: () => _showImageZoom(msg.attachmentUrl!),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                        msg.attachmentUrl!,
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        height: 160,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                Container(
                                          height: 80,
                                          color: isMe
                                              ? Colors.white12
                                              : const Color(0xFFF1F5F9),
                                          child: const Center(
                                            child: Icon(Icons.broken_image_rounded,
                                                color: Colors.white70),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                ],

                                // Message text with word wrapping
                                if (msg.message.isNotEmpty &&
                                    !(hasPhoto &&
                                        msg.message == 'Mengirim lampiran foto.'))
                                  Text(
                                    msg.message,
                                    softWrap: true,
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      color: isMe ? Colors.white : AppColors.slate900,
                                      height: 1.45,
                                    ),
                                  ),
                                const SizedBox(height: 4),

                                // Time timestamp
                                Text(
                                  '${AppDateFormatter.formatTime(msg.createdAt)} ${AppDateFormatter.localTimeZoneLabel}',
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w500,
                                    color: isMe
                                        ? Colors.white70
                                        : AppColors.slate400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),

          // Uploading photo preview indicator if active
          if (_isUploadingPhoto)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: const Color(0xFFEFF6FF),
              child: const Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Mengunggah foto...',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E40AF),
                    ),
                  ),
                ],
              ),
            ),

          // Photo preview before sending
          if (_selectedPhotoUrl != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.white,
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      _selectedPhotoUrl!,
                      width: 52,
                      height: 52,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Foto siap dikirim dengan pesan',
                      style: TextStyle(fontSize: 12, color: AppColors.slate600),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded,
                        color: AppColors.primary, size: 20),
                    onPressed: () => setState(() => _selectedPhotoUrl = null),
                  ),
                ],
              ),
            ),

          // Message Input Field
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  // Photo picker button
                  IconButton(
                    onPressed: _isSending ? null : _showAttachmentPicker,
                    icon: const Icon(Icons.camera_alt_outlined,
                        color: AppColors.primary, size: 24),
                    tooltip: 'Kirim Foto / Kamera',
                  ),

                  // Text input
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        controller: _messageController,
                        decoration: const InputDecoration(
                          hintText: 'Tulis pesan rahasia...',
                          hintStyle: TextStyle(
                              color: AppColors.slate400, fontSize: 13),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 10),
                        ),
                        onSubmitted: (_) => _handleSend(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Send button
                  InkWell(
                    onTap: _isSending ? null : _handleSend,
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: _isSending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send_rounded,
                              size: 18, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
