import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import 'onboarding_screen.dart';
import 'main_screen.dart';

class PreloaderScreen extends StatefulWidget {
  const PreloaderScreen({super.key});

  @override
  State<PreloaderScreen> createState() => _PreloaderScreenState();
}

class _PreloaderScreenState extends State<PreloaderScreen>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  late final AnimationController _fadeInController;
  late final Animation<double> _titleFadeAnimation;
  late final Animation<double> _loaderFadeAnimation;

  late final AnimationController _fadeOutController;
  late final Animation<double> _fadeOutAnimation;

  late final AnimationController _dotController;

  String _statusText = '';

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _fadeInController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _titleFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeInController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _loaderFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeInController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );

    _fadeOutController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeOutAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _fadeOutController, curve: Curves.easeInOut),
    );

    _dotController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _fadeInController.forward();
    });

    _initApp();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _fadeInController.dispose();
    _fadeOutController.dispose();
    _dotController.dispose();
    super.dispose();
  }

  Future<void> _initApp() async {
    final stopwatch = Stopwatch()..start();

    _updateStatus('Requesting permissions...');
    await [
      Permission.camera,
      if (Platform.isAndroid) Permission.storage,
      if (Platform.isIOS) Permission.photos,
    ].request();

    if (!mounted) return;

    _updateStatus('Checking local DB availability...');
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    _updateStatus('Ready!');

    stopwatch.stop();
    final elapsed = stopwatch.elapsedMilliseconds;
    const minSplash = 2500;
    if (elapsed < minSplash) {
      await Future.delayed(Duration(milliseconds: minSplash - elapsed));
    }

    if (!mounted) return;

    await _fadeOutController.forward();
    if (!mounted) return;

    final bool hasSeenOnboarding =
        prefs.getBool('hasSeenOnboarding') ?? false;

    if (!hasSeenOnboarding) {
      await prefs.setBool('hasSeenOnboarding', true);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const OnboardingScreen(),
          transitionDuration: const Duration(milliseconds: 500),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    } else {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const MainScreen(),
          transitionDuration: const Duration(milliseconds: 500),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    }
  }

  void _updateStatus(String text) {
    if (mounted) {
      setState(() => _statusText = text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FadeTransition(
        opacity: _fadeOutAnimation,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Theme.of(context).scaffoldBackgroundColor,
                Theme.of(context).cardColor,
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 3),
                ScaleTransition(
                  scale: _pulseAnimation,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppColors.primaryGradient,
                      boxShadow: [
                        BoxShadow(
                          color:
                              AppColors.primaryAccent.withValues(alpha: 0.35),
                          blurRadius: 40,
                          spreadRadius: 4,
                          offset: const Offset(0, 8),
                        ),
                        BoxShadow(
                          color: AppColors.secondaryAccent
                              .withValues(alpha: 0.2),
                          blurRadius: 60,
                          spreadRadius: 2,
                          offset: const Offset(0, 16),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.savings_rounded,
                        size: 56,
                        color: AppColors.secondaryBackground,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 36),
                FadeTransition(
                  opacity: _titleFadeAnimation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.3),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                        parent: _fadeInController,
                        curve: const Interval(
                          0.0,
                          0.6,
                          curve: Curves.easeOut,
                        ),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Salary Leftovers',
                          style: AppTypography.headline1.copyWith(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Collector',
                          style: AppTypography.headline2.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 48),
                FadeTransition(
                  opacity: _loaderFadeAnimation,
                  child: _PulsingDotsLoader(controller: _dotController),
                ),
                const SizedBox(height: 24),
                FadeTransition(
                  opacity: _loaderFadeAnimation,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Text(
                      _statusText,
                      key: ValueKey(_statusText),
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ),
                const Spacer(flex: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PulsingDotsLoader extends StatelessWidget {
  final AnimationController controller;

  const _PulsingDotsLoader({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (index) {
            final delay = index * 0.3;
            final progress =
                ((controller.value - delay) % 1.0).clamp(0.0, 1.0);
            final scale = 0.5 + 0.5 * sin(progress * pi);
            final opacity = 0.4 + 0.6 * sin(progress * pi);

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 5),
              child: Transform.scale(
                scale: scale,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primaryAccent.withValues(alpha: opacity),
                        AppColors.secondaryAccent.withValues(alpha: opacity),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
