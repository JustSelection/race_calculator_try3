import 'package:flutter/foundation.dart';
import '../models/refuel_model.dart';
import '../models/analytics_event_model.dart';
import '../models/inventory_model.dart';
import '../models/generator_model.dart';
import '../services/refuel_dao.dart';
import '../services/analytics_event_dao.dart';
import '../services/generator_dao.dart';
import '../services/inventory_dao.dart';

class RefuelProvider extends ChangeNotifier {
  final RefuelDao _dao = RefuelDao();
  final AnalyticsEventDao _eventDao = AnalyticsEventDao();
  final GeneratorDao _genDao = GeneratorDao();
  final InventoryDao _invDao = InventoryDao();
  
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

      final generators = await _genDao.getAll();
      
      double totalOldFuel = 0.0;
      for (final genId in newLevels.keys) {
        final gen = generators.firstWhere(
          (g) => g.id == genId, 
          orElse: () => GeneratorModel(name: '', capacity: 0, currentFuel: 0, carId: null),
        );
        totalOldFuel += gen.currentFuel;
      }

      double totalNewFuel = 0.0;
      for (final level in newLevels.values) {
        totalNewFuel += level;
      }

      final expectedTotal = totalOldFuel + refuel.totalFuel;
      final totalConsumption = expectedTotal - totalNewFuel;

      // 🆕 КЛЮЧЕВОЕ ИСПРАВЛЕНИЕ: Создаем ОДНО событие заправки на весь чек.
      // Это гарантирует, что в аналитике сумма не задвоится и всегда покажет точный объем по чеку.
      await _eventDao.insert(AnalyticsEventModel(
        type: 'refuel',
        date: refuel.date,
        description: 'Заправка: по чеку ${refuel.totalFuel.toStringAsFixed(2)} л',
        relatedId: newLevels.isNotEmpty ? newLevels.keys.first : -1, // Привязка к агрегату для фильтрации по авто
      ));

      // Обновляем уровни топлива в агрегатах (без создания лишних событий)
      for (final entry in newLevels.entries) {
        final genId = entry.key;
        final newLevel = entry.value;

        await _dao.insertDistribution({
          'refuelId': id,
          'generatorId': genId,
          'fuelAmount': newLevel,
        });
        
        await _genDao.updateFuel(genId, newLevel);
      }

      // Если есть общий расход, записываем его ОДНИМ событием "Работа агрегата"
      if (totalConsumption > 0.01) {
        final targetGenId = newLevels.isNotEmpty ? newLevels.keys.first : -1;
        
        await _invDao.insert(InventoryModel(
          generatorId: targetGenId,
          date: refuel.date,
          previousFuel: expectedTotal,
          actualFuel: totalNewFuel,
          difference: -totalConsumption,
        ));
        
        await _eventDao.insert(AnalyticsEventModel(
          type: 'inventory',
          date: refuel.date,
          description: 'Работа агрегата: расход при заправке ${totalConsumption.toStringAsFixed(2)} л',
          relatedId: targetGenId,
        ));
      }
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Ошибка при добавлении заправки: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> clearRefuels() async {
    await _dao.deleteAll();
    _refuels = [];
    notifyListeners();
  }
}