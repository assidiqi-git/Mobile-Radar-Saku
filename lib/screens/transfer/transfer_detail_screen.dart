import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../providers/auth_provider.dart';
import '../../providers/transfer_provider.dart';

class TransferDetailScreen extends StatelessWidget {
  final String transferId;

  const TransferDetailScreen({super.key, required this.transferId});

  @override
  Widget build(BuildContext context) {
    final transferProvider = context.watch<TransferProvider>();
    final isGuest = context.watch<AuthProvider>().isGuest;

    final transferList = transferProvider.transfers.where(
      (t) => t.id == transferId,
    );

    if (transferList.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detail Transfer')),
        body: const Center(child: Text('Transfer tidak ditemukan')),
      );
    }

    final transfer = transferList.first;

    final formattedAmount = CurrencyFormatter.format(transfer.amount);
    final actionColor = transfer.syncStatus == 'error'
        ? AppTheme.error
        : AppTheme.onSurfaceVariant;

    final actionIcon = transfer.syncStatus == 'error'
        ? Icons.error_outline_rounded
        : Icons.swap_horiz_rounded;

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Transfer')),
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
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
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
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: actionColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(actionIcon, color: actionColor, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        formattedAmount,
                        style: AppTheme.monoStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                  if (!isGuest) ...[
                    const SizedBox(width: 16),
                    _buildSyncBadge(transfer.syncStatus),
                  ],
                ],
              ),
            ),

            if (!isGuest &&
                transfer.syncStatus == 'error' &&
                transfer.syncErrorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                transfer.syncErrorMessage!,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 12, color: AppTheme.error),
              ),
            ],

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
                    'Dari Dompet',
                    transfer.fromWallet?.name ?? transfer.fromWalletId,
                    icon: Icons.account_balance_wallet_rounded,
                  ),
                  const Divider(
                    height: 24,
                    thickness: 1,
                    color: Color(0xFFF1F5F9),
                  ),
                  _buildDetailRow(
                    'Ke Dompet',
                    transfer.toWallet?.name ?? transfer.toWalletId,
                    icon: Icons.account_balance_wallet_outlined,
                  ),
                  const Divider(
                    height: 24,
                    thickness: 1,
                    color: Color(0xFFF1F5F9),
                  ),
                  _buildDetailRow(
                    'Tanggal',
                    DateFormatter.displayFull(
                      DateTime.tryParse(transfer.transferDate) ??
                          DateTime.tryParse(transfer.createdAt ?? '') ??
                          DateTime.now(),
                    ),
                    icon: Icons.calendar_today_rounded,
                  ),
                    const Divider(
                      height: 24,
                      thickness: 1,
                      color: Color(0xFFF1F5F9),
                    ),
                    _buildDetailRow(
                      'Biaya Transfer',
                      CurrencyFormatter.format(transfer.fee),
                      icon: Icons.money_off_rounded,
                    ),
                  if (transfer.note != null && transfer.note!.isNotEmpty) ...[
                    const Divider(
                      height: 24,
                      thickness: 1,
                      color: Color(0xFFF1F5F9),
                    ),
                    _buildDetailRow(
                      'Catatan',
                      transfer.note!,
                      icon: Icons.notes_rounded,
                    ),
                  ],
                ],
              ),
            ),
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
      case 'synced':
        bgColor = const Color(0xFFD1FAE5);
        textColor = const Color(0xFF065F46);
        label = 'Tersinkronisasi';
        icon = Icons.cloud_done_rounded;
        break;
      case 'error':
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

  Widget _buildDetailRow(String label, String value, {required IconData icon}) {
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
      ],
    );
  }
}
