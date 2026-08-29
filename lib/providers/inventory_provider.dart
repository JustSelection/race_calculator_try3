import 'package:flutter/foundation.dart';
import '../models/inventory_model.dart';
import '../models/analytics_event_model.dart';
import '../services/inventory_dao.dart';
import '../services/analytics_event_dao.dart';
import '../services/generator_dao.dart';

class InventoryProvider extends ChangeNotifier {
  final InventoryDao _dao = InventoryDao();
  final AnalyticsEventDao _eventDao = AnalyticsEventDao();
  final GeneratorDao _genDao = GeneratorDao();
  
  List<InventoryModel> _inventories = [];
  bool _isLoading = false;

  List<InventoryModel> get inventories => _inventories;
  bool get isLoading => _isLoading;

  Future<void> loadInventories({int? generatorId}) async {
    _isLoading = true;
    notifyListeners();
    _inventories = generatorId != null 
        ? await _dao.getByGeneratorId(generatorId) 
        : await _dao.getAll();
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> addInventory(InventoryModel inventory) async {
    _isLoading = true;
    notifyListeners();
    try {
      final id = await _dao.insert(inventory);
      if (id <= 0) return false;

      final newInv = inventory.copyWith(id: id);
      _inventories.insert(0, newInv);

      // 1. Обновляем фактический уровень топлива в агрегате
      await _genDao.updateFuel(inventory.generatorId, inventory.actualFuel);

      // 2. Записываем событие в аналитику
      await _eventDao.insert(AnalyticsEventModel(
        type: 'inventory',
        date: inventory.date,
        description: 'Инвентаризация: ${inventory.difference} л',
        relatedId: inventory.generatorId,
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

  // 🆕 ДОБАВЛЕНО: Метод для очистки истории инвентаризации (сброс оборота агрегатов при калибровке)
  Future<void> clearInventories() async {
    await _dao.deleteAll(); // Удаляем все записи из базы данных
    _inventories = [];      // Очищаем список в памяти
    notifyListeners();      // Уведомляем интерфейс об изменениях
  }
}