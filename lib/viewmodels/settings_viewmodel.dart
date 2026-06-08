import 'package:flutter/material.dart';
import '../data/services/local_storage_service.dart';

class SettingsViewModel extends ChangeNotifier {
  final LocalStorageService _storage = LocalStorageService();

  bool _isLoading = true;
  String? _errorMessage;
  String _currency = 'USD';
  bool _notificationsEnabled = false;
  bool _advancedAnalytics = false;
  bool _requirePhoto = true;
  String _themeMode = 'light';

  bool get isLoading => _isLoading;
  bool get hasError => _errorMessage != null;
  String? get errorMessage => _errorMessage;
  String get currency => _currency;
  bool get notificationsEnabled => _notificationsEnabled;
  bool get advancedAnalytics => _advancedAnalytics;
  bool get requirePhoto => _requirePhoto;
  String get themeMode => _themeMode;

  Future<void> loadSettings() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currency = await _storage.getCurrency();
      _notificationsEnabled = await _storage.getNotificationsEnabled();
      _advancedAnalytics = await _storage.getAdvancedAnalytics();
      _requirePhoto = await _storage.getRequirePhoto();
      _themeMode = await _storage.getThemeMode();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setCurrency(String val) async {
    _currency = val;
    await _storage.saveCurrency(val);
    notifyListeners();
  }

  Future<void> setNotificationsEnabled(bool val) async {
    _notificationsEnabled = val;
    await _storage.setNotificationsEnabled(val);
    notifyListeners();
  }

  Future<void> setAdvancedAnalytics(bool val) async {
    _advancedAnalytics = val;
    await _storage.setAdvancedAnalytics(val);
    notifyListeners();
  }

  Future<void> setRequirePhoto(bool val) async {
    _requirePhoto = val;
    await _storage.setRequirePhoto(val);
    notifyListeners();
  }

  Future<void> setThemeMode(String val) async {
    _themeMode = val;
    await _storage.setThemeMode(val);
    notifyListeners();
  }

  Future<void> clearAllData() async {
    await _storage.clearAll();
    // In a real app we might want to reload everything or restart
    notifyListeners();
  }
}
