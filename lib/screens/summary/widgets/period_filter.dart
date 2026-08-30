import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';

enum SummaryPeriod { today, week, month, year, all }

class PeriodFilter extends StatelessWidget {
  final SummaryPeriod selectedPeriod;
  final ValueChanged<SummaryPeriod> onPeriodChanged;

  const PeriodFilter({
    super.key,
    required this.selectedPeriod,
    required this.onPeriodChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: SummaryPeriod.values.map((period) {
          final isSelected = selectedPeriod == period;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(_getPeriodLabel(period)),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  onPeriodChanged(period);
                }
              },
              backgroundColor: AppTheme.surfaceContainerLow,
              selectedColor: AppTheme.primary,
              labelStyle: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? Colors.white : AppTheme.onSurfaceVariant,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected
                      ? AppTheme.primary
                      : AppTheme.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              showCheckmark: false,
            ),
          );
        }).toList(),
      ),
    );
  }

  String _getPeriodLabel(SummaryPeriod period) {
    switch (period) {
      case SummaryPeriod.today:
        return 'Hari Ini';
      case SummaryPeriod.week:
        return 'Minggu Ini';
      case SummaryPeriod.month:
        return 'Bulan Ini';
      case SummaryPeriod.year:
        return 'Tahun Ini';
      case SummaryPeriod.all:
        return 'Semua';
    }
  }
}
