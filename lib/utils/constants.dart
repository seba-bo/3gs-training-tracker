import 'package:flutter/material.dart';
import 'app_theme.dart';

class AppConstants {
  // Validation
  static const double minTime = 0.1;
  static const double maxTime = 999.0;
  static const int minPoints = 0;
  static const int maxPoints = 200; // Full score - triggers 🎯 emoji when achieved with 0 penalties

  // Colors (Legacy - für Rückwärtskompatibilität)
  static const Color primaryBg = AppTheme.primaryDark;
  static const Color secondaryBg = AppTheme.secondaryDark;
  static const Color cardBg = AppTheme.cardBg;
  
  // Medals
  static const String goldMedal = '🥇';
  static const String silverMedal = '🥈';
  static const String bronzeMedal = '🥉';
  static const String perfectScore = '🎯'; // For runs with max points and 0 penalties
}