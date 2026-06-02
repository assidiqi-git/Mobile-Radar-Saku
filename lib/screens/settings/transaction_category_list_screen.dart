import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../models/transaction_category.dart';
import '../../providers/transaction_category_provider.dart';
import 'transaction_category_form_screen.dart';

class TransactionCategoryListScreen extends StatefulWidget {
  const TransactionCategoryListScreen({super.key});

  @override
  State<TransactionCategoryListScreen> createState() =>
      _TransactionCategoryListScreenState();
}

class _TransactionCategoryListScreenState
    extends State<TransactionCategoryListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TransactionCategoryProvider>().loadAll();
    });
  }

  // ---- Helpers --------------------------------------------------------------

  Color _actionColor(String? action) {
    switch (action) {
      case AppConstants.actionAddition:
        return AppTheme.incomeColor;
      case AppConstants.actionDeduction:
        return AppTheme.expenseColor;
      default:
        return AppTheme.outline;
    }
  }

  Color _actionBgColor(String? action) {
    switch (action) {
      case AppConstants.actionAddition:
        return AppTheme.incomeColor.withOpacity(0.1);
      case AppConstants.actionDeduction:
        return AppTheme.expenseColor.withOpacity(0.1);
      default:
        return AppTheme.surfaceContainerHigh;
    }
  }

  IconData _actionIcon(String? action) {
    switch (action) {
      case AppConstants.actionAddition:
        return Icons.arrow_upward_rounded;
      case AppConstants.actionDeduction:
        return Icons.arrow_downward_rounded;
      default:
        return Icons.remove_rounded;
    }
  }

  // ---- Actions --------------------------------------------------------------

  Future<void> _openForm({TransactionCategoryModel? category}) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => TransactionCategoryFormScreen(category: category),
      ),
    );
    if (result == true && mounted) {
      context.read<TransactionCategoryProvider>().loadAll();
    }
  }

  Future<void> _confirmDelete(
      BuildContext context, TransactionCategoryModel cat) async {
    final provider = context.read<TransactionCategoryProvider>();
    final messenger = ScaffoldMessenger.of(context);
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Kategori'),
        content: RichText(
          text: TextSpan(
            style: GoogleFonts.inter(
                fontSize: 14, color: AppTheme.onSurface, height: 1.5),
            children: [
              const TextSpan(text: 'Hapus kategori '),
              TextSpan(
                text: '"${cat.name}"',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const TextSpan(
                text: '?\n\nJika masih ada transaksi yang menggunakan '
                    'kategori ini, server akan menolak penghapusan (konflik 409).',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.expenseColor),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await provider.delete(cat.id);
      messenger.showSnackBar(
        SnackBar(
          content: Text('"${cat.name}" dihapus'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ---- Build ----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Text('Kategori Transaksi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () =>
                context.read<TransactionCategoryProvider>().loadAll(),
            tooltip: 'Muat ulang',
          ),
        ],
      ),
      body: Consumer<TransactionCategoryProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.errorMessage != null) {
            return _buildErrorState(provider.errorMessage!);
          }

          if (provider.categories.isEmpty) {
            return _buildEmptyState();
          }

          // Group categories by type name for sectioned display
          final grouped = <String, List<TransactionCategoryModel>>{};
          for (final cat in provider.categories) {
            final key = cat.transactionType?.name ?? 'Tanpa Tipe';
            grouped.putIfAbsent(key, () => []).add(cat);
          }

          final typeNames = grouped.keys.toList()..sort();

          return RefreshIndicator(
            onRefresh: provider.loadAll,
            color: AppTheme.primary,
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              itemCount: typeNames.length,
              itemBuilder: (context, sectionIdx) {
                final typeName = typeNames[sectionIdx];
                final cats = grouped[typeName]!;
                final action = cats.first.transactionType?.action;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (sectionIdx > 0) const SizedBox(height: 16),
                    // Section header
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 6),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _actionColor(action),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            typeName,
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _actionColor(action),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Category items
                    ...cats.map((cat) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _CategoryTile(
                            category: cat,
                            actionColor: _actionColor(action),
                            actionBgColor: _actionBgColor(action),
                            actionIcon: _actionIcon(action),
                            onTap: () => _openForm(category: cat),
                            onDelete: () => _confirmDelete(context, cat),
                          ),
                        )),
                  ],
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_tx_cat',
        onPressed: () => _openForm(),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.folder_special_outlined,
                  size: 36, color: AppTheme.outline),
            ),
            const SizedBox(height: 20),
            Text(
              'Belum Ada Kategori',
              style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.onSurface),
            ),
            const SizedBox(height: 8),
            Text(
              'Ketuk tombol + untuk menambahkan\nkategori transaksi baru.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  fontSize: 14, color: AppTheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 40, color: AppTheme.error),
            const SizedBox(height: 16),
            Text(message,
                textAlign: TextAlign.center,
                style:
                    GoogleFonts.inter(fontSize: 14, color: AppTheme.onSurface)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () =>
                  context.read<TransactionCategoryProvider>().loadAll(),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tile widget
// ---------------------------------------------------------------------------

class _CategoryTile extends StatelessWidget {
  final TransactionCategoryModel category;
  final Color actionColor;
  final Color actionBgColor;
  final IconData actionIcon;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _CategoryTile({
    required this.category,
    required this.actionColor,
    required this.actionBgColor,
    required this.actionIcon,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(category.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        onDelete();
        return false;
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppTheme.expenseColor.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_outline_rounded,
            color: AppTheme.expenseColor),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: actionBgColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(actionIcon, size: 20, color: actionColor),
                ),
                const SizedBox(width: 12),
                // Name & description
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.name,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.onSurface,
                        ),
                      ),
                      if (category.description != null &&
                          category.description!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          category.description!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppTheme.onSurfaceVariant),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    size: 20, color: AppTheme.outline),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
