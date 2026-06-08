import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/utils/animated_button.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import 'profile_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  late final AnimationController _floatController;
  late final AnimationController _sparkleController;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();

    _sparkleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _floatController.dispose();
    _sparkleController.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentIndex == 0) {
      _pageController.animateToPage(
        1,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    } else {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const ProfileScreen(),
          transitionDuration: const Duration(milliseconds: 500),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentIndex = index);
                },
                children: [
                  _OnboardingPage(
                    illustration: _WalletIllustration(
                      floatController: _floatController,
                    ),
                    title: 'Welcome to Salary\nLeftovers Collector',
                    subtitle:
                        'Efficiently track daily expenses and accumulate leftovers from your daily salary limit.',
                  ),
                  _OnboardingPage(
                    illustration: _CameraIllustration(
                      floatController: _floatController,
                      sparkleController: _sparkleController,
                    ),
                    title: 'Track Expenses\nwith Photos',
                    subtitle:
                        'Take a photo of your receipt or item, save it, and view it later. Spin the wheel daily for a chance to multiply leftovers!',
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  _PageIndicator(
                    currentIndex: _currentIndex,
                    count: 2,
                  ),
                  const SizedBox(height: 32),
                  AnimatedButton(
                    onPressed: _next,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Text(
                        _currentIndex == 0 ? 'Next' : 'Get Started',
                        key: ValueKey(_currentIndex),
                        style: AppTypography.body.copyWith(
                          color: AppColors.secondaryBackground,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  final Widget illustration;
  final String title;
  final String subtitle;

  const _OnboardingPage({
    required this.illustration,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 2),
          SizedBox(
            width: 260,
            height: 260,
            child: illustration,
          ),
          const SizedBox(height: 48),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOut,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: child,
                ),
              );
            },
            child: Text(
              title,
              style: AppTypography.headline1.copyWith(
                color: AppColors.textPrimary,
                height: 1.3,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOut,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 16 * (1 - value)),
                  child: child,
                ),
              );
            },
            child: Text(
              subtitle,
              style: AppTypography.body.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const Spacer(flex: 3),
        ],
      ),
    );
  }
}

class _PageIndicator extends StatelessWidget {
  final int currentIndex;
  final int count;

  const _PageIndicator({
    required this.currentIndex,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final isActive = index == currentIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 32 : 10,
          height: 10,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            gradient: isActive ? AppColors.primaryGradient : null,
            color: isActive ? null : AppColors.border,
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: AppColors.primaryAccent.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
        );
      }),
    );
  }
}

class _WalletIllustration extends StatelessWidget {
  final AnimationController floatController;

  const _WalletIllustration({required this.floatController});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: floatController,
      builder: (context, _) {
        final t = floatController.value;
        return Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primaryAccent.withValues(alpha: 0.12),
                    AppColors.secondaryAccent.withValues(alpha: 0.08),
                  ],
                ),
              ),
            ),
            Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primaryAccent.withValues(alpha: 0.18),
                    AppColors.secondaryAccent.withValues(alpha: 0.12),
                  ],
                ),
              ),
            ),
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.primaryGradient,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryAccent.withValues(alpha: 0.4),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.account_balance_wallet_rounded,
                size: 48,
                color: AppColors.secondaryBackground,
              ),
            ),
            ..._buildFloatingCoins(t),
            Positioned(
              right: 10,
              bottom: 20,
              child: Transform.translate(
                offset: Offset(0, sin(t * 2 * pi + 1.5) * 6),
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.success.withValues(alpha: 0.15),
                    border: Border.all(
                      color: AppColors.success.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    Icons.savings_rounded,
                    size: 26,
                    color: AppColors.success.withValues(alpha: 0.9),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  List<Widget> _buildFloatingCoins(double t) {
    final coins = <_CoinData>[
      _CoinData(
        startX: -70,
        startY: 50,
        size: 28,
        phaseOffset: 0,
      ),
      _CoinData(
        startX: 60,
        startY: 60,
        size: 22,
        phaseOffset: 0.33,
      ),
      _CoinData(
        startX: -40,
        startY: 80,
        size: 18,
        phaseOffset: 0.66,
      ),
      _CoinData(
        startX: 30,
        startY: 90,
        size: 24,
        phaseOffset: 0.5,
      ),
    ];

    return coins.map((coin) {
      final phase = ((t + coin.phaseOffset) % 1.0);
      final yOffset = -phase * 120;
      final opacity = phase < 0.2
          ? phase / 0.2
          : phase > 0.8
              ? (1.0 - phase) / 0.2
              : 1.0;

      return Positioned(
        left: 130 + coin.startX,
        top: coin.startY + yOffset,
        child: Opacity(
          opacity: opacity.clamp(0.0, 0.8),
          child: Container(
            width: coin.size,
            height: coin.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.warning,
                  AppColors.warning.withValues(alpha: 0.7),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.warning.withValues(alpha: 0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                '\$',
                style: TextStyle(
                  color: AppColors.secondaryBackground,
                  fontSize: coin.size * 0.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      );
    }).toList();
  }
}

class _CoinData {
  final double startX;
  final double startY;
  final double size;
  final double phaseOffset;

  const _CoinData({
    required this.startX,
    required this.startY,
    required this.size,
    required this.phaseOffset,
  });
}

class _CameraIllustration extends StatelessWidget {
  final AnimationController floatController;
  final AnimationController sparkleController;

  const _CameraIllustration({
    required this.floatController,
    required this.sparkleController,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([floatController, sparkleController]),
      builder: (context, _) {
        final t = floatController.value;
        final s = sparkleController.value;
        return Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.secondaryAccent.withValues(alpha: 0.12),
                    AppColors.primaryAccent.withValues(alpha: 0.08),
                  ],
                ),
              ),
            ),
            Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.secondaryAccent.withValues(alpha: 0.18),
                    AppColors.primaryAccent.withValues(alpha: 0.12),
                  ],
                ),
              ),
            ),
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.secondaryAccent,
                    AppColors.primaryAccent,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color:
                        AppColors.secondaryAccent.withValues(alpha: 0.4),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(
                    Icons.camera_alt_rounded,
                    size: 48,
                    color: AppColors.secondaryBackground,
                  ),
                  Positioned(
                    top: 18,
                    right: 22,
                    child: Opacity(
                      opacity: (sin(s * 2 * pi) * 0.5 + 0.5),
                      child: const Icon(
                        Icons.flash_on_rounded,
                        size: 18,
                        color: AppColors.warning,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ..._buildFloatingReceipts(t),
            Positioned(
              left: 20,
              bottom: 25,
              child: Transform.translate(
                offset: Offset(0, sin(t * 2 * pi + 2.0) * 5),
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.success.withValues(alpha: 0.15),
                    border: Border.all(
                      color: AppColors.success.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    Icons.trending_up_rounded,
                    size: 24,
                    color: AppColors.success.withValues(alpha: 0.9),
                  ),
                ),
              ),
            ),
            ..._buildSparkles(s),
          ],
        );
      },
    );
  }

  List<Widget> _buildFloatingReceipts(double t) {
    final items = <_FloatingItemData>[
      _FloatingItemData(
        x: -80,
        y: 40,
        icon: Icons.receipt_long_rounded,
        color: AppColors.primaryAccent,
        phase: 0,
      ),
      _FloatingItemData(
        x: 80,
        y: 30,
        icon: Icons.description_rounded,
        color: AppColors.secondaryAccent,
        phase: 0.5,
      ),
      _FloatingItemData(
        x: 70,
        y: 160,
        icon: Icons.bar_chart_rounded,
        color: AppColors.primaryAccent,
        phase: 0.25,
      ),
    ];

    return items.map((item) {
      final yOff = sin((t + item.phase) * 2 * pi) * 8;
      return Positioned(
        left: 130 + item.x,
        top: item.y.toDouble(),
        child: Transform.translate(
          offset: Offset(0, yOff),
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: item.color.withValues(alpha: 0.25),
                width: 1.5,
              ),
            ),
            child: Icon(
              item.icon,
              size: 20,
              color: item.color.withValues(alpha: 0.8),
            ),
          ),
        ),
      );
    }).toList();
  }

  List<Widget> _buildSparkles(double s) {
    final sparkles = <_SparkleData>[
      _SparkleData(x: -90, y: 10, phase: 0),
      _SparkleData(x: 100, y: 80, phase: 0.33),
      _SparkleData(x: -60, y: 170, phase: 0.66),
      _SparkleData(x: 90, y: 150, phase: 0.5),
    ];

    return sparkles.map((sparkle) {
      final phase = ((s + sparkle.phase) % 1.0);
      final opacity = phase < 0.5 ? phase * 2 : (1.0 - phase) * 2;
      final scale = 0.4 + opacity * 0.6;

      return Positioned(
        left: 130 + sparkle.x,
        top: sparkle.y.toDouble(),
        child: Transform.scale(
          scale: scale,
          child: Opacity(
            opacity: opacity.clamp(0.0, 0.7),
            child: const Icon(
              Icons.auto_awesome,
              size: 16,
              color: AppColors.warning,
            ),
          ),
        ),
      );
    }).toList();
  }
}

class _FloatingItemData {
  final double x;
  final double y;
  final IconData icon;
  final Color color;
  final double phase;

  const _FloatingItemData({
    required this.x,
    required this.y,
    required this.icon,
    required this.color,
    required this.phase,
  });
}

class _SparkleData {
  final double x;
  final double y;
  final double phase;

  const _SparkleData({
    required this.x,
    required this.y,
    required this.phase,
  });
}
