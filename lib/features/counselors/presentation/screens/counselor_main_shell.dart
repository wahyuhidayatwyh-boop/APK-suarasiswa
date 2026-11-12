import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:suara_siswa/features/chat/presentation/screens/chat_list_screen.dart';
import 'package:suara_siswa/features/classes/presentation/screens/counselor_classes_screen.dart';
import 'package:suara_siswa/features/profile/presentation/screens/profile_screen.dart';
import 'package:suara_siswa/features/reports/presentation/screens/report_list_screen.dart';
import 'package:suara_siswa/shared/widgets/floating_bottom_bar.dart';
import 'counselor_dashboard_screen.dart';

class CounselorMainShell extends ConsumerStatefulWidget {
  const CounselorMainShell({super.key});

  @override
  ConsumerState<CounselorMainShell> createState() => _CounselorMainShellState();
}

class _CounselorMainShellState extends ConsumerState<CounselorMainShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const CounselorDashboardScreen(),
    const CounselorClassesScreen(),
    const ReportListScreen(isCounselor: true),
    const ChatListScreen(isCounselor: true),
    const ProfileScreen(isCounselor: true),
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
            icon: Icons.dashboard_outlined,
            activeIcon: Icons.dashboard_rounded,
            label: 'Dashboard',
          ),
          FloatingBottomNavItem(
            icon: Icons.meeting_room_outlined,
            activeIcon: Icons.meeting_room_rounded,
            label: 'Kelas',
          ),
          FloatingBottomNavItem(
            icon: Icons.assignment_outlined,
            activeIcon: Icons.assignment_rounded,
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
