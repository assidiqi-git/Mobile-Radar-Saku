import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/app_router.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/activity_item.dart';
import '../../models/transaction.dart';
import '../../models/transfer.dart';

/// A list-item widget that renders either a [TransactionModel] or a
/// [TransferModel] inside the unified activity feed.
///
/// Used in:
///  - Dashboard "Transaksi Terkini"
///  - AllTransactionsScreen "Semua Aktivitas"
class ActivityListItem extends StatelessWidget {
  final ActivityItem item;

  /// Whether the current user is a guest (hides error/pending badges).
  final bool isGuest;

  /// When true, the item uses [horizontal: 20] margin (dashboard style).
  /// When false, it uses no outer horizontal margin (AllTransactions style).
  final bool withHorizontalMargin;

  const ActivityListItem({
    super.key,
    required this.item,
    this.isGuest = false,
    this.withHorizontalMargin = false,
  });

  @override
  Widget build(BuildContext context) {
    if (item.isTransfer) {
      return _TransferItem(
        transfer: item.transfer!,
        withHorizontalMargin: withHorizontalMargin,
      );
    }
    return _TransactionItem(
      transaction: item.transaction!,
      isGuest: isGuest,
      withHorizontalMargin: withHorizontalMargin,
    );
  }
}

// ── Transfer Item ──────────────────────────────────────────────────────────────

class _TransferItem extends StatelessWidget {
  final TransferModel transfer;
  final bool withHorizontalMargin;

  const _TransferItem({
    required this.transfer,
    required this.withHorizontalMargin,
  });

  @override
  Widget build(BuildContext context) {
    final fromName = transfer.fromWallet?.name ?? transfer.fromWalletId;
    final toName = transfer.toWallet?.name ?? transfer.toWalletId;
    final subtitle = '$fromName → $toName';

    final date =
        DateTime.tryParse(transfer.transferDate) ??
        DateTime.tryParse(transfer.createdAt ?? '');

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: withHorizontalMargin ? 20 : 0,
        vertical: 4,
      ),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.onSurfaceVariant.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.swap_horiz_rounded,
              color: AppTheme.onSurfaceVariant,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          // Name + subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transfer.note?.isNotEmpty == true
                      ? transfer.note!
                      : 'Transfer',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '$subtitle',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppTheme.outline,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
                '~${CurrencyFormatter.format(transfer.amount)}',
                style: AppTheme.monoStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                DateFormatter.relativeTime(date),
                style: GoogleFonts.inter(fontSize: 10, color: AppTheme.outline),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Transaction Item ───────────────────────────────────────────────────────────

class _TransactionItem extends StatelessWidget {
  final TransactionModel transaction;
  final bool isGuest;
  final bool withHorizontalMargin;

  const _TransactionItem({
    required this.transaction,
    required this.isGuest,
    required this.withHorizontalMargin,
  });

  void _showErrorDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error_outline_rounded, color: AppTheme.error, size: 20),
            SizedBox(width: 8),
            Text('Transaksi Bermasalah'),
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
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
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
    final action = transaction.transactionCategory?.transactionType?.action;
    final isIncome = action == AppConstants.actionAddition;
    final isExpense = action == AppConstants.actionDeduction;

    final hasError = transaction.hasError;

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
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.onSurfaceVariant,
          );

    final IconData actionIcon = hasError
        ? Icons.error_outline_rounded
        : isIncome
        ? Icons.arrow_downward_rounded
        : isExpense
        ? Icons.arrow_upward_rounded
        : Icons.swap_horiz_rounded;

    final Color actionColor = hasError
        ? AppTheme.error
        : isIncome
        ? AppTheme.incomeColor
        : isExpense
        ? AppTheme.expenseColor
        : AppTheme.onSurfaceVariant;

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
        margin: EdgeInsets.symmetric(
          horizontal: withHorizontalMargin ? 20 : 0,
          vertical: 4,
        ),
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
                        Flexible(
                          child: Text(
                            transaction.transactionCategory!.name,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: AppTheme.outline,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Text(
                        //   ' · ${DateFormatter.relativeTime(DateTime.tryParse(transaction.createdAt ?? ''))}',
                        //   style: GoogleFonts.inter(
                        //     fontSize: 11,
                        //     color: AppTheme.outline,
                        //   ),
                        // ),
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$amountPrefix${CurrencyFormatter.format(transaction.amount)}',
                  style: amountStyle,
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormatter.relativeTime(
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
