import 'package:flutter/foundation.dart';
import '../models/optimization_model.dart';
import '../models/analytics_event_model.dart';
import '../services/optimization_dao.dart';
import '../services/analytics_event_dao.dart';

class OptimizationProvider extends ChangeNotifier {
  final OptimizationDao _dao = OptimizationDao();
  final AnalyticsEventDao _eventDao = AnalyticsEventDao();
  
  List<OptimizationModel> _optimizations = [];
  double _weekSum = 0.0;
  double _monthSum = 0.0;
  bool _isLoading = false;

  List<OptimizationModel> get optimizations => _optimizations;
  double get weekSum => _weekSum;
  double get monthSum => _monthSum;
  bool get isLoading => _isLoading;

  Future<void> loadOptimizations({int? generatorId}) async {
    _isLoading = true;
    notifyListeners();

    _optimizations = generatorId != null 
        ? await _dao.getByGeneratorId(generatorId) 
        : await _dao.getAll();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadAnalytics() async {
    _weekSum = await _dao.getSumForWeek();
    _monthSum = await _dao.getSumForMonth();
    notifyListeners();
  }

  Future<bool> addOptimization(OptimizationModel optimization) async {
    final id = await _dao.insert(optimization);
    if (id > 0) {
      // 🆕 ИЗМЕНЕНО: Убрано слово "списано", оставлена только "Оптимизация"
      await _eventDao.insert(AnalyticsEventModel(
        type: 'optimization',
        date: optimization.date,
        description: 'Оптимизация: ${optimization.fuelAmount.toStringAsFixed(2)} л',
        relatedId: optimization.generatorId,
      ));

      await loadOptimizations();
      await loadAnalytics();
      return true;
    }
    return false;
  }

  Future<bool> deleteOptimization(int id) async {
    final rows = await _dao.delete(id);
    if (rows > 0) {
      await loadOptimizations();
      await loadAnalytics();
      return true;
    }
    return false;
  }

  Future<void> clearOptimizations() async {
    await _dao.deleteAll();
    _optimizations = [];
    _weekSum = 0.0;
    _monthSum = 0.0;
    notifyListeners();
  }
}