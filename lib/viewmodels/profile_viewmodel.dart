import 'package:flutter/material.dart';
import '../data/models/user_profile.dart';
import '../data/services/local_storage_service.dart';

class ProfileViewModel extends ChangeNotifier {
  final LocalStorageService _storage = LocalStorageService();
  bool _isLoading = false;
  
  bool get isLoading => _isLoading;

  Future<void> saveProfile(String name, double limit, String photoPath) async {
    _isLoading = true;
    notifyListeners();

    final profile = UserProfile(
      name: name,
      dailyLimit: limit,
      photoPath: photoPath,
    );
    await _storage.saveProfile(profile);

    _isLoading = false;
    notifyListeners();
  }
}
