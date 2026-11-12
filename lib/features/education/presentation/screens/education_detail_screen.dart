import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:suara_siswa/core/constants/app_colors.dart';
import 'package:suara_siswa/features/education/data/content_repository.dart';
import 'package:suara_siswa/shared/models/content_model.dart';

class EducationDetailScreen extends ConsumerWidget {
  final String contentId;

  const EducationDetailScreen({super.key, required this.contentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contentRepo = ref.watch(contentRepositoryProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Materi Edukasi'),
      ),
      body: FutureBuilder(
        future: contentRepo.getContentDetail(contentId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          final content = snapshot.data?.data;
          if (content == null) {
            return const Center(child: Text('Materi tidak ditemukan.'));
          }

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Banner / Cover Image
                  if (content.imageUrl != null && content.imageUrl!.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: double.infinity,
                        height: 160,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Image.network(
                          content.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _buildFallbackBanner(content),
                        ),
                      ),
                    )
                  else
                    _buildFallbackBanner(content),
                  const SizedBox(height: 12),

                  // Tag & Date
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          content.type.label,
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Title
                  Text(
                    content.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.3,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Short description lead paragraph
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Text(
                      content.shortDescription,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.slate700,
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Body & Steps
                  Builder(
                    builder: (context) {
                      String mainBody = content.body ?? content.shortDescription;
                      String? stepsText;
                      if (mainBody.contains('### Langkah & Panduan:')) {
                        final parts = mainBody.split('### Langkah & Panduan:');
                        mainBody = parts[0].trim();
                        if (parts.length > 1 && parts[1].trim().isNotEmpty) {
                          stepsText = parts[1].trim();
                        }
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (mainBody.isNotEmpty)
                            Text(
                              mainBody,
                              style: const TextStyle(
                                fontSize: 13.5,
                                color: AppColors.textPrimary,
                                height: 1.5,
                              ),
                            ),
                          if (stepsText != null) ...[
                            const SizedBox(height: 16),
                            const Row(
                              children: [
                                Icon(Icons.format_list_numbered_rounded,
                                    size: 16, color: AppColors.primary),
                                SizedBox(width: 6),
                                Text(
                                  'Langkah & Panduan Praktis',
                                  style: TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.slate900,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            ...stepsText
                                .split('\n')
                                .where((l) => l.trim().isNotEmpty)
                                .map((stepLine) {
                              final trimmed = stepLine.trim();
                              // Extract number if starts with digit
                              final match = RegExp(r'^(\d+)[\.\)]\s*(.*)$').firstMatch(trimmed);
                              final stepNumber = match?.group(1);
                              final stepContent = match?.group(2) ?? trimmed;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.02),
                                      blurRadius: 4,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          stepNumber ?? '•',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        stepContent,
                                        style: const TextStyle(
                                          fontSize: 12.5,
                                          color: AppColors.slate800,
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFallbackBanner(ContentModel content) {
    return Container(
      width: double.infinity,
      height: 140,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.menu_book_rounded,
                size: 36,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              content.type.label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
