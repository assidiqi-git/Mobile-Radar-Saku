import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/app_router.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/transaction.dart';
import '../../models/wallet.dart';
import '../../providers/auth_provider.dart';
import '../../providers/sync_provider.dart';
import '../../providers/transaction_category_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/wallet_provider.dart';
import '../settings/transaction_category_list_screen.dart';
import '../../providers/transaction_type_provider.dart';
import '../settings/transaction_type_list_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  final PageController _balancePageController = PageController();
  int _balanceCardIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _balancePageController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final wallet = context.read<WalletProvider>();
    final tx = context.read<TransactionProvider>();
    final catProvider = context.read<TransactionCategoryProvider>();
    final isGuest = context.read<AuthProvider>().isGuest;

    // Load local data first (always safe, no network)
    await Future.wait([wallet.loadFromLocal(), tx.loadAll()]);

    // Guest mode: skip all network calls — no token available
    if (isGuest) {
      await catProvider.loadAll();
      return;
    }

    // If no local data, fetch from server
    if (wallet.wallets.isEmpty) await wallet.fetchFromServer();

    bool justSynced = false;
    if (tx.categories.isEmpty) {
      await tx.fetchCategoriesFromServer();
      justSynced = true;
    }

    // Refresh CategoryProvider so the banner updates correctly after sync
    if (justSynced || catProvider.categories.isEmpty) {
      await catProvider.loadAll();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppTheme.primary,
          onRefresh: _loadData,
          child: CustomScrollView(
            slivers: [
              // App Bar
              SliverToBoxAdapter(child: _buildHeader()),
              // Hero Balance Card
              SliverToBoxAdapter(child: _buildBalanceCard()),
              // Weekly Expense Chart
              SliverToBoxAdapter(child: _buildWeeklyExpenseChart()),
              // Empty Category Banner
              SliverToBoxAdapter(child: _buildEmptyCategoryBanner()),
              // Wallets Horizontal Scroll
              // SliverToBoxAdapter(child: _buildWalletsSection()),
              // Pending Sync Banner
              SliverToBoxAdapter(child: _buildSyncBanner()),
              // Recent Transactions Header
              SliverToBoxAdapter(
                child: _buildSectionHeader(
                  'Transaksi Terkini',
                  actionLabel: 'Lihat Semua',
                  onTap: () =>
                      Navigator.pushNamed(context, AppRouter.allTransactions),
                ),
              ),
              // Transaction List
              _buildTransactionList(),
              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, AppRouter.addTransaction),
        child: const Icon(Icons.add_rounded),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Halo 👋',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppTheme.onSurfaceVariant,
                ),
              ),
              Text(
                'Dashboard',
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.onSurface,
                ),
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            onPressed: () => Navigator.pushNamed(context, AppRouter.profile),
            icon: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.person_outline_rounded,
                color: AppTheme.primary,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Consumer2<WalletProvider, TransactionProvider>(
      builder: (context, walletProvider, txProvider, _) {
        final totalBalance = walletProvider.totalBalance;

        // Hitung total pengeluaran bulan berjalan
        final now = DateTime.now();
        final monthStart = DateTime(now.year, now.month, 1);
        final monthEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        final monthlyExpense = txProvider.transactions
            .where((t) {
              if (!t.isExpense) return false;
              final date = DateTime.tryParse(t.createdAt ?? '');
              if (date == null) return false;
              return !date.isBefore(monthStart) && !date.isAfter(monthEnd);
            })
            .fold<double>(0, (sum, t) => sum + t.amountDouble);

        return Column(
          children: [
            SizedBox(
              height: 165,
              child: PageView(
                controller: _balancePageController,
                clipBehavior: Clip.none,
                onPageChanged: (index) =>
                    setState(() => _balanceCardIndex = index),
                children: [
                  // --- Card 1: Total Saldo ---
                  _buildTotalSaldoCard(totalBalance),
                  // --- Card 2: Total Pengeluaran Bulan Ini ---
                  _buildTotalPengeluaranCard(monthlyExpense, now),
                ],
              ),
            ),
            const SizedBox(height: 10),
            // Dot indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(2, (index) {
                final isActive = index == _balanceCardIndex;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: isActive ? 18 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppTheme.primary
                        : AppTheme.primary.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTotalSaldoCard(double totalBalance) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryContainer, AppTheme.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.45),
            blurRadius: 16,
            spreadRadius: 0,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.account_balance_wallet_rounded,
                color: Colors.white54,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Total Saldo',
                style: GoogleFonts.inter(fontSize: 13, color: Colors.white70),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Consumer<SyncProvider>(
                  builder: (_, sync, __) => Row(
                    children: [
                      Icon(
                        sync.hasPending
                            ? Icons.sync_problem_rounded
                            : Icons.check_circle_rounded,
                        color: Colors.white70,
                        size: 13,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            CurrencyFormatter.format(totalBalance),
            style: AppTheme.balanceLarge,
          ),
        ],
      ),
    );
  }

  Widget _buildTotalPengeluaranCard(double totalExpense, DateTime now) {
    final monthNames = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    final monthLabel = '${monthNames[now.month - 1]} ${now.year}';

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7F1D1D), Color(0xFFDC2626)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFDC2626).withOpacity(0.45),
            blurRadius: 16,
            spreadRadius: 0,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.trending_down_rounded,
                color: Colors.white54,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Pengeluaran Bulan Ini',
                style: GoogleFonts.inter(fontSize: 13, color: Colors.white70),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  monthLabel,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            CurrencyFormatter.format(totalExpense),
            style: AppTheme.balanceLarge,
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 12, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyExpenseChart() {
    return Consumer<TransactionProvider>(
      builder: (context, txProvider, _) {
        final now = DateTime.now();
        // Mulai dari Senin minggu berjalan
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final weekStart = DateTime(
          startOfWeek.year,
          startOfWeek.month,
          startOfWeek.day,
        );

        // Hitung pengeluaran per hari (Sen-Min)
        final List<double> dailyExpense = List.generate(7, (i) {
          final day = weekStart.add(Duration(days: i));
          final dayEnd = DateTime(day.year, day.month, day.day, 23, 59, 59);
          return txProvider.transactions
              .where((t) {
                if (!t.isExpense) return false;
                final date = DateTime.tryParse(t.createdAt ?? '');
                if (date == null) return false;
                return !date.isBefore(day) && !date.isAfter(dayEnd);
              })
              .fold<double>(0, (sum, t) => sum + t.amountDouble);
        });

        final totalWeek = dailyExpense.fold<double>(0, (a, b) => a + b);
        final maxVal = dailyExpense.reduce((a, b) => a > b ? a : b);

        // Hitung % perubahan vs minggu lalu
        final lastWeekStart = weekStart.subtract(const Duration(days: 7));
        final totalLastWeek = List.generate(7, (i) {
          final day = lastWeekStart.add(Duration(days: i));
          final dayEnd = DateTime(day.year, day.month, day.day, 23, 59, 59);
          return txProvider.transactions
              .where((t) {
                if (!t.isExpense) return false;
                final date = DateTime.tryParse(t.createdAt ?? '');
                if (date == null) return false;
                return !date.isBefore(day) && !date.isAfter(dayEnd);
              })
              .fold<double>(0, (sum, t) => sum + t.amountDouble);
        }).fold<double>(0, (a, b) => a + b);

        double? changePercent;
        if (totalLastWeek > 0) {
          changePercent = ((totalWeek - totalLastWeek) / totalLastWeek) * 100;
        }

        final dayLabels = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
        final todayIndex = now.weekday - 1; // 0=Sen, 6=Min

        return Container(
          margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'Pengeluaran Minggu Ini',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppTheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    CurrencyFormatter.format(totalWeek),
                    style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.onSurface,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (changePercent != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: changePercent <= 0
                            ? AppTheme.incomeColor.withOpacity(0.12)
                            : AppTheme.expenseColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            changePercent <= 0
                                ? Icons.arrow_downward_rounded
                                : Icons.arrow_upward_rounded,
                            size: 11,
                            color: changePercent <= 0
                                ? AppTheme.incomeColor
                                : AppTheme.expenseColor,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '${changePercent.abs().toStringAsFixed(1)}%',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: changePercent <= 0
                                  ? AppTheme.incomeColor
                                  : AppTheme.expenseColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              // Bar Chart
              SizedBox(
                height: 130,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: maxVal > 0 ? maxVal * 1.3 : 10,
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipColor: (_) =>
                            AppTheme.onSurface.withOpacity(0.85),
                        tooltipPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          if (rod.toY == 0) return null;
                          return BarTooltipItem(
                            CurrencyFormatter.compact(rod.toY),
                            GoogleFonts.inter(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 24,
                          getTitlesWidget: (value, meta) {
                            final i = value.toInt();
                            final isToday = i == todayIndex;
                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                dayLabels[i],
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: isToday
                                      ? FontWeight.w700
                                      : FontWeight.w400,
                                  color: isToday
                                      ? AppTheme.primary
                                      : AppTheme.onSurfaceVariant,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    gridData: const FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    barGroups: List.generate(7, (i) {
                      final isToday = i == todayIndex;
                      final val = dailyExpense[i];
                      return BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: val,
                            width: 28,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(8),
                            ),
                            gradient: LinearGradient(
                              colors: isToday
                                  ? [
                                      AppTheme.primaryContainer,
                                      AppTheme.primary,
                                    ]
                                  : [
                                      AppTheme.surfaceContainerLow,
                                      AppTheme.outline.withOpacity(0.4),
                                    ],
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWalletsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          'Dompet Saya',
          actionLabel: 'Lihat Semua',
          onTap: () {
            Navigator.pushNamed(context, AppRouter.wallets);
          },
        ),
        Consumer<WalletProvider>(
          builder: (context, walletProvider, _) {
            final wallets = walletProvider.wallets;
            if (wallets.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: _buildEmptyWalletCard(),
              );
            }
            return SizedBox(
              height: 110,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: wallets.length,
                itemBuilder: (_, i) => _WalletCard(wallet: wallets[i]),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildEmptyWalletCard() {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, AppRouter.wallets),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.primary.withOpacity(0.2),
            style: BorderStyle.solid,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.add_rounded, color: AppTheme.primary),
            ),
            const SizedBox(width: 12),
            Text(
              'Tambah dompet pertama Anda',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppTheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSyncBanner() {
    final isGuest = context.read<AuthProvider>().isGuest;
    if (isGuest) return const SizedBox.shrink();

    return Consumer<SyncProvider>(
      builder: (_, sync, __) {
        if (!sync.hasPending) return const SizedBox.shrink();
        return Container(
          margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBEB),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFFCD34D)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.sync_rounded,
                color: Color(0xFFD97706),
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${sync.pendingCount} transaksi belum tersinkron',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF92400E),
                  ),
                ),
              ),
              TextButton(
                onPressed: sync.isSyncing
                    ? null
                    : () => context.read<SyncProvider>().sync(),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFD97706),
                  minimumSize: Size.zero,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: sync.isSyncing
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Sinkron'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyCategoryBanner() {
    return Consumer2<TransactionTypeProvider, TransactionCategoryProvider>(
      builder: (context, typeProvider, catProvider, _) {
        if (typeProvider.isLoading || catProvider.isLoading) {
          return const SizedBox.shrink();
        }

        final typesEmpty = typeProvider.types.isEmpty;
        final catsEmpty = catProvider.categories.isEmpty;

        if (!typesEmpty && !catsEmpty) {
          return const SizedBox.shrink();
        }

        if (typesEmpty) {
          return _buildBanner(
            context: context,
            title: 'Belum Ada Jenis Transaksi',
            description:
                'Anda belum memiliki jenis transaksi. Tambahkan jenis transaksi pada halaman profil.',
            buttonText: 'Buat Jenis Transaksi',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const TransactionTypeListScreen(),
              ),
            ),
          );
        }

        return _buildBanner(
          context: context,
          title: 'Belum Ada Kategori',
          description:
              'Anda belum memiliki kategori transaksi. Tambahkan kategori pada halaman profil.',
          buttonText: 'Buat Kategori',
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const TransactionCategoryListScreen(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBanner({
    required BuildContext context,
    required String title,
    required String description,
    required String buttonText,
    required VoidCallback onPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.errorContainer.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.error.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: AppTheme.error,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppTheme.error,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppTheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.error,
                  foregroundColor: AppTheme.onError,
                  elevation: 0,
                ),
                child: Text(buttonText),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    String title, {
    String? actionLabel,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Row(
        children: [
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.onSurface,
            ),
          ),
          const Spacer(),
          if (actionLabel != null)
            GestureDetector(
              onTap: onTap,
              child: Text(
                actionLabel,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTransactionList() {
    return Consumer<TransactionProvider>(
      builder: (context, txProvider, _) {
        if (txProvider.isLoading) {
          return const SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            ),
          );
        }

        final transactions = txProvider.recentTransactions;
        if (transactions.isEmpty) {
          return SliverToBoxAdapter(child: _buildEmptyTransactions());
        }

        final isGuest = context.read<AuthProvider>().isGuest;
        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => _TransactionListItem(
              transaction: transactions[index],
              isGuest: isGuest,
            ),
            childCount: transactions.length,
          ),
        );
      },
    );
  }

  Widget _buildEmptyTransactions() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.receipt_long_rounded,
                color: AppTheme.outline,
                size: 36,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Belum ada transaksi',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Catat transaksi pertama Anda\ndengan menekan tombol +',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 13, color: AppTheme.outline),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      type: BottomNavigationBarType.fixed,
      onTap: (index) {
        if (index == 0) {
          // Already on dashboard — no-op
          return;
        }
        if (index == 2) {
          // Dummy item for FAB gap — no-op
          return;
        }

        // Highlight the tapped tab temporarily while the route is open,
        // then reset back to Beranda (0) when the user returns.
        setState(() => _currentIndex = index);
        final route = index == 1
            ? AppRouter.allTransactions
            : index == 3
            ? AppRouter.wallets
            : AppRouter.transfer;
        Navigator.pushNamed(context, route).then((_) {
          if (mounted) setState(() => _currentIndex = 0);
        });
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard_rounded),
          label: 'Beranda',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.receipt_long_rounded),
          label: 'Transaksi',
        ),
        BottomNavigationBarItem(
          icon: Icon(null), // Dummy icon for FAB space
          label: '',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.account_balance_wallet_rounded),
          label: 'Dompet',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.swap_horiz_rounded),
          label: 'Transfer',
        ),
      ],
    );
  }
}

// --- Wallet Card Widget ---
class _WalletCard extends StatelessWidget {
  final WalletModel wallet;

  const _WalletCard({required this.wallet});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12, bottom: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getWalletIcon(wallet.type),
                  color: AppTheme.primary,
                  size: 16,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  wallet.typeLabel,
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    color: AppTheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                wallet.name,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppTheme.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                CurrencyFormatter.compact(wallet.balance),
                style: AppTheme.monoStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.onSurface,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getWalletIcon(String type) {
    switch (type) {
      case 'checking':
        return Icons.account_balance_rounded;
      case 'savings':
        return Icons.savings_rounded;
      case 'cash':
        return Icons.payments_rounded;
      case 'investment':
        return Icons.trending_up_rounded;
      default:
        return Icons.wallet_rounded;
    }
  }
}

// --- Transaction List Item Widget ---
class _TransactionListItem extends StatelessWidget {
  final TransactionModel transaction;
  final bool isGuest;

  const _TransactionListItem({
    required this.transaction,
    required this.isGuest,
  });

  void _showErrorDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: AppTheme.error,
              size: 20,
            ),
            const SizedBox(width: 8),
            const Text('Transaksi Bermasalah'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Transaksi ini ditolak oleh server:',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppTheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.error.withOpacity(0.06),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.error.withOpacity(0.2)),
              ),
              child: Text(
                transaction.syncErrorMessage ?? 'Tidak ada detail error.',
                style: GoogleFonts.inter(fontSize: 12, color: AppTheme.error),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Pilih tindakan:',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppTheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          // Delete: permanently remove + reverse balance
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final txProvider = context.read<TransactionProvider>();
              final walletProvider = context.read<WalletProvider>();
              // Reverse wallet balance mutation
              final amount = transaction.amountDouble;
              final delta = transaction.isIncome
                  ? -amount
                  : transaction.isExpense
                  ? amount
                  : 0.0;
              if (delta != 0 && transaction.walletId.isNotEmpty) {
                await walletProvider.mutateBalance(transaction.walletId, delta);
              }
              await txProvider.deleteTransaction(transaction.id);
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: const Text('Hapus'),
          ),
          // Retry: re-open form with pre-filled data
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              // TODO: navigate to edit form with pre-filled data
              // For now, open a new transaction form
              Navigator.pushNamed(context, AppRouter.addTransaction);
            },
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Resolve the transaction action (addition | deduction | neutral)
    final action = transaction.transactionCategory?.transactionType?.action;
    final isIncome = action == AppConstants.actionAddition;
    final isExpense = action == AppConstants.actionDeduction;
    // neutral covers both explicit 'neutral' AND unknown/null action
    final isNeutral = !isIncome && !isExpense;

    final hasError = transaction.hasError;

    // Amount display
    final String amountPrefix = isIncome
        ? '+'
        : isExpense
        ? '-'
        : '~';
    final TextStyle amountStyle = isIncome
        ? AppTheme.amountIncome
        : isExpense
        ? AppTheme.amountExpense
        : AppTheme.monoStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppTheme.onSurfaceVariant,
          );

    // Icon + tint color for the leading circle
    final IconData actionIcon = hasError
        ? Icons.error_outline_rounded
        : isIncome
        ? Icons.arrow_downward_rounded
        : isExpense
        ? Icons.arrow_upward_rounded
        : Icons.swap_horiz_rounded; // neutral

    final Color actionColor = hasError
        ? AppTheme.error
        : isIncome
        ? AppTheme.incomeColor
        : isExpense
        ? AppTheme.expenseColor
        : AppTheme.onSurfaceVariant; // neutral

    return GestureDetector(
      onTap: () {
        if (!isGuest && hasError) {
          _showErrorDialog(context);
        } else {
          Navigator.pushNamed(
            context,
            AppRouter.transactionDetail,
            arguments: transaction.id,
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: hasError
              ? AppTheme.error.withOpacity(0.03)
              : AppTheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasError
                ? AppTheme.error.withOpacity(0.25)
                : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: actionColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(actionIcon, color: actionColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.name,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      if (transaction.transactionCategory != null) ...[
                        Text(
                          transaction.transactionCategory!.name,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppTheme.outline,
                          ),
                        ),
                        Text(
                          ' · ${DateFormatter.relativeTime(DateTime.tryParse(transaction.createdAt ?? ''))}',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppTheme.outline,
                          ),
                        ),
                      ] else ...[
                        Text(
                          DateFormatter.relativeTime(
                            DateTime.tryParse(transaction.createdAt ?? ''),
                          ),
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppTheme.outline,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$amountPrefix${CurrencyFormatter.format(transaction.amount)}',
                  style: amountStyle,
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormatter.displayDate(
                    DateTime.tryParse(transaction.createdAt ?? ''),
                  ),
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: AppTheme.outline,
                  ),
                ),
                if (!isGuest && hasError)
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          size: 9,
                          color: AppTheme.error,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          'error',
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            color: AppTheme.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  )
                else if (!isGuest && transaction.isPending)
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'pending',
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        color: const Color(0xFFD97706),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
