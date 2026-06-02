import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../models/transaction_type.dart';
import '../../providers/transaction_type_provider.dart';
import 'transaction_type_form_screen.dart';

class TransactionTypeListScreen extends StatefulWidget {
  const TransactionTypeListScreen({super.key});

  @override
  State<TransactionTypeListScreen> createState() =>
      _TransactionTypeListScreenState();
}

class _TransactionTypeListScreenState
    extends State<TransactionTypeListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TransactionTypeProvider>().loadAll();
    });
  }

  // ---- Helpers --------------------------------------------------------------

  Color _actionColor(String action) {
    switch (action) {
      case AppConstants.actionAddition:
        return AppTheme.incomeColor;
      case AppConstants.actionDeduction:
        return AppTheme.expenseColor;
      default:
        return AppTheme.outline;
    }
  }

  Color _actionBgColor(String action) {
    switch (action) {
      case AppConstants.actionAddition:
        return AppTheme.incomeColor.withOpacity(0.1);
      case AppConstants.actionDeduction:
        return AppTheme.expenseColor.withOpacity(0.1);
      default:
        return AppTheme.surfaceContainerHigh;
    }
  }

  String _actionLabel(String action) {
    switch (action) {
      case AppConstants.actionAddition:
        return 'Penambahan';
      case AppConstants.actionDeduction:
        return 'Pengurangan';
      default:
        return 'Netral';
    }
  }

  IconData _actionIcon(String action) {
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

  Future<void> _openForm({TransactionTypeModel? type}) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => TransactionTypeFormScreen(type: type),
      ),
    );
    if (result == true && mounted) {
      context.read<TransactionTypeProvider>().loadAll();
    }
  }

  Future<void> _confirmDelete(
      BuildContext context, TransactionTypeModel type) async {
    final provider = context.read<TransactionTypeProvider>();
    final messenger = ScaffoldMessenger.of(context);
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Tipe Transaksi'),
        content: RichText(
          text: TextSpan(
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppTheme.onSurface,
              height: 1.5,
            ),
            children: [
              const TextSpan(text: 'Hapus tipe '),
              TextSpan(
                text: '"${type.name}"',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const TextSpan(
                text: '?\n\nData akan ditandai untuk dihapus dan '
                    'disinkronkan ke server saat online.',
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
            style:
                ElevatedButton.styleFrom(backgroundColor: AppTheme.expenseColor),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await provider.delete(type.id);
      messenger.showSnackBar(
        SnackBar(
          content: Text('"${type.name}" dihapus'),
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
        title: const Text('Tipe Transaksi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => context.read<TransactionTypeProvider>().loadAll(),
            tooltip: 'Muat ulang',
          ),
        ],
      ),
      body: Consumer<TransactionTypeProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.errorMessage != null) {
            return _buildErrorState(provider.errorMessage!);
          }

          if (provider.types.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: provider.loadAll,
            color: AppTheme.primary,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              itemCount: provider.types.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final type = provider.types[index];
                return _TypeTile(
                  type: type,
                  actionColor: _actionColor(type.action),
                  actionBgColor: _actionBgColor(type.action),
                  actionLabel: _actionLabel(type.action),
                  actionIcon: _actionIcon(type.action),
                  onTap: () => _openForm(type: type),
                  onDelete: () => _confirmDelete(context, type),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_tx_type',
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
              child: const Icon(Icons.category_outlined,
                  size: 36, color: AppTheme.outline),
            ),
            const SizedBox(height: 20),
            Text(
              'Belum Ada Tipe Transaksi',
              style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.onSurface),
            ),
            const SizedBox(height: 8),
            Text(
              'Ketuk tombol + untuk menambahkan\ntipe transaksi baru.',
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
                  context.read<TransactionTypeProvider>().loadAll(),
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

class _TypeTile extends StatelessWidget {
  final TransactionTypeModel type;
  final Color actionColor;
  final Color actionBgColor;
  final String actionLabel;
  final IconData actionIcon;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _TypeTile({
    required this.type,
    required this.actionColor,
    required this.actionBgColor,
    required this.actionLabel,
    required this.actionIcon,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(type.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        onDelete();
        return false; // Let the provider handle UI removal
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
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                // Action icon
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: actionBgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(actionIcon, color: actionColor, size: 22),
                ),
                const SizedBox(width: 14),
                // Name & description
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        type.name,
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.onSurface,
                        ),
                      ),
                      if (type.description != null &&
                          type.description!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          type.description!,
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
                const SizedBox(width: 8),
                // Action badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: actionBgColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    actionLabel,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: actionColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
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
