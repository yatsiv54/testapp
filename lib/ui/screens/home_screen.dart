import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'dart:ui';
import 'profile_screen.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/currency_helper.dart';
import '../../viewmodels/home_viewmodel.dart';
import '../../viewmodels/expenses_list_viewmodel.dart';
import '../../viewmodels/settings_viewmodel.dart';
import 'create_expense_screen.dart';
import 'expense_detail_screen.dart';
import '../widgets/empty_state_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<HomeViewModel>(context, listen: false).loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final homeVm = Provider.of<HomeViewModel>(context);
    final expensesVm = Provider.of<ExpensesListViewModel>(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: const Text('Dashboard'),
            floating: true,
            pinned: true,
            flexibleSpace: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(color: Colors.transparent),
              ),
            ),
            actions: [
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfileScreen(isInitialSetup: false)));
                },
                child: Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: CircleAvatar(
                    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                    backgroundImage: (homeVm.profile?.photoPath != null && homeVm.profile!.photoPath.isNotEmpty)
                        ? FileImage(File(homeVm.profile!.photoPath))
                        : null,
                    child: (homeVm.profile?.photoPath == null || homeVm.profile!.photoPath.isEmpty)
                        ? const Icon(Icons.person, color: AppColors.primaryAccent)
                        : null,
                  ),
                ),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primaryAccent, AppColors.secondaryAccent],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryAccent.withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        )
                      ],
                    ),
                    child: Column(
                      children: [
                        const Text('Leftovers Box', style: TextStyle(color: Colors.white70, fontSize: 16)),
                        const SizedBox(height: 8),
                        Consumer3<HomeViewModel, ExpensesListViewModel, SettingsViewModel>(
                          builder: (context, homeVm, expensesVm, settingsVm, child) {
                            final symbol = CurrencyHelper.getSymbol(settingsVm.currency);
                            
                            final today = DateTime.now();
                            final todayExpenses = expensesVm.expenses.where((e) => 
                                e.date.year == today.year && 
                                e.date.month == today.month && 
                                e.date.day == today.day
                            ).fold(0.0, (sum, e) => sum + e.amount);

                            final currentBalance = homeVm.leftovers + (homeVm.profile?.dailyLimit ?? 0) - todayExpenses;

                            return Text(
                              '$symbol${currentBalance.toStringAsFixed(2)}',
                              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                shadows: [const Shadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text('Recent Expenses', style: Theme.of(context).textTheme.displayMedium),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
          if (expensesVm.expenses.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyStateWidget(
                title: 'No Recent Expenses',
                subtitle: 'Tap the + button to add one.',
                icon: Icons.receipt_long,
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final expense = expensesVm.expenses[expensesVm.expenses.length - 1 - index];
                    return Card(
                      color: Theme.of(context).cardColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: AppColors.border, width: 1),
                      ),
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => ExpenseDetailScreen(expense: expense)),
                          );
                        },
                        contentPadding: const EdgeInsets.all(12),
                        leading: Container(
                          width: 50,
                          height: 50,
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
                        subtitle: Text(DateFormat('MMM dd').format(expense.date), style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                        trailing: Text('-${CurrencyHelper.getSymbol(expense.currency)}${expense.amount.toStringAsFixed(2)}', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.error, fontWeight: FontWeight.bold)),
                      ),
                    );
                  },
                  childCount: expensesVm.expenses.length > 5 ? 5 : expensesVm.expenses.length,
                ),
              ),
            ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 90.0),
        child: FloatingActionButton(
          backgroundColor: AppColors.primaryAccent,
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CreateExpenseScreen()),
            );
          },
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }
}
