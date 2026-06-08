import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/currency_helper.dart';
import '../../viewmodels/expenses_list_viewmodel.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'expense_detail_screen.dart';
import '../widgets/filter_bottom_sheet.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/loading_shimmer_widget.dart';
import '../widgets/error_state_widget.dart';
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

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'Food':
        return Icons.restaurant;
      case 'Transport':
        return Icons.directions_car;
      case 'Entertainment':
        return Icons.movie;
      case 'Bills':
        return Icons.receipt;
      default:
        return Icons.category;
    }
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
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(24),
                          ),
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
                const SliverFillRemaining(child: LoadingShimmerWidget(type: ShimmerType.list))
              else if (vm.hasError)
                SliverFillRemaining(
                  child: ErrorStateWidget(
                    message: vm.errorMessage ?? 'Failed to load expenses',
                    onRetry: () => vm.loadExpenses(),
                  ),
                )
              else if (vm.filteredExpenses.isEmpty)
                const SliverFillRemaining(
                  child: EmptyStateWidget(
                    title: 'No Expenses Yet',
                    subtitle:
                        'Add your first expense or clear filters to see more.',
                    icon: Icons.receipt_long,
                  ),
                )
              else
                ..._buildGroupedExpensesList(context, vm),
              const SliverPadding(padding: EdgeInsets.only(bottom: 120)),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _buildGroupedExpensesList(
    BuildContext context,
    ExpensesListViewModel vm,
  ) {
    final expenses = vm.filteredExpenses;
    final grouped = <String, List<int>>{};

    for (var i = 0; i < expenses.length; i++) {
      final key = DateFormat('yyyy-MM-dd').format(expenses[i].date);
      grouped.putIfAbsent(key, () => []).add(i);
    }

    final sortedKeys = grouped.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    final slivers = <Widget>[];
    var animIndex = 0;

    for (final dateKey in sortedKeys) {
      final date = DateTime.parse(dateKey);
      final indices = grouped[dateKey]!;

      slivers.add(
        SliverPadding(
          padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 4),
          sliver: SliverToBoxAdapter(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: Duration(
                milliseconds: 300 + (animIndex * 30).clamp(0, 300),
              ),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(-10 * (1 - value), 0),
                    child: child,
                  ),
                );
              },
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryAccent.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _formatDateHeader(date),
                      style: AppTypography.caption.copyWith(
                        color: AppColors.primaryAccent,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      height: 1,
                      color: AppColors.border.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      slivers.add(
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, listIndex) {
                final expenseIndex = indices[listIndex];
                final expense = expenses[expenseIndex];
                final currentAnimIndex = animIndex + listIndex;

                return TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: Duration(
                    milliseconds: 300 + (currentAnimIndex * 50).clamp(0, 500),
                  ),
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
                  child: _ExpenseCard(
                    expense: expense,
                    categoryIcon: _categoryIcon(expense.category),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              ExpenseDetailScreen(expense: expense),
                        ),
                      );
                    },
                  ),
                );
              },
              childCount: indices.length,
            ),
          ),
        ),
      );

      animIndex += indices.length;
    }

    return slivers;
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = today.difference(target).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return DateFormat('EEEE').format(date);
    return DateFormat('MMM dd, yyyy').format(date);
  }
}

class _ExpenseCard extends StatefulWidget {
  final dynamic expense;
  final IconData categoryIcon;
  final VoidCallback onTap;

  const _ExpenseCard({
    required this.expense,
    required this.categoryIcon,
    required this.onTap,
  });

  @override
  State<_ExpenseCard> createState() => _ExpenseCardState();
}

class _ExpenseCardState extends State<_ExpenseCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedScale(
          scale: _isPressed ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeInOut,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.secondaryBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isPressed
                    ? AppColors.primaryAccent.withValues(alpha: 0.3)
                    : AppColors.border.withValues(alpha: 0.5),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryAccent.withValues(alpha: 0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: AppColors.secondaryAccent.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                  spreadRadius: 1,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  AnimatedOpacity(
                    opacity: _isPressed ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primaryAccent.withValues(alpha: 0.03),
                            AppColors.secondaryAccent.withValues(alpha: 0.02),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        _buildThumbnail(),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    widget.categoryIcon,
                                    size: 16,
                                    color: AppColors.primaryAccent,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      widget.expense.category,
                                      style: AppTypography.body.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                DateFormat('MMM dd, yyyy').format(
                                  widget.expense.date,
                                ),
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              if (widget.expense.comment.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  widget.expense.comment,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.textSecondary
                                        .withValues(alpha: 0.7),
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '-${CurrencyHelper.getSymbol(widget.expense.currency)}${widget.expense.amount.toStringAsFixed(2)}',
                            style: AppTypography.body.copyWith(
                              color: AppColors.error,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.border.withValues(alpha: 0.6),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryAccent.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: widget.expense.photoPath.isNotEmpty
            ? Image.file(
                File(widget.expense.photoPath),
                fit: BoxFit.cover,
                width: 56,
                height: 56,
              )
            : Center(
                child: Icon(
                  widget.categoryIcon,
                  size: 26,
                  color: AppColors.primaryAccent.withValues(alpha: 0.6),
                ),
              ),
      ),
    );
  }
}
