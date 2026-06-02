import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/app_router.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/transaction.dart';
import '../../models/wallet.dart';
import '../../providers/sync_provider.dart';
import '../../providers/transaction_category_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/wallet_provider.dart';
import '../settings/transaction_category_list_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final wallet = context.read<WalletProvider>();
    final tx = context.read<TransactionProvider>();
    await Future.wait([wallet.loadFromLocal(), tx.loadAll()]);
    // If no local data, fetch from server
    if (wallet.wallets.isEmpty) await wallet.fetchFromServer();
    if (tx.categories.isEmpty) await tx.fetchCategoriesFromServer();
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
              // Empty Category Banner
              SliverToBoxAdapter(child: _buildEmptyCategoryBanner()),
              // Wallets Horizontal Scroll
              SliverToBoxAdapter(child: _buildWalletsSection()),
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
    return Consumer<WalletProvider>(
      builder: (context, walletProvider, _) {
        final totalBalance = walletProvider.totalBalance;
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
                color: AppTheme.primary.withOpacity(0.35),
                blurRadius: 24,
                offset: const Offset(0, 8),
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
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.white70,
                    ),
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
      },
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
    return Consumer<TransactionCategoryProvider>(
      builder: (context, catProvider, _) {
        if (catProvider.isLoading || catProvider.categories.isNotEmpty) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                        'Belum Ada Kategori',
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
                  'Anda belum memiliki kategori transaksi. Tambahkan kategori pada halaman profile.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppTheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const TransactionCategoryListScreen(),
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.error,
                      foregroundColor: AppTheme.onError,
                      elevation: 0,
                    ),
                    child: const Text('Buat Kategori'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
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

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) =>
                _TransactionListItem(transaction: transactions[index]),
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

  const _TransactionListItem({required this.transaction});

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
              final action =
                  transaction.transactionCategory?.transactionType?.action;
              final amount = transaction.amountDouble;
              final delta = action == AppConstants.actionAddition
                  ? -amount
                  : action == AppConstants.actionDeduction
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
        if (hasError) {
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
                if (hasError)
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
                else if (transaction.isPending)
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
