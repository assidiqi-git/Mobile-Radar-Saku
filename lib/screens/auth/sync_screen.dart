import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../services/initial_sync_service.dart';

class SyncScreen extends StatefulWidget {
  const SyncScreen({super.key});

  @override
  State<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends State<SyncScreen>
    with SingleTickerProviderStateMixin {
  // ---- State ----------------------------------------------------------------
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  int _currentStep = 0;
  double _progress = 0.0;
  String _statusMessage = 'Menyiapkan catatan Anda...';

  // ---- Animation ------------------------------------------------------------
  late final AnimationController _iconAnimController;
  late final Animation<double> _iconScaleAnim;
  late final Animation<double> _iconFadeAnim;

  // ---- Step metadata --------------------------------------------------------
  static const _totalSteps = 6; // steps 0..6

  static const _stepProgress = <int, double>{
    0: 0.05,
    1: 0.30,
    2: 0.30, // steps 1-3 lumped (parallel)
    3: 0.30,
    4: 0.75,
    5: 0.90,
    6: 1.00,
  };

  // ---- Lifecycle ------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    _iconAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _iconScaleAnim = CurvedAnimation(
      parent: _iconAnimController,
      curve: Curves.elasticOut,
    );
    _iconFadeAnim = CurvedAnimation(
      parent: _iconAnimController,
      curve: Curves.easeIn,
    );
    _iconAnimController.forward();

    // Small delay so the screen renders before heavy work starts
    Future.delayed(const Duration(milliseconds: 400), _startSync);
  }

  @override
  void dispose() {
    _iconAnimController.dispose();
    super.dispose();
  }

  // ---- Sync logic -----------------------------------------------------------

  Future<void> _startSync() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      await InitialSyncService.instance.runInitialSync(
        onProgress: _onProgress,
      );

      if (!mounted) return;

      // Brief pause so the "Selesai!" message is visible
      await Future<void>.delayed(const Duration(milliseconds: 800));

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, AppRouter.dashboard);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage =
            'Gagal menyinkronkan data.\n${_friendlyError(e.toString())}';
      });
    }
  }

  void _onProgress(int step, String message) {
    if (!mounted) return;
    setState(() {
      _currentStep = step;
      _statusMessage = message;
      _progress = _stepProgress[step] ?? _progress;
    });
  }

  String _friendlyError(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('socket') || lower.contains('connection refused')) {
      return 'Tidak dapat terhubung ke server.\nPeriksa koneksi internet atau pastikan server aktif.';
    }
    if (lower.contains('timeout')) {
      return 'Koneksi timeout. Coba lagi sebentar.';
    }
    if (lower.contains('non-json') || lower.contains('bukan json')) {
      return 'Server mengembalikan respons tidak valid.\nPastikan URL API sudah benar.';
    }
    if (lower.contains('401') || lower.contains('unauthenticated')) {
      return 'Sesi login habis. Silakan login ulang.';
    }
    return 'Terjadi kesalahan. Silakan coba lagi.';
  }

  void _skip() {
    Navigator.pushReplacementNamed(context, AppRouter.dashboard);
  }

  // ---- Build ----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isLoading, // allow back only after loading completes or errors
      child: Scaffold(
        backgroundColor: AppTheme.surface,
        body: SafeArea(
          child: _hasError ? _buildErrorView() : _buildLoadingView(),
        ),
      ),
    );
  }

  // ---- Loading view ---------------------------------------------------------

  Widget _buildLoadingView() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Spacer(flex: 2),

          // Animated logo
          ScaleTransition(
            scale: _iconScaleAnim,
            child: FadeTransition(
              opacity: _iconFadeAnim,
              child: Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primary, Color(0xFF0D7A5C)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.35),
                      blurRadius: 28,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: Colors.white,
                  size: 44,
                ),
              ),
            ),
          ),

          const SizedBox(height: 32),

          Text(
            'Radar Saku',
            style: GoogleFonts.outfit(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: AppTheme.onSurface,
            ),
          ),

          const SizedBox(height: 8),

          // Dynamic status message with smooth crossfade
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.3),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOut,
                )),
                child: child,
              ),
            ),
            child: Text(
              _statusMessage,
              key: ValueKey(_statusMessage),
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppTheme.onSurfaceVariant,
              ),
            ),
          ),

          const SizedBox(height: 40),

          // Progress bar
          _buildProgressSection(),

          const Spacer(flex: 3),

          Text(
            'Mohon tunggu, jangan tutup aplikasi',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppTheme.outline,
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildProgressSection() {
    final percent = (_progress * 100).toInt();
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Sinkronisasi data',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppTheme.onSurfaceVariant,
              ),
            ),
            Text(
              '$percent%',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: _progress),
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
            builder: (context, value, _) => LinearProgressIndicator(
              value: value,
              minHeight: 8,
              backgroundColor: AppTheme.surfaceContainerHigh,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppTheme.primary),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Step dots indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_totalSteps, (i) {
            final stepIndex = i + 1; // steps 1..6
            final isDone = _currentStep > stepIndex;
            final isActive = _currentStep == stepIndex;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: isActive ? 20 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: isDone || isActive
                    ? AppTheme.primary
                    : AppTheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        ),
      ],
    );
  }

  // ---- Error view -----------------------------------------------------------

  Widget _buildErrorView() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Spacer(),

          // Error icon
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: AppTheme.errorContainer,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              Icons.cloud_off_rounded,
              color: AppTheme.error,
              size: 44,
            ),
          ),

          const SizedBox(height: 28),

          Text(
            'Sinkronisasi Gagal',
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppTheme.onSurface,
            ),
          ),

          const SizedBox(height: 12),

          Text(
            _errorMessage,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              height: 1.5,
              color: AppTheme.onSurfaceVariant,
            ),
          ),

          const Spacer(),

          // Retry button
          ElevatedButton.icon(
            onPressed: _startSync,
            icon: const Icon(Icons.refresh_rounded, size: 20),
            label: const Text('Coba Lagi'),
          ),

          const SizedBox(height: 12),

          // Skip button
          OutlinedButton(
            onPressed: _skip,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.onSurfaceVariant,
              side: BorderSide(color: AppTheme.outlineVariant),
            ),
            child: const Text('Lewati, Masuk Tanpa Data'),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
