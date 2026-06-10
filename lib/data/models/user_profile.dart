import 'dart:convert';
import '../../core/utils/image_helper.dart';

class UserProfile {
  final String name;
  final String photoPath;
  final double dailyLimit;

  UserProfile({
    required this.name,
    required this.photoPath,
    required this.dailyLimit,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'photoPath': photoPath,
      'dailyLimit': dailyLimit,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      name: map['name'] ?? '',
      photoPath: ImageHelper.getAbsolutePath(map['photoPath'] ?? ''),
      dailyLimit: map['dailyLimit']?.toDouble() ?? 0.0,
    );
  }

  String toJson() => json.encode(toMap());

  factory UserProfile.fromJson(String source) =>
      UserProfile.fromMap(json.decode(source));
}
