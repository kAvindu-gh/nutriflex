import 'package:flutter/material.dart';

class CalorieProvider extends ChangeNotifier {
  double _dailyCalories = 0;

  double get dailyCalories => _dailyCalories;

  /// Returns a formatted string like "2,450" or "Not set" if not calculated yet.
  String get displayValue {
    if (_dailyCalories <= 0) return 'Not set';
    return _dailyCalories
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
  }

  /// Call this from the BMI page after TDEE is calculated.
  void setDailyCalories(double calories) {
    _dailyCalories = calories;
    notifyListeners();
  }

  /// Reset back to default (e.g. on logout).
  void reset() {
    _dailyCalories = 0;
    notifyListeners();
  }
}