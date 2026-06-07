import 'package:flutter/material.dart';
import '../data/models/user_profile.dart';
import '../data/services/local_storage_service.dart';

class HomeViewModel extends ChangeNotifier {
  final LocalStorageService _storage = LocalStorageService();
  
  UserProfile? _profile;
  double _leftovers = 0.0;
  bool _isLoading = true;

  UserProfile? get profile => _profile;
  double get leftovers => _leftovers;
  bool get isLoading => _isLoading;

  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();

    _profile = await _storage.getProfile();
    _leftovers = await _storage.getLeftovers();

    if (_profile != null) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      DateTime? lastCalc = await _storage.getLastLeftoverCalcDate();

      if (lastCalc == null) {
        // First time initialization
        await _storage.saveLastLeftoverCalcDate(today);
      } else {
        lastCalc = DateTime(lastCalc.year, lastCalc.month, lastCalc.day);
        final difference = today.difference(lastCalc).inDays;

        if (difference > 0) {
          final expenses = await _storage.getExpenses();
          double accumulatedLeftovers = 0;

          for (int i = 0; i < difference; i++) {
            final targetDate = lastCalc.add(Duration(days: i));
            final dailyExpenses = expenses.where((e) {
              return e.date.year == targetDate.year &&
                  e.date.month == targetDate.month &&
                  e.date.day == targetDate.day;
            }).fold(0.0, (sum, e) => sum + e.amount);

            accumulatedLeftovers += (_profile!.dailyLimit - dailyExpenses);
          }

          _leftovers += accumulatedLeftovers;
          await _storage.saveLeftovers(_leftovers);
          await _storage.saveLastLeftoverCalcDate(today);
        }
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateLeftovers(double amount) async {
    _leftovers += amount;
    await _storage.saveLeftovers(_leftovers);
    notifyListeners();
  }
}
