import 'package:flutter/foundation.dart';
import '../models/optimization_model.dart';
import '../services/optimization_dao.dart';

class OptimizationProvider extends ChangeNotifier {
  final OptimizationDao _dao = OptimizationDao();
  
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

  // 🆕 ДОБАВЛЕНО: Метод для полного сброса истории оптимизаций (используется при глобальной калибровке)
  Future<void> clearOptimizations() async {
    await _dao.deleteAll(); // Удаляем все записи из базы
    _optimizations = [];    // Очищаем список в памяти
    _weekSum = 0.0;         // Обнуляем недельную сумму
    _monthSum = 0.0;        // Обнуляем месячную сумму
    notifyListeners();      // Уведомляем интерфейс об изменениях
  }
}