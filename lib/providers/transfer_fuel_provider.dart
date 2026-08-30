import 'package:flutter/foundation.dart';
import '../models/analytics_event_model.dart';
import '../services/generator_dao.dart';
import '../services/analytics_event_dao.dart';

class TransferFuelProvider extends ChangeNotifier {
  final GeneratorDao _genDao = GeneratorDao();
  final AnalyticsEventDao _eventDao = AnalyticsEventDao();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  /// Выполняет перелив топлива и фиксирует событие в журнале
  Future<bool> transferFuel({
    required int sourceId,
    required int destId,
    required double amount,
    required DateTime date,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final generators = await _genDao.getAll();
      final source = generators.firstWhere((g) => g.id == sourceId);
      final dest = generators.firstWhere((g) => g.id == destId);

      // Жесткое округление до сотых, как во всем приложении
      final newSourceFuel = double.parse((source.currentFuel - amount).toStringAsFixed(2));
      final newDestFuel = double.parse((dest.currentFuel + amount).toStringAsFixed(2));

      // 1. Обновляем уровни топлива в БД
      final success1 = await _genDao.updateFuel(sourceId, newSourceFuel);
      final success2 = await _genDao.updateFuel(destId, newDestFuel);

      if (success1 > 0 && success2 > 0) {
        // 2. 🆕 ИНТЕГРАЦИЯ: Записываем событие перелива в Журнал событий (Задача 4)
        await _eventDao.insert(AnalyticsEventModel(
          type: 'transfer',
          date: date,
          description: 'Перелив: ${amount.toStringAsFixed(2)} л из "${source.name}" в "${dest.name}"',
          relatedId: sourceId, 
        ));

        _isLoading = false;
        notifyListeners();
        return true;
      }

      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('Ошибка при переливе: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}