import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

import '../core/constants/app_constants.dart';
import '../core/theme/app_theme.dart';
import '../screens/profile/profile_sync_screen.dart';
import '../screens/shell/main_shell.dart';
import '../screens/summary/summary_screen.dart';
import '../screens/transaction/all_transactions_screen.dart';

/// Service yang mengelola seluruh logika Tutorial Coach Mark.
///
/// Cara penggunaan:
/// ```dart
/// if (await CoachMarkService.shouldShowTutorial()) {
///   await CoachMarkService.markTutorialSeen();
///   CoachMarkService.show(context: context, keys: ...);
/// }
/// ```
class CoachMarkService {
  CoachMarkService._();

  /// Kembalikan [true] jika tutorial belum pernah ditampilkan ke user ini.
  static Future<bool> shouldShowTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(AppConstants.hasSeenTutorialKey) ?? false);
  }

  /// Tandai tutorial sudah ditampilkan sehingga tidak muncul lagi.
  static Future<void> markTutorialSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.hasSeenTutorialKey, true);
  }

  /// **DEVELOPMENT ONLY** — Reset flag tutorial agar coach mark tampil lagi.
  ///
  /// Panggil di `main()` sebelum `runApp()`:
  /// ```dart
  /// if (kDebugMode) await CoachMarkService.resetForDebug();
  /// ```
  /// Atau uncomment sementara, jalankan app, lalu comment lagi.
  static Future<void> resetForDebug() async {
    assert(() {
      // Hanya boleh dipanggil di debug mode
      return true;
    }());
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.hasSeenTutorialKey);
    // ignore: avoid_print
    debugPrint('[CoachMark] Tutorial flag reset — akan tampil saat buka dashboard.');
  }

  /// Tampilkan coach mark dengan [context] dan [GlobalKey] yang dipasang
  /// di widget-widget yang ingin di-highlight.
  static void show({
    required BuildContext context,
    required GlobalKey keyBalanceCard,
    required GlobalKey keyWalletsSection,
    required GlobalKey keyRecentActivity,
    required GlobalKey keyFab,
    required GlobalKey keyNavDashboard,
    required GlobalKey keyNavSummary,
    required GlobalKey keyNavTransaksi,
    required GlobalKey keyNavProfil,
    required PageController balancePageController,
  }) {
    final targets = _buildTargets(
      keyBalanceCard: keyBalanceCard,
      keyWalletsSection: keyWalletsSection,
      keyRecentActivity: keyRecentActivity,
      keyFab: keyFab,
      keyNavDashboard: keyNavDashboard,
      keyNavSummary: keyNavSummary,
      keyNavTransaksi: keyNavTransaksi,
      keyNavProfil: keyNavProfil,
    );

    TutorialCoachMark(
      targets: targets,
      colorShadow: AppTheme.primary,
      opacityShadow: 0.6,
      textSkip: 'LEWATI',
      alignSkip: Alignment.topRight,
      textStyleSkip: GoogleFonts.inter(
        color: Colors.white,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
      paddingFocus: 10,
      pulseEnable: true,
      focusAnimationDuration: const Duration(milliseconds: 400),
      unFocusAnimationDuration: const Duration(milliseconds: 300),
      imageFilter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
      onFinish: () {
        // Kembali ke tab Beranda saat tutorial selesai
        MainShellScreen.switchPage?.call(0);
      },
      onSkip: () {
        // Kembali ke tab Beranda jika user skip
        MainShellScreen.switchPage?.call(0);
        return true;
      },
      // Saat user tap target/overlay → handle aksi per step
      onClickTarget: (t) => _handleStepClick(t, balancePageController),
      onClickOverlay: (t) => _handleStepClick(t, balancePageController),
    ).show(context: context);
  }

  /// Dipanggil saat user tap (target/overlay) di langkah yang sedang aktif.
  /// - balance_card_saldo  → slide PageView ke pengeluaran (page 1)
  /// - nav_*              → pindah tab PageView shell
  static void _handleStepClick(
      TargetFocus target, PageController balancePageController) {
    switch (target.identify) {
      case 'balance_card_saldo':
        // Step 1 di-tap → slide ke kartu pengeluaran
        balancePageController.animateToPage(
          1,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
        break;
      case 'nav_dashboard':
        // Step 5 di-tap → pindah ke Summary, lanjut ke nav_summary
        MainShellScreen.switchPage?.call(1);
        break;
      case 'summary_overview':
        // Step 7 di-tap → pindah ke Transaksi, lanjut ke nav_transaksi
        MainShellScreen.switchPage?.call(2);
        break;
      case 'transaction_filters':
        // Step 9 di-tap → pindah ke Profil
        MainShellScreen.switchPage?.call(3);
        break;
    }
  }

  // ---------------------------------------------------------------------------
  // Private: membangun daftar TargetFocus
  // ---------------------------------------------------------------------------

  static List<TargetFocus> _buildTargets({
    required GlobalKey keyBalanceCard,
    required GlobalKey keyWalletsSection,
    required GlobalKey keyRecentActivity,
    required GlobalKey keyFab,
    required GlobalKey keyNavDashboard,
    required GlobalKey keyNavSummary,
    required GlobalKey keyNavTransaksi,
    required GlobalKey keyNavProfil,
  }) {
    return [
      // Step 1 — Total Saldo Card
      TargetFocus(
        identify: 'balance_card_saldo',
        keyTarget: keyBalanceCard,
        shape: ShapeLightFocus.RRect,
        radius: 20,
        enableOverlayTab: true,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: _ContentWidget(
              icon: '💰',
              title: 'Total Saldo',
              description:
                  'Kartu ini menampilkan total saldo semua dompet Anda. '
                  'Tap untuk melihat kartu pengeluaran.',
            ),
          ),
        ],
      ),

      // Step 2 — Total Pengeluaran Card
      TargetFocus(
        identify: 'balance_card_pengeluaran',
        keyTarget: keyBalanceCard,
        shape: ShapeLightFocus.RRect,
        radius: 20,
        enableOverlayTab: true,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: _ContentWidget(
              icon: '📉',
              title: 'Pengeluaran Bulan Ini',
              description:
                  'Kartu ini merangkum total pengeluaran Anda bulan ini. '
                  'Geser kartu untuk berpindah antara saldo dan pengeluaran.',
            ),
          ),
        ],
      ),

      // Step 2 — Wallets Section
      TargetFocus(
        identify: 'wallets_section',
        keyTarget: keyWalletsSection,
        shape: ShapeLightFocus.RRect,
        radius: 16,
        enableOverlayTab: true,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: _ContentWidget(
              icon: '👛',
              title: 'Dompet Saya',
              description:
                  'Semua dompet Anda tersusun di sini. '
                  'Tap untuk melihat detail atau tambah dompet baru.',
            ),
          ),
        ],
      ),

      // Step 3 — Recent Activity
      TargetFocus(
        identify: 'recent_activity',
        keyTarget: keyRecentActivity,
        shape: ShapeLightFocus.RRect,
        radius: 8,
        enableOverlayTab: true,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: _ContentWidget(
              icon: '📋',
              title: 'Transaksi Terbaru',
              description:
                  'Lihat aktivitas keuangan Anda yang terbaru. '
                  'Tap "Lihat Semua" untuk riwayat lengkap.',
            ),
          ),
        ],
      ),

      // Step 4 — FAB
      TargetFocus(
        identify: 'fab_add',
        keyTarget: keyFab,
        shape: ShapeLightFocus.Circle,
        enableOverlayTab: true,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: _ContentWidget(
              icon: '➕',
              title: 'Catat Transaksi',
              description:
                  'Tombol ini adalah cara tercepat mencatat '
                  'pemasukan atau pengeluaran baru.',
            ),
          ),
        ],
      ),

      // Step 5 — Tab Beranda
      TargetFocus(
        identify: 'nav_dashboard',
        keyTarget: keyNavDashboard,
        shape: ShapeLightFocus.RRect,
        radius: 8,
        enableOverlayTab: true,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: _ContentWidget(
              icon: '🏠',
              title: 'Beranda',
              description: 'Dashboard utama ringkasan keuangan harian Anda.',
            ),
          ),
        ],
      ),

      // Step 6 — Tab Summary
      TargetFocus(
        identify: 'nav_summary',
        keyTarget: keyNavSummary,
        shape: ShapeLightFocus.RRect,
        radius: 8,
        enableOverlayTab: true,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: _ContentWidget(
              icon: '📊',
              title: 'Summary',
              description:
                  'Analisis pengeluaran & pemasukan dalam grafik bulanan '
                  'yang mudah dibaca.',
            ),
          ),
        ],
      ),

      // Step 7 — Summary Overview
      TargetFocus(
        identify: 'summary_overview',
        keyTarget: SummaryScreen.keySummaryOverview,
        shape: ShapeLightFocus.RRect,
        radius: 12,
        enableOverlayTab: true,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: _ContentWidget(
              icon: '🗓️',
              title: 'Filter & Ringkasan',
              description:
                  'Pilih periode waktu di atas dan lihat ringkasan pemasukan, pengeluaran, serta arus kas bersih Anda secara instan di sini.',
            ),
          ),
        ],
      ),

      // Step 8 — Tab Transaksi
      TargetFocus(
        identify: 'nav_transaksi',
        keyTarget: keyNavTransaksi,
        shape: ShapeLightFocus.RRect,
        radius: 8,
        enableOverlayTab: true,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: _ContentWidget(
              icon: '🧾',
              title: 'Transaksi',
              description:
                  'Riwayat lengkap semua transaksi Anda dengan '
                  'filter dan pencarian.',
            ),
          ),
        ],
      ),

      // Step 9 — Transaction Filters
      TargetFocus(
        identify: 'transaction_filters',
        keyTarget: AllTransactionsScreen.keyTransactionFilters,
        shape: ShapeLightFocus.RRect,
        radius: 16,
        enableOverlayTab: true,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: _ContentWidget(
              icon: '🔍',
              title: 'Cari & Filter Transaksi',
              description:
                  'Gunakan kotak pencarian dan filter ini untuk menemukan transaksi berdasarkan jenis, dompet, atau kategori dengan cepat.',
            ),
          ),
        ],
      ),

      // Step 8 — Tab Profil
      TargetFocus(
        identify: 'nav_profil',
        keyTarget: keyNavProfil,
        shape: ShapeLightFocus.RRect,
        radius: 8,
        enableOverlayTab: true,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: _ContentWidget(
              icon: '👤',
              title: 'Profil & Sinkron',
              description:
                  'Kelola akun Anda dan sinkronkan data ke server kapan saja.',
            ),
          ),
        ],
      ),

      // Step 9 — Manajemen Dompet
      TargetFocus(
        identify: 'menu_dompet',
        keyTarget: ProfileSyncScreen.keyMenuDompet,
        shape: ShapeLightFocus.RRect,
        radius: 12,
        enableOverlayTab: true,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: _ContentWidget(
              icon: '👛',
              title: 'Manajemen Dompet',
              description:
                  'Kelola semua dompet, rekening bank, tunai, dan e-wallet Anda di sini.',
            ),
          ),
        ],
      ),

      // Step 10 — Manajemen Kategori Transaksi
      TargetFocus(
        identify: 'menu_kategori',
        keyTarget: ProfileSyncScreen.keyMenuKategori,
        shape: ShapeLightFocus.RRect,
        radius: 12,
        enableOverlayTab: true,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: _ContentWidget(
              icon: '📁',
              title: 'Kategori Transaksi',
              description:
                  'Buat dan kelola kategori untuk mengelompokkan setiap transaksi Anda.',
            ),
          ),
        ],
      ),

      // Step 11 — Manajemen Tipe Transaksi
      TargetFocus(
        identify: 'menu_tipe',
        keyTarget: ProfileSyncScreen.keyMenuTipe,
        shape: ShapeLightFocus.RRect,
        radius: 12,
        enableOverlayTab: true,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: _ContentWidget(
              icon: '🔺',
              title: 'Tipe Transaksi',
              description:
                  'Atur tipe pemasukan atau pengeluaran secara fleksibel sesuai kebutuhan.',
            ),
          ),
        ],
      ),
    ];
  }
}

// ---------------------------------------------------------------------------
// Widget konten coach mark
// ---------------------------------------------------------------------------

class _ContentWidget extends StatelessWidget {
  const _ContentWidget({
    required this.icon,
    required this.title,
    required this.description,
    this.hint,
  });

  final String icon;
  final String title;
  final String description;

  /// Teks hint kustom. Jika null, tampilkan "Tap di mana saja untuk lanjut →".
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final hintText = hint ?? 'Tap di mana saja untuk lanjut →';
    final hintIcon = hint != null ? '👆 ' : '';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$icon  $title',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.white.withOpacity(0.88),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          // Hint box — lebih menonjol jika ada hint kustom (e.g. swipe)
          if (hint != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                ),
              ),
              child: Text(
                '$hintIcon$hintText',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.85),
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          else
            Text(
              hintText,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.white.withOpacity(0.55),
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }
}

