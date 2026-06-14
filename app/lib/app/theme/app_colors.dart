import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AppColors {
  AppColors._();

  static Color get background => Get.isDarkMode ? const Color(0xFF06080F) : const Color(0xFFF8FAFC);
  static Color get surface => Get.isDarkMode ? const Color(0xFF111420) : const Color(0xFFFFFFFF);
  static Color get surfaceLight => Get.isDarkMode ? const Color(0xFF1B2035) : const Color(0xFFF1F5F9);
  static Color get primary => const Color(0xFF3B82F6);
  static Color get primaryLight => Get.isDarkMode ? const Color(0xFF60A5FA) : const Color(0xFF2563EB);
  static Color get accent => Get.isDarkMode ? const Color(0xFFFFFFFF) : const Color(0xFF0F172A);
  static Color get accentGreen => const Color(0xFF3B82F6);
  static Color get textPrimary => Get.isDarkMode ? const Color(0xFFFFFFFF) : const Color(0xFF0F172A);
  static Color get textSecondary => Get.isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF475569);
  static Color get error => const Color(0xFFEF4444);
  static Color get border => Get.isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);

  static List<Color> get pathwayGradients => Get.isDarkMode
      ? const [
          Color(0xFF2563EB),
          Color(0xFF1D4ED8),
          Color(0xFF60A5FA),
          Color(0xFF3B82F6),
          Color(0xFF93C5FD),
          Color(0xFF1E3A8A),
        ]
      : const [
          Color(0xFF3B82F6),
          Color(0xFF1E3A8A),
          Color(0xFF60A5FA),
          Color(0xFF2563EB),
          Color(0xFF93C5FD),
          Color(0xFF1D4ED8),
        ];
}
