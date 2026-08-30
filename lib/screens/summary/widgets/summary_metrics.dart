import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';

class SummaryMetrics extends StatelessWidget {
  final double totalIncome;
  final double totalExpense;
  final double? changePercent;
  final double? incomeChangePercent;
  final double? expenseChangePercent;

  const SummaryMetrics({
    super.key,
    required this.totalIncome,
    required this.totalExpense,
    this.changePercent,
    this.incomeChangePercent,
    this.expenseChangePercent,
  });

  double get netFlow => totalIncome - totalExpense;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
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
        children: [
          Row(
            children: [
              Expanded(
                child: _buildMetricItem(
                  title: 'Pemasukan',
                  amount: totalIncome,
                  color: AppTheme.incomeColor,
                  icon: Icons.arrow_downward_rounded,
                  changePercent: incomeChangePercent,
                  isInverse: false,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: AppTheme.outlineVariant.withValues(alpha: 0.3),
              ),
              Expanded(
                child: _buildMetricItem(
                  title: 'Pengeluaran',
                  amount: totalExpense,
                  color: AppTheme.expenseColor,
                  icon: Icons.arrow_upward_rounded,
                  changePercent: expenseChangePercent,
                  isInverse: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          Column(
            children: [
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                children: [
                  Text(
                    'Arus Kas Bersih',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.onSurfaceVariant,
                    ),
                  ),
                  if (changePercent != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: changePercent! >= 0
                            ? AppTheme.incomeColor.withValues(alpha: 0.12)
                            : AppTheme.expenseColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            changePercent! >= 0
                                ? Icons.arrow_upward_rounded
                                : Icons.arrow_downward_rounded,
                            size: 11,
                            color: changePercent! >= 0
                                ? AppTheme.incomeColor
                                : AppTheme.expenseColor,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '${changePercent!.abs().toStringAsFixed(1)}%',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: changePercent! >= 0
                                  ? AppTheme.incomeColor
                                  : AppTheme.expenseColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                CurrencyFormatter.format(netFlow),
                style: AppTheme.monoStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: netFlow >= 0
                      ? AppTheme.incomeColor
                      : AppTheme.expenseColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem({
    required String title,
    required double amount,
    required Color color,
    required IconData icon,
    double? changePercent,
    bool isInverse = false,
  }) {
    final bool isGood = changePercent == null
        ? true
        : (isInverse ? changePercent <= 0 : changePercent >= 0);
    final Color badgeColor = isGood
        ? AppTheme.incomeColor
        : AppTheme.expenseColor;
    final bool isUp = (changePercent ?? 0) >= 0;

    return Column(
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppTheme.onSurfaceVariant,
              ),
            ),
            if (changePercent != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isUp
                          ? Icons.arrow_upward_rounded
                          : Icons.arrow_downward_rounded,
                      size: 10,
                      color: badgeColor,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      changePercent.abs().toStringAsFixed(1) + '%',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: badgeColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Text(
          CurrencyFormatter.format(amount),
          style: AppTheme.monoStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}
