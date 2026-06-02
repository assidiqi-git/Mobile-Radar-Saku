import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/app_router.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/transaction.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/wallet_provider.dart';

class AllTransactionsScreen extends StatefulWidget {
  const AllTransactionsScreen({super.key});

  @override
  State<AllTransactionsScreen> createState() => _AllTransactionsScreenState();
}

class _AllTransactionsScreenState extends State<AllTransactionsScreen> {
  final _searchController = TextEditingController();

  String _searchText = '';
  String? _selectedAction; // null = semua, 'addition', 'deduction', 'neutral'
  String? _selectedWalletId;
  DateTimeRange? _dateRange;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: _dateRange,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(
            ctx,
          ).colorScheme.copyWith(primary: AppTheme.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _dateRange = picked);
  }

  void _clearDateRange() => setState(() => _dateRange = null);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            _buildSearchBar(),
            _buildFilterChips(),
            if (_dateRange != null) _buildDateRangeBadge(),
            Expanded(child: _buildTransactionList()),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, AppRouter.addTransaction),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        // shape: RoundedRectangleBorder(
        //   borderRadius: BorderRadius.circular(16),
        // ),
        child: const Icon(Icons.add_rounded, size: 28),
      ),
    );
  }

  // ── App Bar ────────────────────────────────────────────────────────────────

  Widget _buildAppBar() {
    return Container(
      color: AppTheme.surfaceContainerLowest,
      padding: const EdgeInsets.fromLTRB(4, 8, 8, 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: () => Navigator.pop(context),
            color: AppTheme.onSurface,
          ),
          Expanded(
            child: Text(
              'Semua Transaksi',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.onSurface,
              ),
            ),
          ),
          // Date range picker button
          Stack(
            children: [
              IconButton(
                icon: Icon(
                  Icons.date_range_rounded,
                  color: _dateRange != null
                      ? AppTheme.primary
                      : AppTheme.outline,
                ),
                onPressed: _pickDateRange,
                tooltip: 'Pilih rentang tanggal',
              ),
              if (_dateRange != null)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppTheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Search Bar ─────────────────────────────────────────────────────────────

  Widget _buildSearchBar() {
    return Container(
      color: AppTheme.surfaceContainerLowest,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: TextField(
        controller: _searchController,
        onChanged: (v) => setState(() => _searchText = v),
        decoration: InputDecoration(
          hintText: 'Cari nama atau catatan...',
          hintStyle: GoogleFonts.inter(fontSize: 14, color: AppTheme.outline),
          prefixIcon: const Icon(Icons.search_rounded, size: 20),
          suffixIcon: _searchText.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchText = '');
                  },
                )
              : null,
          filled: true,
          fillColor: AppTheme.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(28),
            borderSide: BorderSide(color: AppTheme.outline.withOpacity(0.3)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(28),
            borderSide: BorderSide(color: AppTheme.outline.withOpacity(0.2)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(28),
            borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 10,
          ),
          isDense: true,
        ),
        style: GoogleFonts.inter(fontSize: 14, color: AppTheme.onSurface),
      ),
    );
  }

  // ── Filter Chips ───────────────────────────────────────────────────────────

  Widget _buildFilterChips() {
    final wallets = context.watch<WalletProvider>().wallets;

    return Container(
      color: AppTheme.surfaceContainerLowest,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),
          // 1. Baris Jenis Transaksi
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
            child: Row(
              children: [
                _ActionChip(
                  label: 'Semua Transaksi',
                  isSelected: _selectedAction == null,
                  onTap: () => setState(() => _selectedAction = null),
                ),
                const SizedBox(width: 8),
                _ActionChip(
                  label: 'Pemasukan',
                  icon: Icons.arrow_downward_rounded,
                  iconColor: AppTheme.incomeColor,
                  isSelected: _selectedAction == AppConstants.actionAddition,
                  onTap: () => setState(
                    () => _selectedAction =
                        _selectedAction == AppConstants.actionAddition
                        ? null
                        : AppConstants.actionAddition,
                  ),
                ),
                const SizedBox(width: 8),
                _ActionChip(
                  label: 'Pengeluaran',
                  icon: Icons.arrow_upward_rounded,
                  iconColor: AppTheme.expenseColor,
                  isSelected: _selectedAction == AppConstants.actionDeduction,
                  onTap: () => setState(
                    () => _selectedAction =
                        _selectedAction == AppConstants.actionDeduction
                        ? null
                        : AppConstants.actionDeduction,
                  ),
                ),
                const SizedBox(width: 8),
                _ActionChip(
                  label: 'Netral',
                  icon: Icons.remove_rounded,
                  iconColor: AppTheme.secondary,
                  isSelected: _selectedAction == AppConstants.actionNeutral,
                  onTap: () => setState(
                    () => _selectedAction =
                        _selectedAction == AppConstants.actionNeutral
                        ? null
                        : AppConstants.actionNeutral,
                  ),
                ),
              ],
            ),
          ),
          // 2. Baris Dompet (jika ada)
          if (wallets.isNotEmpty)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
              child: Row(
                children: [
                  _ActionChip(
                    label: 'Semua Dompet',
                    isSelected: _selectedWalletId == null,
                    onTap: () => setState(() => _selectedWalletId = null),
                  ),
                  const SizedBox(width: 8),
                  ...wallets.map(
                    (w) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _ActionChip(
                        label: w.name,
                        icon: Icons.account_balance_wallet_rounded,
                        isSelected: _selectedWalletId == w.id,
                        onTap: () => setState(
                          () => _selectedWalletId = _selectedWalletId == w.id
                              ? null
                              : w.id,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (wallets.isEmpty)
            const SizedBox(height: 6), // padding bawah jika dompet kosong
        ],
      ),
    );
  }

  // ── Date Range Badge ───────────────────────────────────────────────────────

  Widget _buildDateRangeBadge() {
    final start = DateFormatter.displayDate(_dateRange!.start);
    final end = DateFormatter.displayDate(_dateRange!.end);
    return Container(
      width: double.infinity,
      color: AppTheme.primary.withOpacity(0.06),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Icon(Icons.calendar_today_rounded, size: 13, color: AppTheme.primary),
          const SizedBox(width: 6),
          Text(
            '$start – $end',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppTheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: _clearDateRange,
            child: Icon(Icons.close_rounded, size: 16, color: AppTheme.primary),
          ),
        ],
      ),
    );
  }

  // ── Transaction List ───────────────────────────────────────────────────────

  Widget _buildTransactionList() {
    return Consumer<TransactionProvider>(
      builder: (context, txProvider, _) {
        final filtered = txProvider.filterTransactions(
          searchText: _searchText.isEmpty ? null : _searchText,
          walletId: _selectedWalletId,
          categoryAction: _selectedAction,
          startDate: _dateRange?.start,
          endDate: _dateRange?.end,
        );

        if (txProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (filtered.isEmpty) {
          return _buildEmptyState();
        }

        final groupedItems = <dynamic>[];
        String? currentDateGroup;

        for (final tx in filtered) {
          final txDate = DateFormatter.fromApiString(tx.createdAt);
          final dateGroup = DateFormatter.displayDateGroup(txDate);

          if (currentDateGroup != dateGroup) {
            groupedItems.add(dateGroup);
            currentDateGroup = dateGroup;
          }
          groupedItems.add(tx);
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          itemCount: groupedItems.length,
          itemBuilder: (_, i) {
            final item = groupedItems[i];

            if (item is String) {
              return Padding(
                padding: const EdgeInsets.only(top: 16, bottom: 8),
                child: Text(
                  item.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.outline,
                    letterSpacing: 0.5,
                  ),
                ),
              );
            }

            return _TransactionItem(transaction: item as TransactionModel);
          },
        );
      },
    );
  }

  // ── Empty State ────────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    final hasFilters =
        _searchText.isNotEmpty ||
        _selectedAction != null ||
        _selectedWalletId != null ||
        _dateRange != null;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.outline.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                hasFilters
                    ? Icons.search_off_rounded
                    : Icons.receipt_long_rounded,
                size: 36,
                color: AppTheme.outline,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              hasFilters ? 'Tidak ada transaksi' : 'Belum ada transaksi',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hasFilters
                  ? 'Coba ubah filter atau rentang tanggal'
                  : 'Tambahkan transaksi pertama Anda\ndengan menekan tombol + di beranda',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 13, color: AppTheme.outline),
            ),
            if (hasFilters) ...[
              const SizedBox(height: 20),
              TextButton.icon(
                onPressed: () => setState(() {
                  _searchText = '';
                  _searchController.clear();
                  _selectedAction = null;
                  _selectedWalletId = null;
                  _dateRange = null;
                }),
                icon: const Icon(Icons.filter_alt_off_rounded, size: 16),
                label: const Text('Hapus semua filter'),
                style: TextButton.styleFrom(foregroundColor: AppTheme.primary),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Filter Chip Component ───────────────────────────────────────────────────

class _ActionChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color? iconColor;
  final bool isSelected;
  final VoidCallback onTap;

  const _ActionChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.icon,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primary
              : AppTheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppTheme.primary
                : AppTheme.outline.withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 13,
                color: isSelected
                    ? Colors.white
                    : (iconColor ?? AppTheme.onSurfaceVariant),
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? Colors.white : AppTheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Transaction List Item ───────────────────────────────────────────────────

class _TransactionItem extends StatelessWidget {
  final TransactionModel transaction;

  const _TransactionItem({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final action = transaction.transactionCategory?.transactionType?.action;
    final isIncome = action == AppConstants.actionAddition;
    final isExpense = action == AppConstants.actionDeduction;

    final Color actionColor = isIncome
        ? AppTheme.incomeColor
        : isExpense
        ? AppTheme.expenseColor
        : AppTheme.onSurfaceVariant;

    final IconData actionIcon = isIncome
        ? Icons.arrow_downward_rounded
        : isExpense
        ? Icons.arrow_upward_rounded
        : Icons.swap_horiz_rounded;

    final String prefix = isIncome
        ? '+'
        : isExpense
        ? '-'
        : '~';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            AppRouter.transactionDetail,
            arguments: transaction.id,
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Icon
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
              // Name + subtitle
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
              const SizedBox(width: 8),
              // Amount + date
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$prefix${CurrencyFormatter.format(transaction.amount)}',
                    style: AppTheme.monoStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: actionColor,
                    ),
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
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
