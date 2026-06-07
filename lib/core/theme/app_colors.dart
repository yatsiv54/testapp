import 'package:flutter/material.dart';

class AppColors {
  static const Color primaryBackground = Color(0xFFF7FAFF);
  static const Color secondaryBackground = Color(0xFFFFFFFF);
  static const Color primaryAccent = Color(0xFF2A7BDE);
  static const Color secondaryAccent = Color(0xFF8C3ED6);
  static const Color textPrimary = Color(0xFF232A34);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color border = Color(0xFFE3E8F0);
  static const Color success = Color(0xFF3AD29F);
  static const Color warning = Color(0xFFF8B400);
  static const Color error = Color(0xFFE94F37);
  static const Color cardBackground = Color(0xFFF1F5FB);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryAccent, secondaryAccent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
 