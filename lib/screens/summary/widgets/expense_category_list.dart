import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';

class ExpenseCategoryList extends StatelessWidget {
  final Map<String, double> categoryData;

  const ExpenseCategoryList({super.key, required this.categoryData});

  final List<Color> _chartColors = const [
    Color(0xFF0284C7), // Blue
    Color(0xFF16A34A), // Green
    Color(0xFFEAB308), // Yellow
    Color(0xFFF97316), // Orange
    Color(0xFF8B5CF6), // Purple
    Color(0xFFEC4899), // Pink
    Color(0xFF14B8A6), // Teal
    Color(0xFFF43F5E), // Rose
  ];

  @override
  Widget build(BuildContext context) {
    if (categoryData.isEmpty) {
      return _buildEmptyState();
    }

    // Sort categories by amount descending
    final sortedEntries = categoryData.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Calculate total
    final totalExpense = sortedEntries.fold(
      0.0,
      (sum, entry) => sum + entry.value,
    );

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
          Text(
            'Pengeluaran per Kategori',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.onSurface,
            ),
          ),
          const SizedBox(height: 20),
          _buildList(sortedEntries, totalExpense),
        ],
      ),
    );
  }

  Widget _buildList(List<MapEntry<String, double>> entries, double total) {
    return Column(
      children: List.generate(entries.length, (i) {
        final entry = entries[i];
        final color = _chartColors[i % _chartColors.length];
        final percentage = (entry.value / total) * 100;

        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        entry.key,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    CurrencyFormatter.format(entry.value),
                    style: AppTheme.monoStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: entry.value / total,
                        backgroundColor: color.withValues(alpha: 0.1),
                        color: color,
                        minHeight: 6,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 40,
                    child: Text(
                      '${percentage.toStringAsFixed(1)}%',
                      textAlign: TextAlign.right,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.outline,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.outlineVariant.withValues(alpha: 0.2),
        ),
      ),
      child: Center(
        child: Column(
          children: [
            const Icon(
              Icons.list_alt_rounded,
              size: 48,
              color: AppTheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'Belum ada data pengeluaran',
              style: GoogleFonts.inter(fontSize: 14, color: AppTheme.outline),
            ),
          ],
        ),
      ),
    );
  }
}
