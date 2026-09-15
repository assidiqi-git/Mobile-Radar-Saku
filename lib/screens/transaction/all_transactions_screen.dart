import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:dropdown_button2/dropdown_button2.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/activity_item.dart';
import '../../providers/auth_provider.dart';
import '../../providers/transaction_category_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/transfer_provider.dart';
import '../../providers/wallet_provider.dart';
import '../components/activity_list_item.dart';

class FilterItem {
  final String id;
  final String label;
  const FilterItem(this.id, this.label);

  @override
  String toString() => label;

  @override
  bool operator ==(Object other) => other is FilterItem && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class AllTransactionsScreen extends StatefulWidget {
  const AllTransactionsScreen({super.key});

  static final GlobalKey keyTransactionFilters = GlobalKey(debugLabel: 'keyTransactionFilters');

  @override
  State<AllTransactionsScreen> createState() => _AllTransactionsScreenState();
}

class _AllTransactionsScreenState extends State<AllTransactionsScreen> {
  final _searchController = TextEditingController();

  String _searchText = '';
  String? _selectedAction; // null = semua, 'addition', 'deduction', 'neutral'
  String? _selectedWalletId;
  String? _selectedCategoryId;
  DateTimeRange? _dateRange;
  /// 'all' | 'transaction' | 'transfer'
  String _selectedActivityType = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<TransactionCategoryProvider>().loadAll();
      }
    });
  }

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
            Container(
              key: AllTransactionsScreen.keyTransactionFilters,
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildActivityTypeFilter(),
                  _buildSearchBar(),
                  if (_selectedActivityType != 'transfer') _buildFilterDropdowns(),
                ],
              ),
            ),
            if (_dateRange != null) _buildDateRangeBadge(),
            Expanded(child: _buildActivityList()),
          ],
        ),
      ),
    );
  }

  // ── App Bar ────────────────────────────────────────────────────────────────

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 8, 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Riwayat',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppTheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  'Semua Aktivitas',
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.onSurface,
                  ),
                ),
              ],
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
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

  // ── Filter Dropdowns ───────────────────────────────────────────────────────
  Widget _buildDropdown2({
    required FilterItem selectedItem,
    required List<FilterItem> items,
    required ValueChanged<FilterItem?> onChanged,
    required double width,
  }) {
    return SizedBox(
      width: width,
      child: DropdownButtonHideUnderline(
        child: DropdownButton2<FilterItem>(
          isExpanded: true,
          valueListenable: ValueNotifier(selectedItem),
          items: items
              .map((item) => DropdownItem<FilterItem>(
                    value: item,
                    height: 40, // Height is now set on the DropdownItem itself
                    child: Text(
                      item.label,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppTheme.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ))
              .toList(),
          onChanged: onChanged,
          buttonStyleData: ButtonStyleData(
            height: 40,
            padding: const EdgeInsets.only(left: 16, right: 14),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppTheme.outlineVariant.withValues(alpha: 0.3),
              ),
            ),
          ),
          iconStyleData: const IconStyleData(
            icon: Icon(Icons.arrow_drop_down_rounded),
            iconSize: 20,
            iconEnabledColor: AppTheme.outline,
          ),
          dropdownStyleData: DropdownStyleData(
            maxHeight: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: AppTheme.surfaceContainerLowest,
            ),
            offset: const Offset(0, -4),
          ),
          menuItemStyleData: const MenuItemStyleData(
            padding: EdgeInsets.symmetric(horizontal: 16),
          ),
        ),
      ),
    );
  }

  // ── Filter Dropdowns ───────────────────────────────────────────────────────

  Widget _buildFilterDropdowns() {
    final wallets = context.watch<WalletProvider>().wallets;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Consumer<TransactionCategoryProvider>(
        builder: (context, catProvider, _) {
          final allCategories = catProvider.categories;
          final filteredCategories = _selectedAction == null
              ? allCategories
              : allCategories
                  .where((c) => c.transactionType?.action == _selectedAction)
                  .toList();

          // 1. Jenis Transaksi
          final jenisItems = const [
            FilterItem('all', 'Semua Transaksi'),
            FilterItem(AppConstants.actionAddition, 'Pemasukan'),
            FilterItem(AppConstants.actionDeduction, 'Pengeluaran'),
            FilterItem(AppConstants.actionNeutral, 'Netral'),
          ];
          final selectedJenis = jenisItems.firstWhere(
            (item) => item.id == (_selectedAction ?? 'all'),
            orElse: () => jenisItems.first,
          );

          // 2. Dompet
          final dompetItems = [
            const FilterItem('all', 'Semua Dompet'),
            ...wallets.map((w) => FilterItem(w.id, w.name)),
          ];
          final selectedDompet = dompetItems.firstWhere(
            (item) => item.id == (_selectedWalletId ?? 'all'),
            orElse: () => dompetItems.first,
          );

          // 3. Kategori
          final kategoriItems = [
            const FilterItem('all', 'Semua Kategori'),
            ...filteredCategories.map((c) => FilterItem(c.id, c.name)),
          ];
          final selectedKategori = kategoriItems.firstWhere(
            (item) => item.id == (_selectedCategoryId ?? 'all'),
            orElse: () => kategoriItems.first,
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Jenis
              _buildDropdown2(
                width: double.infinity,
                selectedItem: selectedJenis,
                items: jenisItems,
                onChanged: (val) {
                  if (val == null) return;
                  setState(() {
                    _selectedAction = val.id == 'all' ? null : val.id;
                    _selectedCategoryId = null;
                  });
                },
              ),
              // Dompet
              if (wallets.isNotEmpty) const SizedBox(height: 12),
              if (wallets.isNotEmpty)
                _buildDropdown2(
                  width: double.infinity,
                  selectedItem: selectedDompet,
                  items: dompetItems,
                  onChanged: (val) {
                    if (val == null) return;
                    setState(() {
                      _selectedWalletId = val.id == 'all' ? null : val.id;
                    });
                  },
                ),
              // Kategori
              if (filteredCategories.isNotEmpty) const SizedBox(height: 12),
              if (filteredCategories.isNotEmpty)
                _buildDropdown2(
                  width: double.infinity,
                  selectedItem: selectedKategori,
                  items: kategoriItems,
                  onChanged: (val) {
                    if (val == null) return;
                    setState(() {
                      _selectedCategoryId = val.id == 'all' ? null : val.id;
                    });
                  },
                ),
            ],
          );
        },
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

  // ── Activity Type Filter ──────────────────────────────────────────────────

  Widget _buildActivityTypeFilter() {
    final types = [
      ('all', 'Semua'),
      ('transaction', 'Transaksi'),
      ('transfer', 'Transfer'),
    ];
    return Container(
      height: 38,
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: types.map((t) {
          final isSelected = _selectedActivityType == t.$1;
          return GestureDetector(
            onTap: () => setState(() {
              _selectedActivityType = t.$1;
              // Reset category filter jika pindah ke Transfer
              if (t.$1 == 'transfer') {
                _selectedAction = null;
                _selectedCategoryId = null;
              }
            }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primary : AppTheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? AppTheme.primary
                      : AppTheme.outlineVariant.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                t.$2,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? Colors.white : AppTheme.onSurface,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Transaction List ───────────────────────────────────────────────────────

  Widget _buildActivityList() {
    return Consumer2<TransactionProvider, TransferProvider>(
      builder: (context, txProvider, transferProvider, _) {
        final isGuest = context.read<AuthProvider>().isGuest;

        final List<ActivityItem> items;
        if (_selectedActivityType == 'transfer') {
          // Only transfers
          final filtered = transferProvider.filterTransfers(
            searchText: _searchText.isEmpty ? null : _searchText,
            walletId: _selectedWalletId,
            startDate: _dateRange?.start,
            endDate: _dateRange?.end,
          );
          items = filtered.map(ActivityItem.fromTransfer).toList();
        } else if (_selectedActivityType == 'transaction') {
          // Only transactions
          final filtered = txProvider.filterTransactions(
            searchText: _searchText.isEmpty ? null : _searchText,
            walletId: _selectedWalletId,
            categoryAction: _selectedAction,
            categoryId: _selectedCategoryId,
            startDate: _dateRange?.start,
            endDate: _dateRange?.end,
          );
          items = filtered.map(ActivityItem.fromTransaction).toList();
        } else {
          // All — merge and sort
          final filteredTx = txProvider.filterTransactions(
            searchText: _searchText.isEmpty ? null : _searchText,
            walletId: _selectedWalletId,
            categoryAction: _selectedAction,
            categoryId: _selectedCategoryId,
            startDate: _dateRange?.start,
            endDate: _dateRange?.end,
          );
          final filteredTf = transferProvider.filterTransfers(
            searchText: _searchText.isEmpty ? null : _searchText,
            walletId: _selectedWalletId,
            startDate: _dateRange?.start,
            endDate: _dateRange?.end,
          );
          items = [
            ...filteredTx.map(ActivityItem.fromTransaction),
            ...filteredTf.map(ActivityItem.fromTransfer),
          ];
          items.sort((a, b) => b.date.compareTo(a.date));
        }

        if (txProvider.isLoading || transferProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (items.isEmpty) {
          return _buildEmptyState();
        }

        // Build date-grouped list
        final groupedItems = <dynamic>[];
        String? currentDateGroup;
        for (final item in items) {
          final dateGroup = DateFormatter.displayDateGroup(item.date);
          if (currentDateGroup != dateGroup) {
            groupedItems.add(dateGroup);
            currentDateGroup = dateGroup;
          }
          groupedItems.add(item);
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
          itemCount: groupedItems.length,
          itemBuilder: (_, i) {
            final entry = groupedItems[i];
            if (entry is String) {
              return Padding(
                padding: const EdgeInsets.only(top: 16, bottom: 8),
                child: Text(
                  entry.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.outline,
                    letterSpacing: 0.5,
                  ),
                ),
              );
            }
            return ActivityListItem(
              item: entry as ActivityItem,
              isGuest: isGuest,
              withHorizontalMargin: false,
            );
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
        _selectedCategoryId != null ||
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
                  _selectedCategoryId = null;
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

// _TransactionItem has been replaced by ActivityListItem.
// See: lib/screens/components/activity_list_item.dart
