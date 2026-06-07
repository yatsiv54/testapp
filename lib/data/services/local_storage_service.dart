import 'package:shared_preferences/shared_preferences.dart';
import '../models/expense.dart';
import '../models/user_profile.dart';

class LocalStorageService {
  static const String _profileKey = 'user_profile';
  static const String _expensesKey = 'expenses_list';
  static const String _leftoversKey = 'leftovers_balance';
  static const String _lastWheelSpinKey = 'last_wheel_spin_date';
  static const String _currencyKey = 'currency';
  static const String _notificationsKey = 'notifications_enabled';
  static const String _analyticsKey = 'advanced_analytics';
  static const String _photoKey = 'require_photo';
  static const String _themeKey = 'theme_mode';
  static const String _lastLeftoverCalcDateKey = 'last_leftover_calc_date';

  Future<void> saveProfile(UserProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profileKey, profile.toJson());
  }

  Future<UserProfile?> getProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_profileKey);
    if (data != null) {
      return UserProfile.fromJson(data);
    }
    return null;
  }

  Future<void> saveExpenses(List<Expense> expenses) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> data = expenses.map((e) => e.toJson()).toList();
    await prefs.setStringList(_expensesKey, data);
  }

  Future<List<Expense>> getExpenses() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? data = prefs.getStringList(_expensesKey);
    if (data != null) {
      return data.map((e) => Expense.fromJson(e)).toList();
    }
    return [];
  }

  Future<void> saveLeftovers(double amount) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_leftoversKey, amount);
  }

  Future<double> getLeftovers() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_leftoversKey) ?? 0.0;
  }

  Future<void> setLastWheelSpinDate(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastWheelSpinKey, date.toIso8601String());
  }

  Future<DateTime?> getLastWheelSpinDate() async {
    final prefs = await SharedPreferences.getInstance();
    final dateStr = prefs.getString(_lastWheelSpinKey);
    if (dateStr != null) {
      return DateTime.parse(dateStr);
    }
    return null;
  }

  Future<void> saveLastLeftoverCalcDate(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastLeftoverCalcDateKey, date.toIso8601String());
  }

  Future<DateTime?> getLastLeftoverCalcDate() async {
    final prefs = await SharedPreferences.getInstance();
    final dateStr = prefs.getString(_lastLeftoverCalcDateKey);
    return dateStr != null ? DateTime.parse(dateStr) : null;
  }

  Future<void> saveCurrency(String currency) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currencyKey, currency);
  }

  Future<String> getCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_currencyKey) ?? 'USD';
  }

  Future<void> setNotificationsEnabled(bool val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsKey, val);
  }

  Future<bool> getNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_notificationsKey) ?? false;
  }

  Future<void> setAdvancedAnalytics(bool val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_analyticsKey, val);
  }

  Future<bool> getAdvancedAnalytics() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_analyticsKey) ?? false;
  }

  Future<void> setRequirePhoto(bool val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_photoKey, val);
  }

  Future<bool> getRequirePhoto() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_photoKey) ?? true;
  }

  Future<String?> getLastSpinDate() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('last_spin_date');
  }

  Future<void> saveLastSpinDate(String dateIso) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_spin_date', dateIso);
  }

  Future<void> setThemeMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, mode);
  }

  Future<String> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_themeKey) ?? 'light';
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
