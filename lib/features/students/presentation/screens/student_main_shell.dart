import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:suara_siswa/features/chat/presentation/screens/chat_list_screen.dart';
import 'package:suara_siswa/features/profile/presentation/screens/profile_screen.dart';
import 'package:suara_siswa/features/reports/presentation/screens/create_report_screen.dart';
import 'package:suara_siswa/features/reports/presentation/screens/report_list_screen.dart';
import 'package:suara_siswa/features/students/presentation/screens/student_home_screen.dart';
import 'package:suara_siswa/shared/widgets/floating_bottom_bar.dart';

class StudentMainShell extends ConsumerStatefulWidget {
  const StudentMainShell({super.key});

  @override
  ConsumerState<StudentMainShell> createState() => _StudentMainShellState();
}

class _StudentMainShellState extends ConsumerState<StudentMainShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const StudentHomeScreen(),
    const ReportListScreen(isCounselor: false),
    const CreateReportScreen(),
    const ChatListScreen(isCounselor: false),
    const ProfileScreen(isCounselor: false),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: FloatingBottomBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          FloatingBottomNavItem(
            icon: Icons.home_outlined,
            activeIcon: Icons.home_rounded,
            label: 'Beranda',
          ),
          FloatingBottomNavItem(
            icon: Icons.receipt_long_outlined,
            activeIcon: Icons.receipt_long_rounded,
            label: 'Riwayat',
          ),
          FloatingBottomNavItem(
            icon: Icons.campaign_outlined,
            activeIcon: Icons.campaign_rounded,
            label: 'Laporan',
            isCenter: true,
          ),
          FloatingBottomNavItem(
            icon: Icons.chat_bubble_outline_rounded,
            activeIcon: Icons.chat_bubble_rounded,
            label: 'Pesan',
          ),
          FloatingBottomNavItem(
            icon: Icons.person_outline_rounded,
            activeIcon: Icons.person_rounded,
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
