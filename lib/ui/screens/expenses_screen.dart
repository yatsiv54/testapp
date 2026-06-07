import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/currency_helper.dart';
import '../../viewmodels/expenses_list_viewmodel.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'expense_detail_screen.dart';
import '../widgets/filter_bottom_sheet.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/loading_shimmer_widget.dart';

import 'dart:ui';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ExpensesListViewModel>(context, listen: false).loadExpenses();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<ExpensesListViewModel>(
        builder: (context, vm, child) {
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                title: const Text('Expenses'),
                floating: true,
                pinned: true,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.filter_list),
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                        ),
                        builder: (_) => const FilterBottomSheet(),
                      );
                    },
                  ),
                ],
                flexibleSpace: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(color: Colors.transparent),
                  ),
                ),
              ),
              if (vm.isLoading)
                const SliverFillRemaining(child: LoadingShimmerWidget())
              else if (vm.filteredExpenses.isEmpty)
                const SliverFillRemaining(
                  child: EmptyStateWidget(
                    title: 'No Expenses Yet',
                    subtitle: 'Add your first expense or clear filters to see more.',
                    icon: Icons.receipt_long,
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final expense = vm.filteredExpenses[index];
                        return TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: Duration(milliseconds: 300 + (index * 50).clamp(0, 500)),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, child) {
                            return Transform.translate(
                              offset: Offset(0, 20 * (1 - value)),
                              child: Opacity(
                                opacity: value,
                                child: child,
                              ),
                            );
                          },
                          child: Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            child: ListTile(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => ExpenseDetailScreen(expense: expense),
                                  ),
                                );
                              },
                              contentPadding: const EdgeInsets.all(12),
                              leading: Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).scaffoldBackgroundColor,
                                  borderRadius: BorderRadius.circular(12),
                                  image: expense.photoPath.isNotEmpty
                                      ? DecorationImage(image: FileImage(File(expense.photoPath)), fit: BoxFit.cover)
                                      : null,
                                ),
                                child: expense.photoPath.isEmpty
                                    ? const Icon(Icons.receipt_long, color: AppColors.primaryAccent)
                                    : null,
                              ),
                              title: Text(expense.category, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                              subtitle: Text(DateFormat('MMM dd, yyyy').format(expense.date), style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                              trailing: Text('-${CurrencyHelper.getSymbol(expense.currency)}${expense.amount.toStringAsFixed(2)}', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.error, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        );
                      },
                      childCount: vm.filteredExpenses.length,
                    ),
                  ),
                ),
              const SliverPadding(padding: EdgeInsets.only(bottom: 120)),
            ],
          );
        },
      ),
    );
  }
}
