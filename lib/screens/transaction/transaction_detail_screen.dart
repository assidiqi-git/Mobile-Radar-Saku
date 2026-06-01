import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../providers/sync_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../services/sync_manager.dart';

class TransactionDetailScreen extends StatelessWidget {
  final String transactionId;

  const TransactionDetailScreen({super.key, required this.transactionId});

  @override
  Widget build(BuildContext context) {
    final txProvider = context.watch<TransactionProvider>();
    // Cari transaksi berdasarkan ID
    final txList = txProvider.transactions.where((t) => t.id == transactionId);
    if (txList.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detail Transaksi')),
        body: const Center(child: Text('Transaksi tidak ditemukan')),
      );
    }
    final tx = txList.first;

    final action = tx.transactionCategory?.transactionType?.action ?? AppConstants.actionNeutral;
    
    // Formatting Amount
    final formattedAmount = CurrencyFormatter.format(tx.amount);
    String displayAmount = formattedAmount;
    Color amountColor = AppTheme.onSurface;
    if (action == AppConstants.actionAddition) {
      displayAmount = '+ $formattedAmount';
      amountColor = AppTheme.incomeColor;
    } else if (action == AppConstants.actionDeduction) {
      displayAmount = '- $formattedAmount';
      amountColor = AppTheme.expenseColor;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Transaksi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.error),
            onPressed: () => _confirmDelete(context, tx, action),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Nominal Section
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
              ),
              child: Column(
                children: [
                  Text(
                    displayAmount,
                    style: AppTheme.monoStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: amountColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSyncBadge(tx.syncStatus),
                  if (tx.syncStatus == AppConstants.syncStatusError && tx.syncErrorMessage != null) ...[
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        tx.syncErrorMessage!,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(fontSize: 12, color: AppTheme.error),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Details Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow(
                    'Kategori',
                    tx.transactionCategory?.name ?? '-',
                    icon: Icons.category_rounded,
                  ),
                  const Divider(height: 24, thickness: 1, color: Color(0xFFF1F5F9)),
                  _buildDetailRow(
                    'Dompet',
                    tx.wallet?.name ?? '-',
                    icon: Icons.account_balance_wallet_rounded,
                  ),
                  const Divider(height: 24, thickness: 1, color: Color(0xFFF1F5F9)),
                  _buildDetailRow(
                    'Tanggal',
                    DateFormatter.displayFull(DateFormatter.fromApiString(tx.createdAt)),
                    icon: Icons.calendar_today_rounded,
                  ),
                  if (tx.note != null && tx.note!.isNotEmpty) ...[
                    const Divider(height: 24, thickness: 1, color: Color(0xFFF1F5F9)),
                    _buildDetailRow(
                      'Catatan',
                      tx.note!,
                      icon: Icons.notes_rounded,
                    ),
                  ],
                ],
              ),
            ),

            if (tx.photoUrl != null && tx.photoUrl!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
                ),
                child: Image.network(
                  tx.photoUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 150,
                    color: AppTheme.surfaceContainerHigh,
                    alignment: Alignment.center,
                    child: const Icon(Icons.broken_image_rounded, color: AppTheme.outline),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSyncBadge(String status) {
    Color bgColor;
    Color textColor;
    String label;
    IconData icon;

    switch (status) {
      case AppConstants.syncStatusSynced:
        bgColor = const Color(0xFFD1FAE5); // emerald-100
        textColor = const Color(0xFF065F46); // emerald-800
        label = 'Tersinkronisasi';
        icon = Icons.cloud_done_rounded;
        break;
      case AppConstants.syncStatusError:
        bgColor = const Color(0xFFFEE2E2); // red-100
        textColor = const Color(0xFF991B1B); // red-800
        label = 'Gagal Sinkronisasi';
        icon = Icons.error_rounded;
        break;
      default: // pending
        bgColor = const Color(0xFFFEF3C7); // amber-100
        textColor = const Color(0xFF92400E); // amber-800
        label = 'Menunggu Sinkronisasi';
        icon = Icons.cloud_upload_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {required IconData icon}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppTheme.outline),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppTheme.outline,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _confirmDelete(BuildContext context, tx, String action) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Transaksi'),
        content: const Text('Apakah Anda yakin ingin menghapus transaksi ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () async {
              Navigator.pop(ctx); // Tutup dialog
              await _performDelete(context, tx, action);
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _performDelete(BuildContext context, tx, String action) async {
    final walletProvider = context.read<WalletProvider>();
    final txProvider = context.read<TransactionProvider>();
    final syncProvider = context.read<SyncProvider>();

    // 1. Revert wallet balance
    final amount = double.tryParse(tx.amount) ?? 0.0;
    final delta = action == AppConstants.actionAddition
        ? -amount // if it was addition, we deduct to revert
        : action == AppConstants.actionDeduction
            ? amount // if it was deduction, we add to revert
            : 0.0;
            
    if (delta != 0) {
      await walletProvider.mutateBalance(tx.walletId, delta);
    }

    // 2. Soft-delete in provider
    await txProvider.deleteTransaction(tx.id);

    // 3. Trigger sync and update badge
    await syncProvider.refreshPendingCount();
    SyncManager.instance.push().then((_) {
      syncProvider.refreshPendingCount();
    });

    if (!context.mounted) return;
    
    // 4. Pop screen
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Transaksi berhasil dihapus')),
    );
  }
}
