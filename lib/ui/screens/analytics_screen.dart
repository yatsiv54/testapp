import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:community_charts_flutter/community_charts_flutter.dart'
    as charts;
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'dart:ui';
import 'package:path_provider/path_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/currency_helper.dart';
import '../../viewmodels/expenses_list_viewmodel.dart';
import '../../viewmodels/home_viewmodel.dart';
import '../../viewmodels/settings_viewmodel.dart';
import '../../data/models/expense.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/loading_shimmer_widget.dart';
import '../widgets/error_state_widget.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  String _selectedPeriod = 'All Time';
  final List<String> _periods = ['Week', 'Month', 'Year', 'All Time'];

  Future<void> _exportData(
    List<Expense> expenses, [
    Rect? sharePositionOrigin,
  ]) async {
    try {
      if (expenses.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('No data to export')));
        return;
      }
      final StringBuffer csv = StringBuffer();
      csv.writeln('ID,Amount,Currency,Category,Date,Comment');
      for (var e in expenses) {
        csv.writeln(
          '${e.id},${e.amount},${e.currency},${e.category},${e.date.toIso8601String()},"${e.comment.replaceAll('"', '""')}"',
        );
      }
      final directory = await getTemporaryDirectory();
      final path = '${directory.path}/expenses_export.csv';
      final file = File(path);
      await file.writeAsString(csv.toString());
      await Share.shareXFiles(
        [XFile(path)],
        text: 'My Expenses Export',
        sharePositionOrigin: sharePositionOrigin,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to export: $e')));
      }
    }
  }

  List<Expense> _filterExpensesByPeriod(List<Expense> allExpenses) {
    final now = DateTime.now();
    return allExpenses.where((e) {
      if (_selectedPeriod == 'Week') {
        return now.difference(e.date).inDays <= 7;
      } else if (_selectedPeriod == 'Month') {
        return now.difference(e.date).inDays <= 30;
      } else if (_selectedPeriod == 'Year') {
        return now.difference(e.date).inDays <= 365;
      }
      return true; // All Time
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final expensesVm = Provider.of<ExpensesListViewModel>(context);
    final homeVm = Provider.of<HomeViewModel>(context);
    final settingsVm = Provider.of<SettingsViewModel>(context);

    if (homeVm.isLoading || expensesVm.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Analytics')),
        body: const LoadingShimmerWidget(type: ShimmerType.analytics),
      );
    }

    if (homeVm.hasError || expensesVm.hasError) {
      return Scaffold(
        appBar: AppBar(title: const Text('Analytics')),
        body: ErrorStateWidget(
          message:
              homeVm.errorMessage ??
              expensesVm.errorMessage ??
              'Failed to load data',
          onRetry: () {
            homeVm.loadData();
            expensesVm.loadExpenses();
          },
        ),
      );
    }

    final filteredExpenses = _filterExpensesByPeriod(expensesVm.expenses);
    double totalExpenses = filteredExpenses.fold(
      0.0,
      (sum, e) => sum + e.amount,
    );

    final Map<String, double> categoryTotals = {};
    for (var e in filteredExpenses) {
      categoryTotals[e.category] = (categoryTotals[e.category] ?? 0) + e.amount;
    }

    final double dailyLimit = homeVm.profile?.dailyLimit ?? 0;
    double efficiency = 0;
    if (dailyLimit > 0) {
      efficiency = ((dailyLimit - totalExpenses) / dailyLimit) * 100;
      if (efficiency < 0) efficiency = 0;
    }

    // Prepare chart data
    final pieData = <_PieData>[];
    if (homeVm.leftovers > 0) {
      pieData.add(
        _PieData('Leftovers', homeVm.leftovers, AppColors.primaryAccent),
      );
    }
    if (totalExpenses > 0) {
      pieData.add(_PieData('Expenses', totalExpenses, AppColors.error));
    }
    if (pieData.isEmpty) {
      pieData.add(_PieData('No Data', 1, AppColors.border));
    }

    final barData = categoryTotals.entries
        .map((e) => _BarData(e.key, e.value))
        .toList();
    final symbol = CurrencyHelper.getSymbol(settingsVm.currency);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: const Text('Analytics'),
            floating: true,
            pinned: true,
            flexibleSpace: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(color: Colors.transparent),
              ),
            ),
            actions: [
              Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.file_download),
                  tooltip: 'Export Data',
                  onPressed: () {
                    final box = context.findRenderObject() as RenderBox?;
                    final rect = box != null
                        ? (box.localToGlobal(Offset.zero) & box.size)
                        : null;
                    _exportData(filteredExpenses, rect);
                  },
                ),
              ),
            ],
          ),
          if (filteredExpenses.isEmpty && homeVm.leftovers == 0)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyStateWidget(
                title: 'No Analytics Data',
                subtitle: 'Add some expenses or leftovers to see charts.',
                icon: Icons.analytics_outlined,
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(24.0),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Period selector - segmented chip style
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value,
                        child: Transform.translate(
                          offset: Offset(0, 16 * (1 - value)),
                          child: child,
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.border.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        children: _periods.map((period) {
                          final isSelected = _selectedPeriod == period;
                          return Expanded(
                            child: GestureDetector(
                              onTap: () =>
                                  setState(() => _selectedPeriod = period),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeOutCubic,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  gradient: isSelected
                                      ? AppColors.primaryGradient
                                      : null,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: AppColors.primaryAccent
                                                .withValues(alpha: 0.3),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Center(
                                  child: Text(
                                    period,
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : Theme.of(context).colorScheme.onSurfaceVariant,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Stat summary cards
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value,
                        child: Transform.translate(
                          offset: Offset(0, 20 * (1 - value)),
                          child: child,
                        ),
                      );
                    },
                    child: Row(
                      children: [
                        Expanded(
                          child: _AnimatedStatCard(
                            title: 'Total Expenses',
                            value: totalExpenses,
                            prefix: symbol,
                            icon: Icons.trending_down_rounded,
                            color: AppColors.error,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _AnimatedStatCard(
                            title: 'Leftovers',
                            value: homeVm.leftovers,
                            prefix: symbol,
                            icon: Icons.savings_rounded,
                            color: AppColors.primaryAccent,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _AnimatedStatCard(
                            title: 'Efficiency',
                            value: efficiency,
                            suffix: '%',
                            icon: Icons.speed_rounded,
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Pie chart card
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 900),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value,
                        child: Transform.translate(
                          offset: Offset(0, 24 * (1 - value)),
                          child: child,
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.border.withValues(alpha: 0.5),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryAccent.withValues(
                              alpha: 0.06,
                            ),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Leftovers vs Expenses',
                            style: Theme.of(context).textTheme.displayMedium,
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            height: 200,
                            child: charts.PieChart<String>(
                              [
                                charts.Series<_PieData, String>(
                                  id: 'Overview',
                                  domainFn: (_PieData data, _) => data.label,
                                  measureFn: (_PieData data, _) => data.value,
                                  colorFn: (_PieData data, _) =>
                                      charts.ColorUtil.fromDartColor(
                                        data.color,
                                      ),
                                  data: pieData,
                                  labelAccessorFn: (_PieData row, _) =>
                                      row.label,
                                ),
                              ],
                              animate: true,
                              defaultRenderer: charts.ArcRendererConfig<String>(
                                arcWidth: 60,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildLegendItem(
                                context,
                                'Leftovers',
                                AppColors.primaryAccent,
                                homeVm.leftovers,
                              ),
                              _buildLegendItem(
                                context,
                                'Expenses',
                                AppColors.error,
                                totalExpenses,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (settingsVm.advancedAnalytics) ...[
                    const SizedBox(height: 24),
                    // Advanced analytics section
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 1100),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: value,
                          child: Transform.translate(
                            offset: Offset(0, 24 * (1 - value)),
                            child: child,
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.border.withValues(alpha: 0.5),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.secondaryAccent.withValues(
                                alpha: 0.06,
                              ),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.secondaryAccent.withValues(
                                      alpha: 0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.insights_rounded,
                                    color: AppColors.secondaryAccent,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Advanced Analytics',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.displayMedium,
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.cardBackground,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Efficiency Summary',
                                    style: Theme.of(context).textTheme.bodyLarge
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'You have saved ${efficiency.toStringAsFixed(1)}% of your daily limit in this period.',
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Expenses by Category',
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 200,
                              child: charts.BarChart(
                                [
                                  charts.Series<_BarData, String>(
                                    id: 'Categories',
                                    domainFn: (_BarData data, _) =>
                                        data.category,
                                    measureFn: (_BarData data, _) => data.value,
                                    colorFn: (data, index) =>
                                        charts.ColorUtil.fromDartColor(
                                          AppColors.secondaryAccent,
                                        ),
                                    data: barData,
                                  ),
                                ],
                                animate: true,
                                domainAxis: charts.OrdinalAxisSpec(
                                  renderSpec: charts.SmallTickRendererSpec(
                                    labelRotation: 45,
                                    labelStyle: charts.TextStyleSpec(
                                      color: charts.ColorUtil.fromDartColor(
                                        Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Colors.white70
                                            : AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                ),
                                primaryMeasureAxis: charts.NumericAxisSpec(
                                  renderSpec: charts.GridlineRendererSpec(
                                    labelStyle: charts.TextStyleSpec(
                                      color: charts.ColorUtil.fromDartColor(
                                        Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Colors.white70
                                            : AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 120),
                ]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(
    BuildContext context,
    String title,
    Color color,
    double value,
  ) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Builder(
          builder: (context) {
            final settingsVm = Provider.of<SettingsViewModel>(context);
            final symbol = CurrencyHelper.getSymbol(settingsVm.currency);
            return Text(
              '$symbol${value.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            );
          },
        ),
      ],
    );
  }
}

class _AnimatedStatCard extends StatelessWidget {
  final String title;
  final double value;
  final String? prefix;
  final String? suffix;
  final IconData icon;
  final Color color;

  const _AnimatedStatCard({
    required this.title,
    required this.value,
    this.prefix,
    this.suffix,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 10),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: value),
            duration: const Duration(milliseconds: 1200),
            curve: Curves.easeOutCubic,
            builder: (context, animatedValue, child) {
              return Text(
                '${prefix ?? ''}${animatedValue.toStringAsFixed(suffix != null ? 1 : 2)}${suffix ?? ''}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: color,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              );
            },
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _PieData {
  final String label;
  final double value;
  final Color color;
  _PieData(this.label, this.value, this.color);
}

class _BarData {
  final String category;
  final double value;
  _BarData(this.category, this.value);
}
