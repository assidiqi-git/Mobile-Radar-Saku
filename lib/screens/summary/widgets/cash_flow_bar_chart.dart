import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';

class CashFlowDataPoint {
  final String label;
  final double income;
  final double expense;

  CashFlowDataPoint({
    required this.label,
    required this.income,
    required this.expense,
  });
}

class CashFlowBarChart extends StatelessWidget {
  final List<CashFlowDataPoint> data;

  const CashFlowBarChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const SizedBox.shrink();
    }

    double maxY = 0;
    for (final dp in data) {
      if (dp.income > maxY) maxY = dp.income;
      if (dp.expense > maxY) maxY = dp.expense;
    }
    // Add 20% padding to top
    maxY = maxY * 1.2;
    if (maxY == 0) maxY = 1000;

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Arus Kas',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.onSurface,
                ),
              ),
              Row(
                children: [
                  _buildLegendDot('Pemasukan', AppTheme.incomeColor),
                  const SizedBox(width: 12),
                  _buildLegendDot('Pengeluaran', AppTheme.expenseColor),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),
          AspectRatio(
            aspectRatio: 1.5,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final isIncome = rodIndex == 0;
                      return BarTooltipItem(
                        '${isIncome ? 'Pemasukan' : 'Pengeluaran'}\n',
                        GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                        children: <TextSpan>[
                          TextSpan(
                            text: CurrencyFormatter.format(rod.toY),
                            style: GoogleFonts.jetBrainsMono(
                              color: isIncome
                                  ? const Color(0xFF6EE7B7)
                                  : const Color(0xFFFDA4AF),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < data.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              data[index].label,
                              style: GoogleFonts.inter(
                                color: AppTheme.outline,
                                fontSize: 11,
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 45,
                      getTitlesWidget: (value, meta) {
                        if (value == 0 || value == maxY)
                          return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: Text(
                            _formatAxisValue(value),
                            textAlign: TextAlign.right,
                            style: GoogleFonts.jetBrainsMono(
                              color: AppTheme.outline,
                              fontSize: 10,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  checkToShowHorizontalLine: (value) => value % (maxY / 4) < 1,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: AppTheme.outlineVariant.withValues(alpha: 0.2),
                    strokeWidth: 1,
                    dashArray: [4, 4],
                  ),
                  drawVerticalLine: false,
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(data.length, (i) {
                  return BarChartGroupData(
                    x: i,
                    barsSpace: 4,
                    barRods: [
                      BarChartRodData(
                        toY: data[i].income,
                        color: AppTheme.incomeColor,
                        width: 8,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                      ),
                      BarChartRodData(
                        toY: data[i].expense,
                        color: AppTheme.expenseColor,
                        width: 8,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendDot(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: AppTheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  String _formatAxisValue(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}jt';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}k';
    }
    return value.toStringAsFixed(0);
  }
}
