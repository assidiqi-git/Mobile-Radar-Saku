import 'package:flutter/material.dart';

import '../../core/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../dashboard/dashboard_screen.dart';
import '../summary/summary_screen.dart';
import '../transaction/all_transactions_screen.dart';
import '../profile/profile_sync_screen.dart';

class MainShellScreen extends StatefulWidget {
  const MainShellScreen({super.key});

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  final PageController _pageController = PageController();
  int _currentTab = 0;

  // Swipe gesture tracking
  double _dragStartX = 0;
  double _dragStartY = 0;

  static const _swipeThreshold = 60.0;

  final List<Widget> _pages = const [
    DashboardScreen(),
    SummaryScreen(),
    AllTransactionsScreen(),
    ProfileSyncScreen(),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabTap(int index) {
    setState(() => _currentTab = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _onPageChanged(int index) {
    setState(() => _currentTab = index);
  }

  void _onHorizontalDragStart(DragStartDetails details) {
    _dragStartX = details.globalPosition.dx;
    _dragStartY = details.globalPosition.dy;
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    final dx = details.globalPosition.dx - _dragStartX;
    final dy = details.globalPosition.dy - _dragStartY;

    // Hanya proses jika horizontal lebih dominan dari vertikal
    if (dx.abs() < _swipeThreshold || dy.abs() > dx.abs() * 0.75) return;

    if (dx < 0 && _currentTab < _pages.length - 1) {
      // Swipe kiri → halaman berikutnya
      _onTabTap(_currentTab + 1);
    } else if (dx > 0 && _currentTab > 0) {
      // Swipe kanan → halaman sebelumnya
      _onTabTap(_currentTab - 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragStart: _onHorizontalDragStart,
      onHorizontalDragEnd: _onHorizontalDragEnd,
      child: Scaffold(
        backgroundColor: AppTheme.surface,
        body: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          onPageChanged: _onPageChanged,
          children: _pages,
        ),
        bottomNavigationBar: BottomNavigationBar(
          // Konversi page index → nav item index (skip FAB gap di posisi 2)
          // Page 0,1 → Nav 0,1 | Page 2,3 → Nav 3,4
          currentIndex: _currentTab < 2 ? _currentTab : _currentTab + 1,
          type: BottomNavigationBarType.fixed,
          onTap: (index) {
            if (index == 2) return; // FAB gap — no-op
            // Konversi nav item index → page index
            // Nav 0,1 → Page 0,1 | Nav 3,4 → Page 2,3
            final pageIndex = index > 2 ? index - 1 : index;
            _onTabTap(pageIndex);
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_rounded),
              label: 'Beranda',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_rounded),
              label: 'Summary',
            ),
            BottomNavigationBarItem(
              icon: Icon(null), // FAB gap
              label: '',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_rounded),
              label: 'Transaksi',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              label: 'Profil',
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () =>
              Navigator.pushNamed(context, AppRouter.addTransaction),
          child: const Icon(Icons.receipt_long_rounded),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      ),
    );
  }
}
