import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/book.dart';
import '../models/transaction.dart';
import '../code/app_theme.dart';
import '../providers/transaction_provider.dart';

class ReportScreen extends ConsumerStatefulWidget {
  final Book book;

  const ReportScreen({super.key, required this.book});

  @override
  ConsumerState<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends ConsumerState<ReportScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _touchedPieIndex = -1;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Get transactions for the current week (Mon-Sun)
  List<Transaction> _getWeeklyTransactions(List<Transaction> all) {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final startOfWeek = DateTime(monday.year, monday.month, monday.day);
    final endOfWeek = startOfWeek.add(const Duration(days: 7));
    return all
        .where((t) =>
            t.date.isAfter(startOfWeek.subtract(const Duration(seconds: 1))) &&
            t.date.isBefore(endOfWeek))
        .toList();
  }

  // Get transactions for the current month
  List<Transaction> _getMonthlyTransactions(List<Transaction> all) {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    return all
        .where((t) =>
            t.date.isAfter(startOfMonth.subtract(const Duration(seconds: 1))) &&
            t.date.isBefore(endOfMonth.add(const Duration(seconds: 1))))
        .toList();
  }

  Map<String, double> _groupByCategory(
      List<Transaction> txns, TransactionType type) {
    final map = <String, double>{};
    for (var t in txns) {
      if (t.type == type) {
        map[t.category] = (map[t.category] ?? 0) + t.amount;
      }
    }
    return map;
  }

  // Group daily totals for the bar chart (7 days for weekly, ~30 for monthly)
  Map<String, Map<String, double>> _groupDaily(List<Transaction> txns,
      {required bool isWeekly}) {
    final map = <String, Map<String, double>>{};
    final now = DateTime.now();

    if (isWeekly) {
      final monday = now.subtract(Duration(days: now.weekday - 1));
      for (int i = 0; i < 7; i++) {
        final day = monday.add(Duration(days: i));
        final key = DateFormat('E').format(day); // Mon, Tue, etc.
        map[key] = {'income': 0, 'expense': 0};
      }
      for (var t in txns) {
        final key = DateFormat('E').format(t.date);
        if (map.containsKey(key)) {
          if (t.type == TransactionType.income) {
            map[key]!['income'] = (map[key]!['income'] ?? 0) + t.amount;
          } else {
            map[key]!['expense'] = (map[key]!['expense'] ?? 0) + t.amount;
          }
        }
      }
    } else {
      // Monthly: group by week number within the month
      final startOfMonth = DateTime(now.year, now.month, 1);
      final daysInMonth = DateTime(now.year, now.month + 1, 0).day;

      // Create week labels
      for (int week = 0;
          week < ((daysInMonth + startOfMonth.weekday - 1) / 7).ceil();
          week++) {
        final weekStart = week * 7 + 1 - (startOfMonth.weekday - 1);
        final weekEnd = weekStart + 6;
        final label = 'W${week + 1}';
        map[label] = {'income': 0, 'expense': 0};
      }

      for (var t in txns) {
        if (t.date.month == now.month && t.date.year == now.year) {
          final weekIndex =
              ((t.date.day + startOfMonth.weekday - 2) / 7).floor();
          final label = 'W${weekIndex + 1}';
          if (map.containsKey(label)) {
            if (t.type == TransactionType.income) {
              map[label]!['income'] = (map[label]!['income'] ?? 0) + t.amount;
            } else {
              map[label]!['expense'] = (map[label]!['expense'] ?? 0) + t.amount;
            }
          }
        }
      }
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final transactionsAsync =
        ref.watch(bookTransactionsProvider(widget.book.id));
    final bookColor = Color(int.parse('FF${widget.book.color}', radix: 16));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text(
          'Report',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textHint,
          indicatorColor: AppColors.primary,
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle:
              GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
          unselectedLabelStyle:
              GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w400),
          tabs: const [
            Tab(text: 'This Week'),
            Tab(text: 'This Month'),
          ],
        ),
      ),
      body: transactionsAsync.when(
        data: (allTransactions) {
          return TabBarView(
            controller: _tabController,
            children: [
              _buildReportTab(allTransactions,
                  isWeekly: true, bookColor: bookColor),
              _buildReportTab(allTransactions,
                  isWeekly: false, bookColor: bookColor),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildReportTab(List<Transaction> allTransactions,
      {required bool isWeekly, required Color bookColor}) {
    final txns = isWeekly
        ? _getWeeklyTransactions(allTransactions)
        : _getMonthlyTransactions(allTransactions);

    final incomeByCategory = _groupByCategory(txns, TransactionType.income);
    final expenseByCategory = _groupByCategory(txns, TransactionType.expense);
    final dailyData = _groupDaily(txns, isWeekly: isWeekly);

    double totalIncome = 0;
    double totalExpense = 0;
    for (var t in txns) {
      if (t.type == TransactionType.income) {
        totalIncome += t.amount;
      } else {
        totalExpense += t.amount;
      }
    }

    final currencyFormat =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    if (txns.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart_rounded, size: 72, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              isWeekly ? 'No data this week' : 'No data this month',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add transactions to see your report',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppColors.textHint,
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary cards
          _buildSummaryRow(totalIncome, totalExpense, currencyFormat),
          const SizedBox(height: 28),

          // Bar chart
          _buildSectionTitle('Income vs Expense'),
          const SizedBox(height: 16),
          _buildBarChart(dailyData, bookColor),
          const SizedBox(height: 32),

          // Expense pie chart
          if (expenseByCategory.isNotEmpty) ...[
            _buildSectionTitle('Expense Breakdown'),
            const SizedBox(height: 16),
            _buildPieChart(expenseByCategory, totalExpense, currencyFormat,
                isExpense: true),
            const SizedBox(height: 32),
          ],

          // Income pie chart
          if (incomeByCategory.isNotEmpty) ...[
            _buildSectionTitle('Income Breakdown'),
            const SizedBox(height: 16),
            _buildPieChart(incomeByCategory, totalIncome, currencyFormat,
                isExpense: false),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildSummaryRow(double income, double expense, NumberFormat fmt) {
    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            label: 'Income',
            amount: fmt.format(income),
            color: AppColors.income,
            bgColor: AppColors.incomeBg,
            icon: Icons.trending_up_rounded,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            label: 'Expense',
            amount: fmt.format(expense),
            color: AppColors.expense,
            bgColor: AppColors.expenseBg,
            icon: Icons.trending_down_rounded,
          ),
        ),
      ],
    );
  }

  Widget _buildBarChart(
      Map<String, Map<String, double>> dailyData, Color bookColor) {
    final entries = dailyData.entries.toList();
    final maxVal = entries.fold<double>(
        0,
        (m, e) => [m, e.value['income'] ?? 0, e.value['expense'] ?? 0]
            .reduce((a, b) => a > b ? a : b));

    return Container(
      height: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxVal * 1.2,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final label = rodIndex == 0 ? 'Income' : 'Expense';
                return BarTooltipItem(
                  '$label\n${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(rod.toY)}',
                  GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= entries.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      entries[idx].key,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  );
                },
                reservedSize: 28,
              ),
            ),
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxVal > 0 ? maxVal / 4 : 1,
            getDrawingHorizontalLine: (value) => FlLine(
              color: AppColors.border.withOpacity(0.5),
              strokeWidth: 1,
              dashArray: [5, 5],
            ),
          ),
          barGroups: List.generate(entries.length, (i) {
            final entry = entries[i];
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: entry.value['income'] ?? 0,
                  color: AppColors.income,
                  width: entries.length > 5 ? 8 : 14,
                  borderRadius: BorderRadius.circular(4),
                ),
                BarChartRodData(
                  toY: entry.value['expense'] ?? 0,
                  color: AppColors.expense,
                  width: entries.length > 5 ? 8 : 14,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
              barsSpace: 3,
            );
          }),
        ),
        swapAnimationDuration: const Duration(milliseconds: 400),
        swapAnimationCurve: Curves.easeInOutCubic,
      ),
    );
  }

  Widget _buildPieChart(
      Map<String, double> data, double total, NumberFormat fmt,
      {required bool isExpense}) {
    final entries = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final colors = isExpense
        ? [
            const Color(0xFFFF6B8A),
            const Color(0xFFFF9E7C),
            const Color(0xFFFFB347),
            const Color(0xFFFFD93D),
            const Color(0xFFC9B1FF),
            const Color(0xFFFF8A80),
            const Color(0xFFE57373),
            const Color(0xFFFFAB91),
          ]
        : [
            const Color(0xFF00C9A7),
            const Color(0xFF4ECDC4),
            const Color(0xFF82B1FF),
            const Color(0xFF5B5FEF),
            const Color(0xFF7C7FFF),
            const Color(0xFF00D9A6),
            const Color(0xFF26A69A),
            const Color(0xFF80CBC4),
          ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                pieTouchData: PieTouchData(
                  touchCallback: (event, pieTouchResponse) {
                    setState(() {
                      if (!event.isInterestedForInteractions ||
                          pieTouchResponse == null ||
                          pieTouchResponse.touchedSection == null) {
                        _touchedPieIndex = -1;
                        return;
                      }
                      _touchedPieIndex =
                          pieTouchResponse.touchedSection!.touchedSectionIndex;
                    });
                  },
                ),
                borderData: FlBorderData(show: false),
                sectionsSpace: 2,
                centerSpaceRadius: 50,
                sections: List.generate(entries.length, (i) {
                  final isTouched = i == _touchedPieIndex;
                  final fontSize = isTouched ? 14.0 : 12.0;
                  final radius = isTouched ? 45.0 : 38.0;
                  final pct = (entries[i].value / total * 100);

                  return PieChartSectionData(
                    color: colors[i % colors.length],
                    value: entries[i].value,
                    title: '${pct.toStringAsFixed(0)}%',
                    radius: radius,
                    titleStyle: GoogleFonts.poppins(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    titlePositionPercentageOffset: 0.55,
                  );
                }),
              ),
              swapAnimationDuration: const Duration(milliseconds: 400),
              swapAnimationCurve: Curves.easeInOutCubic,
            ),
          ),
          const SizedBox(height: 20),
          // Legend
          ...List.generate(entries.length, (i) {
            final pct = (entries[i].value / total * 100);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: colors[i % colors.length],
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      entries[i].key,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Text(
                    fmt.format(entries[i].value),
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 40,
                    child: Text(
                      '${pct.toStringAsFixed(0)}%',
                      textAlign: TextAlign.right,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String amount;
  final Color color;
  final Color bgColor;
  final IconData icon;

  const _SummaryCard({
    required this.label,
    required this.amount,
    required this.color,
    required this.bgColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              amount,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
