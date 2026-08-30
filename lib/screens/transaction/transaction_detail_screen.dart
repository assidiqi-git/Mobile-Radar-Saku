import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../providers/auth_provider.dart';
import '../../providers/sync_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../services/sync_manager.dart';
import '../../models/transaction.dart';

class TransactionDetailScreen extends StatefulWidget {
  final String transactionId;

  const TransactionDetailScreen({super.key, required this.transactionId});

  @override
  State<TransactionDetailScreen> createState() =>
      _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final txProvider = context.watch<TransactionProvider>();
    final isGuest = context.watch<AuthProvider>().isGuest;
    final txList = txProvider.transactions.where(
      (t) => t.id == widget.transactionId,
    );
    if (txList.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detail Transaksi')),
        body: const Center(child: Text('Transaksi tidak ditemukan')),
      );
    }
    final tx = txList.first;

    final action =
        tx.transactionCategory?.transactionType?.action ??
        AppConstants.actionNeutral;

    // Formatting Amount
    final formattedAmount = CurrencyFormatter.format(tx.amount);
    String displayAmount = formattedAmount;
    Color amountColor = AppTheme.onSurface;
    if (action == AppConstants.actionAddition) {
      amountColor = AppTheme.incomeColor;
    } else if (action == AppConstants.actionDeduction) {
      amountColor = AppTheme.expenseColor;
    }

    final isIncome = action == AppConstants.actionAddition;
    final isExpense = action == AppConstants.actionDeduction;

    final IconData actionIcon = tx.hasError
        ? Icons.error_outline_rounded
        : isIncome
        ? Icons.arrow_downward_rounded
        : isExpense
        ? Icons.arrow_upward_rounded
        : Icons.swap_horiz_rounded;

    final Color actionColor = tx.hasError
        ? AppTheme.error
        : isIncome
        ? AppTheme.incomeColor
        : isExpense
        ? AppTheme.expenseColor
        : AppTheme.onSurfaceVariant;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Transaksi'),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: AppTheme.error,
            ),
            onPressed: () => _confirmDelete(context, tx),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          16 + MediaQuery.of(context).padding.bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Nominal Section
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 24),
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: actionColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              actionIcon,
                              color: actionColor,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                      Text(
                        displayAmount,
                        style: AppTheme.monoStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: amountColor,
                        ),
                      ),
                    ],
                  ),
                  if (!isGuest) ...[
                    const SizedBox(height: 16),
                    _buildSyncBadge(tx.syncStatus),
                    if (tx.syncStatus == AppConstants.syncStatusError &&
                        tx.syncErrorMessage != null) ...[
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          tx.syncErrorMessage!,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppTheme.error,
                          ),
                        ),
                      ),
                    ],
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
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow(
                    'Nama',
                    tx.name,
                    icon: Icons.label_outline_rounded,
                    onEdit: () => _editName(context, tx),
                  ),
                  const Divider(
                    height: 24,
                    thickness: 1,
                    color: Color(0xFFF1F5F9),
                  ),
                  _buildDetailRow(
                    'Tanggal',
                    DateFormatter.displayFull(
                      DateFormatter.fromApiString(tx.createdAt),
                    ),
                    icon: Icons.calendar_today_rounded,
                  ),
                  const Divider(
                    height: 24,
                    thickness: 1,
                    color: Color(0xFFF1F5F9),
                  ),
                  _buildDetailRow(
                    'Kategori',
                    tx.transactionCategory?.name ?? '-',
                    icon: Icons.category_rounded,
                  ),
                  const Divider(
                    height: 24,
                    thickness: 1,
                    color: Color(0xFFF1F5F9),
                  ),
                  _buildDetailRow(
                    'Dompet',
                    tx.wallet?.name ?? '-',
                    icon: Icons.account_balance_wallet_rounded,
                  ),
                  if (tx.note != null && tx.note!.isNotEmpty) ...[
                    const Divider(
                      height: 24,
                      thickness: 1,
                      color: Color(0xFFF1F5F9),
                    ),
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
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Image.network(
                  tx.photoUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 150,
                    color: AppTheme.surfaceContainerHigh,
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.broken_image_rounded,
                      color: AppTheme.outline,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Dialog edit nama transaksi.
  Future<void> _editName(BuildContext context, TransactionModel tx) async {
    final controller = TextEditingController(text: tx.name);
    final formKey = GlobalKey<FormState>();

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Ubah Nama Transaksi',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Form(
                    key: formKey,
                    child: TextFormField(
                      controller: controller,
                      autofocus: true,
                      textCapitalization: TextCapitalization.sentences,
                      maxLength: AppConstants.maxNameLength,
                      decoration: const InputDecoration(
                        labelText: 'Nama',
                        prefixIcon: Icon(Icons.label_outline_rounded),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty)
                          return 'Nama wajib diisi';
                        if (v.trim().length > AppConstants.maxNameLength) {
                          return 'Nama maks ${AppConstants.maxNameLength} karakter';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Batal'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            if (formKey.currentState!.validate()) {
                              Navigator.pop(ctx, true);
                            }
                          },
                          child: const Text('Simpan'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (confirmed != true || !context.mounted) return;

    final newName = controller.text.trim();
    if (newName == tx.name) return; // tidak ada perubahan

    final txProvider = context.read<TransactionProvider>();
    final syncProvider = context.read<SyncProvider>();

    await txProvider.updateTransactionName(tx.id, newName);
    await syncProvider.refreshPendingCount();

    // Fire-and-forget background sync
    SyncManager.instance.push().then((_) {
      syncProvider.refreshPendingCount();
    });

    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Nama berhasil diubah')));
  }

  Widget _buildSyncBadge(String status) {
    Color bgColor;
    Color textColor;
    String label;
    IconData icon;

    switch (status) {
      case AppConstants.syncStatusSynced:
        bgColor = const Color(0xFFD1FAE5);
        textColor = const Color(0xFF065F46);
        label = 'Tersinkronisasi';
        icon = Icons.cloud_done_rounded;
        break;
      case AppConstants.syncStatusError:
        bgColor = const Color(0xFFFEE2E2);
        textColor = const Color(0xFF991B1B);
        label = 'Gagal Sinkronisasi';
        icon = Icons.error_rounded;
        break;
      default:
        bgColor = const Color(0xFFFEF3C7);
        textColor = const Color(0xFF92400E);
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

  Widget _buildDetailRow(
    String label,
    String value, {
    required IconData icon,
    VoidCallback? onEdit,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 20, color: AppTheme.outline),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(fontSize: 12, color: AppTheme.outline),
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
        if (onEdit != null)
          IconButton(
            icon: const Icon(Icons.edit_rounded, size: 18),
            color: AppTheme.outline,
            tooltip: 'Ubah',
            visualDensity: VisualDensity.compact,
            onPressed: onEdit,
          ),
      ],
    );
  }

  void _confirmDelete(BuildContext context, TransactionModel tx) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Hapus Transaksi',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Apakah Anda yakin ingin menghapus transaksi ini?',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppTheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Batal'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.error,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () async {
                          Navigator.pop(ctx);
                          await _performDelete(context, tx);
                        },
                        child: const Text('Hapus'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _performDelete(BuildContext context, TransactionModel tx) async {
    final walletProvider = context.read<WalletProvider>();
    final txProvider = context.read<TransactionProvider>();
    final syncProvider = context.read<SyncProvider>();

    // 1. Revert wallet balance
    final amount = tx.amountDouble;
    final delta = tx.isIncome
        ? -amount
        : tx.isExpense
        ? amount
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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Transaksi berhasil dihapus')));
  }
}
