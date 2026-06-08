import 'package:flutter/material.dart';
import '../data/models/user_profile.dart';
import '../data/services/local_storage_service.dart';

class ProfileViewModel extends ChangeNotifier {
  final LocalStorageService _storage = LocalStorageService();
  bool _isLoading = false;
  String? _errorMessage;
  
  bool get isLoading => _isLoading;
  bool get hasError => _errorMessage != null;
  String? get errorMessage => _errorMessage;

  Future<void> saveProfile(String name, double limit, String photoPath) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final profile = UserProfile(
        name: name,
        dailyLimit: limit,
        photoPath: photoPath,
      );
      await _storage.saveProfile(profile);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
