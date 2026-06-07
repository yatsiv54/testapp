import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:community_charts_flutter/community_charts_flutter.dart' as charts;
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
class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  String _selectedPeriod = 'All Time';
  final List<String> _periods = ['Week', 'Month', 'Year', 'All Time'];

  Future<void> _exportData(List<Expense> expenses) async {
    try {
      if (expenses.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No data to export')));
        return;
      }
      final StringBuffer csv = StringBuffer();
      csv.writeln('ID,Amount,Currency,Category,Date,Comment');
      for (var e in expenses) {
        csv.writeln('${e.id},${e.amount},${e.currency},${e.category},${e.date.toIso8601String()},"${e.comment.replaceAll('"', '""')}"');
      }
      final directory = await getTemporaryDirectory();
      final path = '${directory.path}/expenses_export.csv';
      final file = File(path);
      await file.writeAsString(csv.toString());
      await Share.shareXFiles([XFile(path)], text: 'My Expenses Export');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to export: $e')));
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

    final filteredExpenses = _filterExpensesByPeriod(expensesVm.expenses);
    double totalExpenses = filteredExpenses.fold(0.0, (sum, e) => sum + e.amount);

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
      pieData.add(_PieData('Leftovers', homeVm.leftovers, AppColors.primaryAccent));
    }
    if (totalExpenses > 0) {
      pieData.add(_PieData('Expenses', totalExpenses, AppColors.error));
    }
    if (pieData.isEmpty) {
      pieData.add(_PieData('No Data', 1, AppColors.border));
    }

    final barData = categoryTotals.entries.map((e) => _BarData(e.key, e.value)).toList();

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
              IconButton(
                icon: const Icon(Icons.file_download),
                tooltip: 'Export Data',
                onPressed: () => _exportData(filteredExpenses),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Period', style: Theme.of(context).textTheme.bodyLarge),
                      DropdownButton<String>(
                        value: _selectedPeriod,
                        items: _periods.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedPeriod = val);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text('Leftovers vs Expenses', style: Theme.of(context).textTheme.displayMedium),
                  const SizedBox(height: 32),
                  SizedBox(
                    height: 200,
                    child: charts.PieChart<String>(
                      [
                        charts.Series<_PieData, String>(
                          id: 'Overview',
                          domainFn: (_PieData data, _) => data.label,
                          measureFn: (_PieData data, _) => data.value,
                          colorFn: (_PieData data, _) => charts.ColorUtil.fromDartColor(data.color),
                          data: pieData,
                          labelAccessorFn: (_PieData row, _) => row.label,
                        )
                      ],
                      animate: true,
                      defaultRenderer: charts.ArcRendererConfig<String>(
                        arcWidth: 60,
                        arcRendererDecorators: [
                          charts.ArcLabelDecorator<String>(
                            insideLabelStyleSpec: charts.TextStyleSpec(
                              color: charts.ColorUtil.fromDartColor(Colors.white),
                            ),
                            outsideLabelStyleSpec: charts.TextStyleSpec(
                              color: charts.ColorUtil.fromDartColor(Theme.of(context).colorScheme.onSurface),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildLegendItem(context, 'Leftovers', AppColors.primaryAccent, homeVm.leftovers),
                      _buildLegendItem(context, 'Expenses', AppColors.error, totalExpenses),
                    ],
                  ),
                  if (settingsVm.advancedAnalytics) ...[
                    const SizedBox(height: 48),
                    const Divider(),
                    const SizedBox(height: 24),
                    Text('Advanced Analytics', style: Theme.of(context).textTheme.displayMedium),
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text('Efficiency Summary', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text(
                            'You have saved ${efficiency.toStringAsFixed(1)}% of your daily limit in this period.',
                            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                          ),
                          const SizedBox(height: 24),
                          Text('Expenses by Category', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 24),
                          SizedBox(
                            height: 200,
                            child: charts.BarChart(
                              [
                                charts.Series<_BarData, String>(
                                  id: 'Categories',
                                  domainFn: (_BarData data, _) => data.category,
                                  measureFn: (_BarData data, _) => data.value,
                                  colorFn: (data, index) => charts.ColorUtil.fromDartColor(AppColors.secondaryAccent),
                                  data: barData,
                                )
                              ],
                              animate: true,
                              domainAxis: charts.OrdinalAxisSpec(
                                renderSpec: charts.SmallTickRendererSpec(
                                  labelRotation: 45,
                                  labelStyle: charts.TextStyleSpec(
                                    color: charts.ColorUtil.fromDartColor(Theme.of(context).colorScheme.onSurfaceVariant),
                                  ),
                                ),
                              ),
                              primaryMeasureAxis: charts.NumericAxisSpec(
                                renderSpec: charts.GridlineRendererSpec(
                                  labelStyle: charts.TextStyleSpec(
                                    color: charts.ColorUtil.fromDartColor(Theme.of(context).colorScheme.onSurfaceVariant),
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
                  const SizedBox(height: 120), // Increased padding to avoid navbar overlap
                ]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(BuildContext context, String title, Color color, double value) {
    return Column(
      children: [
        Row(
          children: [
            Container(width: 16, height: 16, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Text(title, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 4),
        Builder(builder: (context) {
          final settingsVm = Provider.of<SettingsViewModel>(context);
          final symbol = CurrencyHelper.getSymbol(settingsVm.currency);
          return Text('$symbol${value.toStringAsFixed(2)}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurfaceVariant));
        }),
      ],
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
