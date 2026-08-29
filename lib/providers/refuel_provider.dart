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
    // 🛡️ ЗАЩИТА: Если карта пустая, прерываем выполнение, чтобы избежать ошибок
    if (newLevels.isEmpty) return false;

    _isLoading = true;
    notifyListeners();
    try {
      final id = await _dao.insert(refuel);
      if (id <= 0) return false;

      final newRefuel = refuel.copyWith(id: id);
      _refuels.insert(0, newRefuel);

      // Получаем текущие уровни агрегатов
      final generators = await _genDao.getAll();
      
      // Считаем сколько было ДО заправки (ТОЛЬКО в тех агрегатах, которые меняем)
      double totalOldFuel = 0.0;
      for (final genId in newLevels.keys) {
        final gen = generators.firstWhere(
          (g) => g.id == genId, 
          orElse: () => GeneratorModel(name: '', capacity: 0, currentFuel: 0, carId: null),
        );
        totalOldFuel += gen.currentFuel;
      }

      // Считаем сколько стало ПОСЛЕ (сумма новых уровней)
      double totalNewFuel = 0.0;
      for (final level in newLevels.values) {
        totalNewFuel += level;
      }

      // Ожидаемая сумма: было + заправили
      final expectedTotal = totalOldFuel + refuel.totalFuel;
      
      // Расход = ожидаемое - фактическое
      final totalConsumption = expectedTotal - totalNewFuel;

      // Обновляем уровни и записываем распределение
      for (final entry in newLevels.entries) {
        final genId = entry.key;
        final newLevel = entry.value;

        await _dao.insertDistribution({
          'refuelId': id,
          'generatorId': genId,
          'fuelAmount': newLevel,
        });
        
        await _genDao.updateFuel(genId, newLevel);

        await _eventDao.insert(AnalyticsEventModel(
          type: 'refuel',
          date: refuel.date,
          description: 'Заправка: уровень установлен на ${newLevel.toStringAsFixed(2)} л',
          relatedId: genId,
        ));
      }

      // Если есть общий расход (положительное значение), записываем его в аналитику
      if (totalConsumption > 0.01) {
        final firstGenId = newLevels.keys.first;
        
        await _invDao.insert(InventoryModel(
          generatorId: firstGenId,
          date: refuel.date,
          previousFuel: expectedTotal, // Примечание: это сумма по системе
          actualFuel: totalNewFuel,    // Примечание: это сумма по системе
          difference: -totalConsumption, // отрицательное = расход
        ));
        
        await _eventDao.insert(AnalyticsEventModel(
          type: 'inventory',
          date: refuel.date,
          description: 'Расход при заправке: ${totalConsumption.toStringAsFixed(2)} л',
          relatedId: firstGenId,
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

  Future<void> clearRefuels() async {
    await _dao.deleteAll();
    _refuels = [];
    notifyListeners();
  }
}