import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../core/theme/app_colors.dart';

class EmptyStateWidget extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const EmptyStateWidget({
    super.key,
    required this.title,
    required this.subtitle,
    this.icon = Icons.inbox_outlined,
  });

  @override
  State<EmptyStateWidget> createState() => _EmptyStateWidgetState();
}

class _EmptyStateWidgetState extends State<EmptyStateWidget>
    with TickerProviderStateMixin {
  late final AnimationController _floatController;
  late final AnimationController _fadeController;
  late final AnimationController _dotController;
  late final Animation<double> _floatAnimation;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _dotAnimation;

  @override
  void initState() {
    super.initState();

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: -6.0, end: 6.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    _dotController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();

    _dotAnimation = CurvedAnimation(
      parent: _dotController,
      curve: Curves.linear,
    );
  }

  @override
  void dispose() {
    _floatController.dispose();
    _fadeController.dispose();
    _dotController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 140,
                height: 140,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    ..._buildDecorativeDots(),
                    AnimatedBuilder(
                      animation: _floatAnimation,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, _floatAnimation.value),
                          child: child,
                        );
                      },
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primaryAccent.withValues(alpha: 0.12),
                              AppColors.secondaryAccent.withValues(alpha: 0.10),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryAccent.withValues(alpha: 0.15),
                              blurRadius: 24,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Icon(
                          widget.icon,
                          size: 48,
                          color: AppColors.primaryAccent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                widget.title,
                style: theme.textTheme.displayMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                widget.subtitle,
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildDecorativeDots() {
    final dots = <_DotConfig>[
      _DotConfig(angle: 0, radius: 58, size: 8, color: AppColors.primaryAccent),
      _DotConfig(angle: math.pi * 0.4, radius: 62, size: 6, color: AppColors.secondaryAccent),
      _DotConfig(angle: math.pi * 0.8, radius: 55, size: 10, color: AppColors.success),
      _DotConfig(angle: math.pi * 1.2, radius: 60, size: 5, color: AppColors.warning),
      _DotConfig(angle: math.pi * 1.6, radius: 56, size: 7, color: AppColors.primaryAccent),
    ];

    return dots.asMap().entries.map((entry) {
      final index = entry.key;
      final dot = entry.value;
      return AnimatedBuilder(
        animation: _dotAnimation,
        builder: (context, child) {
          final progress = (_dotAnimation.value + index * 0.2) % 1.0;
          final angle = dot.angle + progress * math.pi * 2;
          final floatOffset = math.sin(progress * math.pi * 2) * 4;
          final opacity = 0.3 + 0.5 * math.sin(progress * math.pi);

          return Positioned(
            left: 70 + math.cos(angle) * dot.radius - dot.size / 2,
            top: 70 + math.sin(angle) * dot.radius - dot.size / 2 + floatOffset,
            child: Opacity(
              opacity: opacity,
              child: Container(
                width: dot.size,
                height: dot.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: dot.color.withValues(alpha: 0.6),
                ),
              ),
            ),
          );
        },
      );
    }).toList();
  }
}

class _DotConfig {
  final double angle;
  final double radius;
  final double size;
  final Color color;

  const _DotConfig({
    required this.angle,
    required this.radius,
    required this.size,
    required this.color,
  });
}
