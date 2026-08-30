import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/analytics_event_provider.dart';
import '../models/analytics_event_model.dart';

class RefuelStatsCard extends StatelessWidget {
  const RefuelStatsCard({super.key});

  @override
  Widget build(BuildContext context) {
    // 🆕 ИЗМЕНЕНО: Берем данные из журнала событий (AnalyticsEventProvider), а не из RefuelProvider
    final allEvents = context.watch<AnalyticsEventProvider>().events;
    final now = DateTime.now();

    // Фильтруем только события типа 'refuel'
    final refuelEvents = allEvents.where((e) => e.type == 'refuel').toList();

    // Фильтрация по периодам
    final todayRefuels = refuelEvents.where((e) => 
      e.date.year == now.year && e.date.month == now.month && e.date.day == now.day
    ).toList();

    final weekRefuels = refuelEvents.where((e) {
      final diff = now.difference(e.date).inDays;
      return diff >= 0 && diff < 7;
    }).toList();

    final monthRefuels = refuelEvents.where((e) {
      final diff = now.difference(e.date).inDays;
      return diff >= 0 && diff < 30;
    }).toList();

    //  ИЗМЕНЕНО: Извлекаем количество топлива из описания события
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
            const Row(
              children: [
                Icon(Icons.local_gas_station, color: Colors.blue, size: 24),
                SizedBox(width: 8),
                Text('Заправлено по чеку', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue)),
              ],
            ),
            const SizedBox(height: 12),
            _buildStatRow('За сегодня:', todayTotal, todayRefuels.length),
            const SizedBox(height: 8),
            _buildStatRow('За неделю:', weekTotal, weekRefuels.length),
            const SizedBox(height: 8),
            _buildStatRow('За месяц:', monthTotal, monthRefuels.length),
          ],
        ),
      ),
    );
  }

  // 🆕 ИЗМЕНЕНО: Метод для извлечения количества топлива из описания события
  double _extractFuelAmount(List<AnalyticsEventModel> events) {
    double total = 0.0;
    for (final event in events) {
      // Ищем число в описании вида "Заправка: по чеку заправлено 123.2 л"
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