import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OptimizationSettingsProvider extends ChangeNotifier {
  static const String _weekLimitKey = 'optimization_week_limit';
  static const String _monthLimitKey = 'optimization_month_limit';

  double _weekLimit = 50.0; // По умолчанию 50 л/неделю
  double _monthLimit = 150.0; // По умолчанию 150 л/месяц
  bool _isLoading = false;

  double get weekLimit => _weekLimit;
  double get monthLimit => _monthLimit;
  bool get isLoading => _isLoading;

  Future<void> loadSettings() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      _weekLimit = prefs.getDouble(_weekLimitKey) ?? 50.0;
      _monthLimit = prefs.getDouble(_monthLimitKey) ?? 150.0;
    } catch (e) {
      _weekLimit = 50.0;
      _monthLimit = 150.0;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> updateWeekLimit(double newLimit) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_weekLimitKey, newLimit);
      _weekLimit = newLimit;
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateMonthLimit(double newLimit) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_monthLimitKey, newLimit);
      _monthLimit = newLimit;
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateLimits(double weekLimit, double monthLimit) async {
    if (monthLimit < weekLimit) return false; // y >= x
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_weekLimitKey, weekLimit);
      await prefs.setDouble(_monthLimitKey, monthLimit);
      _weekLimit = weekLimit;
      _monthLimit = monthLimit;
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }
}