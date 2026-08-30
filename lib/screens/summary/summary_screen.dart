import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../models/transaction.dart';
import '../../providers/transaction_provider.dart';
import 'widgets/cash_flow_bar_chart.dart';
import 'widgets/expense_category_list.dart';
import 'widgets/period_filter.dart';
import 'widgets/summary_metrics.dart';
import 'widgets/top_transactions.dart';

class SummaryScreen extends StatefulWidget {
  const SummaryScreen({super.key});

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  SummaryPeriod _selectedPeriod = SummaryPeriod.week;

  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _updateDateRange();
  }

  void _updateDateRange() {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case SummaryPeriod.today:
        _startDate = DateTime(now.year, now.month, now.day);
        _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
      case SummaryPeriod.week:
        final weekday = now.weekday; // 1 = Monday, 7 = Sunday
        _startDate = DateTime(now.year, now.month, now.day - weekday + 1);
        _endDate = _startDate!.add(
          const Duration(days: 6, hours: 23, minutes: 59, seconds: 59),
        );
        break;
      case SummaryPeriod.month:
        _startDate = DateTime(now.year, now.month, 1);
        _endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        break;
      case SummaryPeriod.year:
        _startDate = DateTime(now.year, 1, 1);
        _endDate = DateTime(now.year, 12, 31, 23, 59, 59);
        break;
      case SummaryPeriod.all:
        _startDate = null;
        _endDate = null;
        break;
    }
  }

  List<TransactionModel> _filterTransactions(
    List<TransactionModel> transactions,
  ) {
    if (_startDate == null || _endDate == null) return transactions;
    return transactions.where((tx) {
      final date = DateTime.parse(
        tx.createdAt ?? DateTime.now().toIso8601String(),
      );
      return date.isAfter(_startDate!) && date.isBefore(_endDate!);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: Consumer<TransactionProvider>(
        builder: (context, provider, _) {
          final allTransactions = provider.transactions;
          final filteredTransactions = _filterTransactions(allTransactions);

          double totalIncome = 0;
          double totalExpense = 0;
          Map<String, double> expensesByCategory = {};

          // Lists for top transactions
          List<TransactionModel> expenseTransactions = [];

          for (final tx in filteredTransactions) {
            final amount = tx.amountDouble;
            final action = tx.transactionCategory?.transactionType?.action;

            if (action == AppConstants.actionAddition) {
              totalIncome += amount;
            } else if (action == AppConstants.actionDeduction) {
              totalExpense += amount;
              expenseTransactions.add(tx);

              final catName = tx.transactionCategory?.name ?? 'Lainnya';
              expensesByCategory[catName] =
                  (expensesByCategory[catName] ?? 0) + amount;
            }
          }

          // Sort for top 5 expenses
          expenseTransactions.sort(
            (a, b) => b.amountDouble.compareTo(a.amountDouble),
          );
          final top5Expenses = expenseTransactions.take(5).toList();

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                    child: Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Ringkasan',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: AppTheme.onSurfaceVariant,
                              ),
                            ),
                            Text(
                              'Summary',
                              style: GoogleFonts.outfit(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: PeriodFilter(
                    selectedPeriod: _selectedPeriod,
                    onPeriodChanged: (period) {
                      setState(() {
                        _selectedPeriod = period;
                        _updateDateRange();
                      });
                    },
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SummaryMetrics(
                  totalIncome: totalIncome,
                  totalExpense: totalExpense,
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
              SliverToBoxAdapter(
                child: CashFlowBarChart(
                  data: _generateCashFlowData(filteredTransactions),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
              SliverToBoxAdapter(
                child: ExpenseCategoryList(categoryData: expensesByCategory),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 8)),
              SliverToBoxAdapter(
                child: TopTransactions(transactions: top5Expenses),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: 80),
              ), // Padding for bottom nav
            ],
          );
        },
      ),
    );
  }

  List<CashFlowDataPoint> _generateCashFlowData(
    List<TransactionModel> transactions,
  ) {
    if (transactions.isEmpty) return [];

    if (_selectedPeriod == SummaryPeriod.today ||
        _selectedPeriod == SummaryPeriod.week) {
      // Return 7 days for the week
      Map<int, CashFlowDataPoint> days = {};
      final start =
          _startDate ?? DateTime.now().subtract(const Duration(days: 6));

      for (int i = 0; i < 7; i++) {
        final date = start.add(Duration(days: i));
        final label = _getDayLabel(date.weekday);
        days[date.weekday] = CashFlowDataPoint(
          label: label,
          income: 0,
          expense: 0,
        );
      }

      for (final tx in transactions) {
        final date = DateTime.parse(
          tx.createdAt ?? DateTime.now().toIso8601String(),
        ).toLocal();
        final action = tx.transactionCategory?.transactionType?.action;
        final amount = tx.amountDouble;

        final existing =
            days[date.weekday] ??
            CashFlowDataPoint(
              label: _getDayLabel(date.weekday),
              income: 0,
              expense: 0,
            );

        if (action == AppConstants.actionAddition) {
          days[date.weekday] = CashFlowDataPoint(
            label: existing.label,
            income: existing.income + amount,
            expense: existing.expense,
          );
        } else if (action == AppConstants.actionDeduction) {
          days[date.weekday] = CashFlowDataPoint(
            label: existing.label,
            income: existing.income,
            expense: existing.expense + amount,
          );
        }
      }
      return days.values.toList();
    } else if (_selectedPeriod == SummaryPeriod.month) {
      // Group by weeks in month (approx 4 weeks)
      Map<int, CashFlowDataPoint> weeks = {
        1: CashFlowDataPoint(label: 'Mg 1', income: 0, expense: 0),
        2: CashFlowDataPoint(label: 'Mg 2', income: 0, expense: 0),
        3: CashFlowDataPoint(label: 'Mg 3', income: 0, expense: 0),
        4: CashFlowDataPoint(label: 'Mg 4', income: 0, expense: 0),
      };

      for (final tx in transactions) {
        final date = DateTime.parse(
          tx.createdAt ?? DateTime.now().toIso8601String(),
        ).toLocal();
        final action = tx.transactionCategory?.transactionType?.action;
        final amount = tx.amountDouble;

        int weekNum = ((date.day - 1) / 7).floor() + 1;
        if (weekNum > 4) weekNum = 4; // Combine remaining days into week 4

        final existing = weeks[weekNum]!;
        if (action == AppConstants.actionAddition) {
          weeks[weekNum] = CashFlowDataPoint(
            label: existing.label,
            income: existing.income + amount,
            expense: existing.expense,
          );
        } else if (action == AppConstants.actionDeduction) {
          weeks[weekNum] = CashFlowDataPoint(
            label: existing.label,
            income: existing.income,
            expense: existing.expense + amount,
          );
        }
      }
      return weeks.values.toList();
    } else {
      // Year or All - Group by Months
      Map<int, CashFlowDataPoint> months = {};
      for (int i = 1; i <= 12; i++) {
        months[i] = CashFlowDataPoint(
          label: _getMonthLabel(i),
          income: 0,
          expense: 0,
        );
      }

      for (final tx in transactions) {
        final date = DateTime.parse(
          tx.createdAt ?? DateTime.now().toIso8601String(),
        ).toLocal();
        final action = tx.transactionCategory?.transactionType?.action;
        final amount = tx.amountDouble;

        final existing = months[date.month]!;
        if (action == AppConstants.actionAddition) {
          months[date.month] = CashFlowDataPoint(
            label: existing.label,
            income: existing.income + amount,
            expense: existing.expense,
          );
        } else if (action == AppConstants.actionDeduction) {
          months[date.month] = CashFlowDataPoint(
            label: existing.label,
            income: existing.income,
            expense: existing.expense + amount,
          );
        }
      }
      return months.values.toList();
    }
  }

  String _getDayLabel(int weekday) {
    const days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    return days[weekday - 1];
  }

  String _getMonthLabel(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Ags',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return months[month - 1];
  }
}
