import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/analytics_event_provider.dart';
import '../providers/generator_provider.dart'; // 🆕 ДОБАВЛЕНО
import '../models/analytics_event_model.dart';

class RefuelStatsCard extends StatelessWidget {
  final int? selectedCarId;

  const RefuelStatsCard({
    super.key,
    this.selectedCarId,
  });

  @override
  Widget build(BuildContext context) {
    final allEvents = context.watch<AnalyticsEventProvider>().events;
    final generators = context.watch<GeneratorProvider>().generators; // 🆕 Получаем агрегаты
    final now = DateTime.now();

    // 1. Берем все события заправки
    final allRefuelEvents = allEvents.where((e) => e.type == 'refuel').toList();

    // 2. Определяем разрешенные ID агрегатов
    // Если selectedCarId == null, берем все агрегаты. Иначе только агрегаты выбранного авто.
    final allowedGenIds = selectedCarId == null
        ? generators.map((g) => g.id).toSet()
        : generators.where((g) => g.carId == selectedCarId).map((g) => g.id).toSet();

    // 3. Фильтруем события: оставляем только те, где relatedId (теперь это generatorId) есть в разрешенных
    final filteredRefuelEvents = allRefuelEvents
        .where((e) => allowedGenIds.contains(e.relatedId))
        .toList();

    // 4. Фильтрация по периодам уже на основе отфильтрованных событий
    final todayRefuels = filteredRefuelEvents.where((e) => 
      e.date.year == now.year && e.date.month == now.month && e.date.day == now.day
    ).toList();

    final weekRefuels = filteredRefuelEvents.where((e) {
      final diff = now.difference(e.date).inDays;
      return diff >= 0 && diff < 7;
    }).toList();

    final monthRefuels = filteredRefuelEvents.where((e) {
      final diff = now.difference(e.date).inDays;
      return diff >= 0 && diff < 30;
    }).toList();

    final todayTotal = _extractFuelAmount(todayRefuels);
    final weekTotal = _extractFuelAmount(weekRefuels);
    final monthTotal = _extractFuelAmount(monthRefuels);

    return Card(
      color: Colors.blue.shade50,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.local_gas_station, color: Colors.blue, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    selectedCarId == null 
                        ? 'Заправлено по чеку (Все автомобили)' 
                        : 'Заправлено по чеку (Выбранный автомобиль)',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue),
                    softWrap: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildStatRow('За сегодня:', todayTotal, todayRefuels.length),
            const SizedBox(height: 8),
            _buildStatRow('За неделю:', weekTotal, weekRefuels.length),
            const SizedBox(height: 8),
            _buildStatRow('За месяц:', monthTotal, monthRefuels.length),
            
            // 🆕 Убрано оранжевое предупреждение, так как фильтрация теперь работает!
          ],
        ),
      ),
    );
  }

  double _extractFuelAmount(List<AnalyticsEventModel> events) {
    double total = 0.0;
    for (final event in events) {
      // Регулярное выражение ищет число перед "л" в описании вида "Заправка Имя: по чеку заправлено 12.5 л"
      final match = RegExp(r'(\d+\.?\d*)\s*л').firstMatch(event.description);
      if (match != null) {
        final value = double.tryParse(match.group(1)!);
        if (value != null) {
          total += value;
        }
      }
    }
    return total;
  }

  Widget _buildStatRow(String label, double total, int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.black87)),
        Row(
          children: [
            Text(
              '${total.toStringAsFixed(2)} л',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blue),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text('$count', style: const TextStyle(fontSize: 12, color: Colors.blue)),
            ),
          ],
        ),
      ],
    );
  }
}