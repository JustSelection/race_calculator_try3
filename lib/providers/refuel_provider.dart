import 'package:flutter/foundation.dart';
import '../models/refuel_model.dart';
import '../models/analytics_event_model.dart';
import '../services/refuel_dao.dart';
import '../services/analytics_event_dao.dart';
import '../services/generator_dao.dart';

class RefuelProvider extends ChangeNotifier {
  final RefuelDao _dao = RefuelDao();
  final AnalyticsEventDao _eventDao = AnalyticsEventDao();
  final GeneratorDao _genDao = GeneratorDao();
  
  List<RefuelModel> _refuels = [];
  bool _isLoading = false;

  List<RefuelModel> get refuels => _refuels;
  bool get isLoading => _isLoading;

  Future<void> loadRefuels() async {
    _isLoading = true;
    notifyListeners();
    _refuels = await _dao.getAll();
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> addRefuel(RefuelModel refuel, Map<int, double> newLevels) async {
    _isLoading = true;
    notifyListeners();
    try {
      final id = await _dao.insert(refuel);
      if (id <= 0) return false;

      final newRefuel = refuel.copyWith(id: id);
      _refuels.insert(0, newRefuel);

      for (final entry in newLevels.entries) {
        await _dao.insertDistribution({
          'refuelId': id,
          'generatorId': entry.key,
          'fuelAmount': entry.value,
        });
        
        await _genDao.updateFuel(entry.key, entry.value);

        await _eventDao.insert(AnalyticsEventModel(
          type: 'refuel',
          date: refuel.date,
          description: 'Заправка: уровень установлен на ${entry.value} л',
          relatedId: entry.key,
        ));
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // 🆕 ДОБАВЛЕНО: Метод для очистки истории заправок (чтобы сбросить оборот в аналитике)
  Future<void> clearRefuels() async {
    await _dao.deleteAll(); // Удаляем все записи из базы данных
    _refuels = [];          // Очищаем список в памяти
    notifyListeners();      // Уведомляем интерфейс об изменениях
  }
}