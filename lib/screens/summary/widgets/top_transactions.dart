import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/app_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/transaction.dart';

class TopTransactions extends StatelessWidget {
  final List<TransactionModel> transactions;

  const TopTransactions({super.key, required this.transactions});

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Pengeluaran Terbesar',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.onSurface,
                ),
              ),
              Icon(Icons.star_rounded, color: AppTheme.expenseColor, size: 20),
            ],
          ),
          const SizedBox(height: 16),
          ...transactions.map((tx) => _buildTransactionItem(context, tx)),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(BuildContext context, TransactionModel tx) {
    final isExpense =
        tx.transactionCategory?.transactionType?.action ==
        AppConstants.actionDeduction;

    return InkWell(
      onTap: () {
        Navigator.pushNamed(
          context,
          AppRouter.transactionDetail,
          arguments: tx.id,
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isExpense
                    ? AppTheme.expenseColor.withValues(alpha: 0.1)
                    : AppTheme.incomeColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isExpense
                    ? Icons.arrow_upward_rounded
                    : Icons.arrow_downward_rounded,
                color: isExpense ? AppTheme.expenseColor : AppTheme.incomeColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tx.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    tx.transactionCategory?.name ?? '-',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppTheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              CurrencyFormatter.format(tx.amount),
              style: AppTheme.monoStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isExpense ? AppTheme.expenseColor : AppTheme.incomeColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
