import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';

class SummaryMetrics extends StatelessWidget {
  final double totalIncome;
  final double totalExpense;

  const SummaryMetrics({
    super.key,
    required this.totalIncome,
    required this.totalExpense,
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
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Arus Kas Bersih',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.onSurfaceVariant,
                ),
              ),
              Text(
                CurrencyFormatter.format(netFlow),
                style: AppTheme.monoStyle(
                  fontSize: 16,
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
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
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
