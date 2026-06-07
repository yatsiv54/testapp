import 'package:flutter/material.dart';
import '../../core/utils/animated_button.dart';
import '../../core/theme/app_colors.dart';

import 'profile_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _currentIndex = 0;

  void _next() {
    if (_currentIndex == 0) {
      setState(() => _currentIndex = 1);
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const ProfileScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Spacer(),
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.primaryGradient,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryAccent.withValues(alpha: 0.3),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    _currentIndex == 0 ? Icons.account_balance_wallet : Icons.camera_alt,
                    size: 80,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 48),
              Text(
                _currentIndex == 0
                    ? 'Welcome to Salary Leftovers Collector'
                    : 'Track Expenses with Photos',
                style: Theme.of(context).textTheme.displayMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                _currentIndex == 0
                    ? 'Efficiently track daily expenses and accumulate leftovers from your daily salary limit.'
                    : 'Take a photo of your receipt or item, save it, and view it later. Spin the wheel daily for a chance to multiply leftovers!',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              Spacer(),
              AnimatedButton(
                onPressed: _next,
                child: Text(
                  _currentIndex == 0 ? 'Next' : 'Get Started',
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
