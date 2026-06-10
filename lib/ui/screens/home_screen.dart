import 'package:community_charts_flutter/community_charts_flutter.dart'
    as charts;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'dart:ui';
import 'dart:math';
import 'profile_screen.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/currency_helper.dart';
import '../../viewmodels/home_viewmodel.dart';
import '../../viewmodels/expenses_list_viewmodel.dart';
import '../../viewmodels/settings_viewmodel.dart';
import 'create_expense_screen.dart';
import 'expense_detail_screen.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/loading_shimmer_widget.dart';
import '../widgets/error_state_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late final AnimationController _sparkleController;

  @override
  void initState() {
    super.initState();
    _sparkleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<HomeViewModel>(context, listen: false).loadData();
    });
  }

  @override
  void dispose() {
    _sparkleController.dispose();
    super.dispose();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return AppColors.success;
      case 'transport':
        return AppColors.primaryAccent;
      case 'entertainment':
        return AppColors.secondaryAccent;
      case 'bills':
        return AppColors.warning;
      case 'other':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Icons.restaurant_rounded;
      case 'transport':
        return Icons.directions_car_rounded;
      case 'entertainment':
        return Icons.movie_rounded;
      case 'bills':
        return Icons.receipt_long_rounded;
      case 'other':
        return Icons.more_horiz_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final homeVm = Provider.of<HomeViewModel>(context);
    final expensesVm = Provider.of<ExpensesListViewModel>(context);

    if (homeVm.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Dashboard')),
        body: const LoadingShimmerWidget(type: ShimmerType.home),
      );
    }

    if (homeVm.hasError) {
      return Scaffold(
        appBar: AppBar(title: const Text('Dashboard')),
        body: ErrorStateWidget(
          message: homeVm.errorMessage ?? 'Failed to load data',
          onRetry: () => homeVm.loadData(),
        ),
      );
    }

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
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          const ProfileScreen(isInitialSetup: false),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: Hero(
                    tag: 'profile_avatar',
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primaryAccent.withValues(alpha: 0.5),
                          width: 2,
                        ),
                      ),
                      child: CircleAvatar(
                        key: ValueKey(homeVm.profile?.photoPath),
                        radius: 20,
                        backgroundColor: Theme.of(
                          context,
                        ).scaffoldBackgroundColor,
                        backgroundImage:
                            (homeVm.profile?.photoPath != null &&
                                homeVm.profile!.photoPath.isNotEmpty &&
                                File(homeVm.profile!.photoPath).existsSync() &&
                                File(homeVm.profile!.photoPath).lengthSync() >
                                    0)
                            ? FileImage(File(homeVm.profile!.photoPath))
                            : null,
                        child:
                            (homeVm.profile?.photoPath == null ||
                                homeVm.profile!.photoPath.isEmpty ||
                                !File(homeVm.profile!.photoPath).existsSync() ||
                                File(homeVm.profile!.photoPath).lengthSync() ==
                                    0)
                            ? const Icon(
                                Icons.person,
                                color: AppColors.primaryAccent,
                              )
                            : null,
                      ),
                    ),
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
                  // Greeting text
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value,
                        child: Transform.translate(
                          offset: Offset(0, 12 * (1 - value)),
                          child: child,
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Text(
                        '${_getGreeting()}, ${homeVm.profile?.name ?? 'there'}!',
                        style: Theme.of(context).textTheme.displayMedium
                            ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                    ),
                  ),
                  // Balance card with sparkle overlay
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value,
                        child: Transform.scale(
                          scale: 0.9 + (0.1 * value),
                          child: child,
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryAccent.withValues(
                              alpha: 0.3,
                            ),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                          BoxShadow(
                            color: AppColors.secondaryAccent.withValues(
                              alpha: 0.15,
                            ),
                            blurRadius: 40,
                            offset: const Offset(0, 20),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          // Sparkle dots overlay
                          Positioned.fill(
                            child: AnimatedBuilder(
                              animation: _sparkleController,
                              builder: (context, child) {
                                return CustomPaint(
                                  painter: _SparklePainter(
                                    progress: _sparkleController.value,
                                  ),
                                );
                              },
                            ),
                          ),
                          Column(
                            children: [
                              const Text(
                                'Leftovers Box',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Consumer3<
                                HomeViewModel,
                                ExpensesListViewModel,
                                SettingsViewModel
                              >(
                                builder:
                                    (
                                      context,
                                      homeVm,
                                      expensesVm,
                                      settingsVm,
                                      child,
                                    ) {
                                      final symbol = CurrencyHelper.getSymbol(
                                        settingsVm.currency,
                                      );

                                      final today = DateTime.now();
                                      final todayExpenses = expensesVm.expenses
                                          .where(
                                            (e) =>
                                                e.date.year == today.year &&
                                                e.date.month == today.month &&
                                                e.date.day == today.day,
                                          )
                                          .fold(
                                            0.0,
                                            (sum, e) => sum + e.amount,
                                          );

                                      final currentBalance =
                                          homeVm.leftovers +
                                          (homeVm.profile?.dailyLimit ?? 0) -
                                          todayExpenses;

                                      return TweenAnimationBuilder<double>(
                                        tween: Tween(
                                          begin: 0.0,
                                          end: currentBalance,
                                        ),
                                        duration: const Duration(
                                          milliseconds: 1200,
                                        ),
                                        curve: Curves.easeOutCubic,
                                        builder: (context, animatedValue, child) {
                                          return Text(
                                            '$symbol${animatedValue.toStringAsFixed(2)}',
                                            style: Theme.of(context)
                                                .textTheme
                                                .displayLarge
                                                ?.copyWith(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 36,
                                                  shadows: [
                                                    const Shadow(
                                                      color: Colors.black26,
                                                      blurRadius: 10,
                                                      offset: Offset(0, 4),
                                                    ),
                                                  ],
                                                ),
                                          );
                                        },
                                      );
                                    },
                              ),
                              const SizedBox(height: 4),
                              Consumer<HomeViewModel>(
                                builder: (context, homeVm, child) {
                                  return Text(
                                    'Daily limit: ${homeVm.profile?.dailyLimit.toStringAsFixed(0) ?? '0'}',
                                    style: const TextStyle(
                                      color: Colors.white54,
                                      fontSize: 13,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Quick action buttons
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 900),
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
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _QuickActionButton(
                          icon: Icons.add_rounded,
                          label: 'Add Expense',
                          color: AppColors.primaryAccent,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const CreateExpenseScreen(),
                              ),
                            );
                          },
                        ),
                        _QuickActionButton(
                          icon: Icons.pie_chart_rounded,
                          label: 'Spin Wheel',
                          color: AppColors.secondaryAccent,
                          onTap: () {
                            // Navigate to wheel tab (index 2) via MainScreen
                            final mainState = context
                                .findAncestorStateOfType<State>();
                            if (mainState != null) {
                              // Find the main screen's state and switch tab
                              _switchToTab(context, 2);
                            }
                          },
                        ),
                        _QuickActionButton(
                          icon: Icons.analytics_rounded,
                          label: 'Analytics',
                          color: AppColors.success,
                          onTap: () {
                            _switchToTab(context, 3);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Recent expenses header
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 1000),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return Opacity(opacity: value, child: child);
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Recent Expenses',
                          style: Theme.of(context).textTheme.displayMedium,
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const CreateExpenseScreen(),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.primaryAccent.withValues(
                                    alpha: 0.15,
                                  ),
                                  AppColors.secondaryAccent.withValues(
                                    alpha: 0.1,
                                  ),
                                ],
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.add,
                              color: AppColors.primaryAccent,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
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
                    final expense = expensesVm
                        .expenses[expensesVm.expenses.length - 1 - index];
                    final categoryColor = _getCategoryColor(expense.category);
                    final categoryIcon = _getCategoryIcon(expense.category);

                    return TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: Duration(milliseconds: 500 + (index * 100)),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: value,
                          child: Transform.translate(
                            offset: Offset(0, 30 * (1 - value)),
                            child: child,
                          ),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.border.withValues(alpha: 0.5),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: categoryColor.withValues(alpha: 0.08),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      ExpenseDetailScreen(expense: expense),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  // Category indicator with icon
                                  Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: categoryColor.withValues(
                                        alpha: 0.12,
                                      ),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: (expense.photoPath.isNotEmpty && File(expense.photoPath).existsSync())
                                        ? ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              14,
                                            ),
                                            child: Image.file(
                                              File(expense.photoPath),
                                              fit: BoxFit.cover,
                                              width: 50,
                                              height: 50,
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                    return Container(
                                                      width: 50,
                                                      height: 50,
                                                      color: AppColors.error
                                                          .withValues(
                                                            alpha: 0.1,
                                                          ),
                                                      child: const Icon(
                                                        Icons.receipt_long,
                                                        color: AppColors.error,
                                                      ),
                                                    );
                                                  },
                                            ),
                                          )
                                        : Icon(
                                            categoryIcon,
                                            color: categoryColor,
                                            size: 24,
                                          ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Category + date
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          expense.category,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyLarge
                                              ?.copyWith(
                                                fontWeight: FontWeight.w600,
                                                color: Theme.of(context).colorScheme.onSurface,
                                              ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Container(
                                              width: 6,
                                              height: 6,
                                              decoration: BoxDecoration(
                                                color: categoryColor,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              DateFormat(
                                                'MMM dd, hh:mm a',
                                              ).format(expense.date),
                                              style: TextStyle(
                                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Amount
                                  Text(
                                    '-${CurrencyHelper.getSymbol(expense.currency)}${expense.amount.toStringAsFixed(2)}',
                                    style: Theme.of(context).textTheme.bodyLarge
                                        ?.copyWith(
                                          color: AppColors.error,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  childCount: expensesVm.expenses.length > 5
                      ? 5
                      : expensesVm.expenses.length,
                ),
              ),
            ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 120)),
        ],
      ),
    );
  }

  void _switchToTab(BuildContext context, int index) {
    // Walk up the widget tree to find MainScreen's state
    context.visitAncestorElements((element) {
      if (element.widget.runtimeType.toString() == 'MainScreen') {
        final state = (element as StatefulElement).state;
        if (state.runtimeType.toString() == 'MainScreenState') {
          (state as dynamic).switchToTab(index);
        }
        return false;
      }
      return true;
    });
  }
}

class _QuickActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  State<_QuickActionButton> createState() => _QuickActionButtonState();
}

class _QuickActionButtonState extends State<_QuickActionButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _pressController.forward(),
      onTapUp: (_) {
        _pressController.reverse();
        widget.onTap();
      },
      onTapCancel: () => _pressController.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: widget.color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: widget.color.withValues(alpha: 0.2),
                  width: 1.5,
                ),
              ),
              child: Icon(widget.icon, color: widget.color, size: 26),
            ),
            const SizedBox(height: 8),
            Text(
              widget.label,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SparklePainter extends CustomPainter {
  final double progress;

  _SparklePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(42);
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 12; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final phase = (progress + (i / 12)) % 1.0;
      final opacity = (sin(phase * pi * 2) * 0.5 + 0.5) * 0.3;
      final radius = 1.5 + random.nextDouble() * 2.0;

      paint.color = Colors.white.withValues(alpha: opacity);
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SparklePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
