import 'package:flutter/foundation.dart';
import '../models/calibration_model.dart';
import '../models/analytics_event_model.dart';
import '../services/calibration_dao.dart';
import '../services/analytics_event_dao.dart';
import '../services/generator_dao.dart';

class CalibrationProvider extends ChangeNotifier {
  final CalibrationDao _dao = CalibrationDao();
  final AnalyticsEventDao _eventDao = AnalyticsEventDao();
  final GeneratorDao _genDao = GeneratorDao();
  
  List<CalibrationModel> _calibrations = [];
  bool _isLoading = false;

  List<CalibrationModel> get calibrations => _calibrations;
  bool get isLoading => _isLoading;

  Future<void> loadCalibrations() async {
    _isLoading = true;
    notifyListeners();
    _calibrations = await _dao.getAll();
    _isLoading = false;
    notifyListeners();
  }

  /// Проводит глобальную калибровку: сбрасывает топливо во всех агрегатах
  /// и записывает событие в аналитику
  Future<bool> performCalibration(
      CalibrationModel calibration,
      Map<int, double> newFuelLevels) async { // generatorId -> newFuelLevel
    _isLoading = true;
    notifyListeners();
    try {
      // 1. Сохраняем запись о калибровке
      final id = await _dao.insert(calibration);
      if (id <= 0) return false;

      final newCalibration = calibration.copyWith(id: id);
      _calibrations.insert(0, newCalibration);

      // 2. Обновляем уровни топлива во всех агрегатах
      for (final entry in newFuelLevels.entries) {
        await _genDao.updateFuel(entry.key, entry.value);
      }

      // 3. Записываем событие в аналитику
      await _eventDao.insert(AnalyticsEventModel(
        type: 'calibration',
        date: calibration.date,
        description: 'Калибровка: ${calibration.comment}',
      ));

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}