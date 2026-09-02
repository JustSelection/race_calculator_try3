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

      // 🆕 ИЗМЕНЕНО: Создаем события заправки для каждого агрегата отдельно.
      // Мы используем relatedId как generatorId, чтобы не менять структуру БД, 
      // и это позволит фильтровать статистику заправок по автомобилю!
      if (newLevels.isEmpty) {
        await _eventDao.insert(AnalyticsEventModel(
          type: 'refuel',
          date: refuel.date,
          description: 'Заправка (без привязки): по чеку заправлено ${refuel.totalFuel} л',
          relatedId: -1, // Маркер "без привязки к агрегату"
        ));
      } else {
        for (final entry in newLevels.entries) {
          final genId = entry.key;
          final newLevel = entry.value;
          
          final gen = generators.firstWhere(
            (g) => g.id == genId,
            orElse: () => GeneratorModel(name: 'Неизвестный', capacity: 0, currentFuel: 0, carId: null),
          );
          
          final fuelAdded = newLevel - gen.currentFuel;
          if (fuelAdded > 0) {
            await _eventDao.insert(AnalyticsEventModel(
              type: 'refuel',
              date: refuel.date,
              description: 'Заправка ${gen.name}: по чеку заправлено ${fuelAdded.toStringAsFixed(2)} л',
              relatedId: genId, // 🆕 Теперь relatedId хранит ID агрегата для фильтрации!
            ));
          }

          await _dao.insertDistribution({
            'refuelId': id,
            'generatorId': genId,
            'fuelAmount': newLevel,
          });
          
          await _genDao.updateFuel(genId, newLevel);
        }
      }

      // Если есть общий расход, записываем его ОДНИМ событием
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