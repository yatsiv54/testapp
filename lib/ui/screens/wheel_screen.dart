import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/animated_button.dart';
import '../../core/utils/currency_helper.dart';
import '../../data/services/local_storage_service.dart';
import '../../viewmodels/settings_viewmodel.dart';
import '../../viewmodels/home_viewmodel.dart';
import '../../viewmodels/expenses_list_viewmodel.dart';
import 'dart:math';

class WheelScreen extends StatefulWidget {
  const WheelScreen({super.key});

  @override
  State<WheelScreen> createState() => _WheelScreenState();
}

class _WheelScreenState extends State<WheelScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _currentAngle = 0;
  double _multiplier = 1.0;
  bool _spinning = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    _animation = Tween<double>(begin: 0, end: 0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _spin() async {
    if (_spinning) return;
    
    final settingsVm = Provider.of<SettingsViewModel>(context, listen: false);
    final storage = LocalStorageService();
    
    final lastSpinStr = await storage.getLastSpinDate();
    final now = DateTime.now();
    if (lastSpinStr != null) {
      final lastSpin = DateTime.parse(lastSpinStr);
      if (lastSpin.year == now.year && lastSpin.month == now.month && lastSpin.day == now.day) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('You can only spin the wheel once a day!')));
        return;
      }
    }

    setState(() => _spinning = true);
    
    setState(() => _spinning = true);
    
    // Pick a random multiplier segment
    final int selectedIndex = Random().nextInt(10);
    _multiplier = 1.1 + (selectedIndex * 0.1);
    
    const double sweepAngle = (2 * pi) / 10;
    final double thetaInitial = selectedIndex * sweepAngle + sweepAngle / 2;
    
    // Rotate to make the selected segment land exactly at the top (-pi/2)
    // Add 5 full spins (10 * pi) for the animation effect
    final double rTarget = (10 * pi) - (pi / 2) - thetaInitial;

    _animation = Tween<double>(
      begin: _currentAngle,
      end: _currentAngle + rTarget,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.reset();
    await _controller.forward();
    
    _currentAngle = (_currentAngle + rTarget) % (2 * pi);
    
    if (!mounted) return;

    final homeVm = Provider.of<HomeViewModel>(context, listen: false);
    final expensesVm = Provider.of<ExpensesListViewModel>(context, listen: false);
    
    final today = DateTime.now();
    final todayExpenses = expensesVm.expenses.where((e) => 
        e.date.year == today.year && 
        e.date.month == today.month && 
        e.date.day == today.day
    ).fold(0.0, (sum, e) => sum + e.amount);

    final currentBalance = homeVm.leftovers + (homeVm.profile?.dailyLimit ?? 0) - todayExpenses;
    
    final bonus = currentBalance > 0 ? currentBalance * (_multiplier - 1.0) : 0.0;
    if (bonus > 0) {
      await homeVm.updateLeftovers(bonus);
    }
    await storage.saveLastSpinDate(now.toIso8601String());

    setState(() => _spinning = false);

    if (!mounted) return;
    
    final symbol = CurrencyHelper.getSymbol(settingsVm.currency);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Congratulations!'),
        content: Text('You multiplied your balance by ${_multiplier.toStringAsFixed(2)}x!\n\nBonus added: $symbol${bonus.toStringAsFixed(2)}'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Awesome')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Wheel'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Center(
              child: Stack(
                alignment: Alignment.topCenter,
                clipBehavior: Clip.none,
                children: [
                  AnimatedBuilder(
                    animation: _animation,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _animation.value,
                        child: Container(
                          width: 300,
                          height: 300,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.secondaryAccent.withValues(alpha: 0.3),
                                blurRadius: 30,
                                spreadRadius: 5,
                              )
                            ],
                            border: Border.all(color: Colors.white, width: 8),
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              CustomPaint(
                                size: const Size(double.infinity, double.infinity),
                                painter: _WheelPainter(),
                              ),
                              // Center peg
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(color: Colors.black26, blurRadius: 4, offset: const Offset(0, 2))
                                  ],
                                  border: Border.all(color: AppColors.primaryAccent, width: 4),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  // Pointer at the top (now outside rotation)
                  Positioned(
                    top: -15,
                    child: CustomPaint(
                      size: const Size(24, 28),
                      painter: _PointerPainter(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 64),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: AnimatedButton(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 32),
                borderRadius: BorderRadius.circular(30),
                onPressed: _spin,
                child: const Text('SPIN NOW!', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PointerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.error
      ..style = PaintingStyle.fill;
    
    final path = Path()
      ..moveTo(size.width / 2, size.height)
      ..lineTo(0, 0)
      ..lineTo(size.width, 0)
      ..close();
      
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _WheelPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double radius = size.width / 2;
    final Offset center = Offset(radius, radius);
    final Rect rect = Rect.fromCircle(center: center, radius: radius);
    
    final List<String> multipliers = ['1.1x', '1.2x', '1.3x', '1.4x', '1.5x', '1.6x', '1.7x', '1.8x', '1.9x', '2.0x'];
    const double sweepAngle = (2 * 3.141592653589793) / 10;
    
    for (int i = 0; i < 10; i++) {
      final paint = Paint()
        ..color = i.isEven ? const Color(0xFFF1F5FB) : const Color(0xFFE3E8F0)
        ..style = PaintingStyle.fill;
        
      canvas.drawArc(rect, i * sweepAngle, sweepAngle, true, paint);
      
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(i * sweepAngle + sweepAngle / 2);
      
      final textPainter = TextPainter(
        text: TextSpan(
          text: multipliers[i],
          style: const TextStyle(color: AppColors.primaryAccent, fontSize: 18, fontWeight: FontWeight.w900),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(radius - 60, -textPainter.height / 2));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
