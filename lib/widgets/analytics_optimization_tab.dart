import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/generator_provider.dart';
import '../providers/optimization_provider.dart';
import '../providers/optimization_settings_provider.dart';
import '../providers/inventory_provider.dart';
import '../widgets/analytics_reset_button.dart';
import 'refuel_stats_card.dart';

class AnalyticsOptimizationTab extends StatelessWidget {
  // 🆕 ДОБАВЛЕНО: параметр для фильтрации по автомобилю
  final int? selectedCarId;

  const AnalyticsOptimizationTab({
    super.key,
    this.selectedCarId,
  });

  List<T> _filterLastDays<T>(List<T> items, DateTime Function(T) getDate, int days) {
    final threshold = DateTime.now().subtract(Duration(days: days));
    return items.where((item) => getDate(item).isAfter(threshold)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final allGenerators = context.watch<GeneratorProvider>().generators;
    final allOptimizations = context.watch<OptimizationProvider>().optimizations;
    final allInventories = context.watch<InventoryProvider>().inventories;
    final settings = context.watch<OptimizationSettingsProvider>();

    // 🆕 ШАГ 1: Фильтруем агрегаты по выбранному автомобилю
    final filteredGenerators = selectedCarId == null
        ? allGenerators
        : allGenerators.where((g) => g.carId == selectedCarId).toList();

    // 🆕 ШАГ 2: Создаем Set ID разрешенных агрегатов для быстрого поиска O(1)
    final allowedGenIds = filteredGenerators.map((g) => g.id).toSet();

    // 🆕 ШАГ 3: Фильтруем события, оставляя только те, что относятся к разрешенным агрегатам
    final filteredInventories = allInventories.where((i) => allowedGenIds.contains(i.generatorId)).toList();
    final filteredOptimizations = allOptimizations.where((o) => allowedGenIds.contains(o.generatorId)).toList();

    // 🆕 ШАГ 4: Расчеты теперь идут ТОЛЬКО по отфильтрованным данным
    final weeklyConsumption = _filterLastDays(filteredInventories, (i) => i.date, 7)
        .where((i) => i.difference < 0).fold(0.0, (sum, i) => sum + i.difference.abs());
    final weeklyOptimized = _filterLastDays(filteredOptimizations, (o) => o.date, 7)
        .fold(0.0, (sum, o) => sum + o.fuelAmount);
    final weeklyAllowed = weeklyConsumption * (settings.weekLimit / 100);
    final weeklyRemaining = (weeklyAllowed - weeklyOptimized).clamp(0.0, weeklyAllowed);
    final isWeekExceeded = weeklyOptimized > weeklyAllowed;

    final monthlyConsumption = _filterLastDays(filteredInventories, (i) => i.date, 30)
        .where((i) => i.difference < 0).fold(0.0, (sum, i) => sum + i.difference.abs());
    final monthlyOptimized = _filterLastDays(filteredOptimizations, (o) => o.date, 30)
        .fold(0.0, (sum, o) => sum + o.fuelAmount);
    final monthlyAllowed = monthlyConsumption * (settings.monthLimit / 100);
    final monthlyRemaining = (monthlyAllowed - monthlyOptimized).clamp(0.0, monthlyAllowed);
    final isMonthExceeded = monthlyOptimized > monthlyAllowed;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🆕 Передаем selectedCarId вниз, чтобы архитектура была согласованной
          RefuelStatsCard(selectedCarId: selectedCarId),
          
          _buildCard('Недельная оптимизация', weeklyConsumption, weeklyOptimized, weeklyAllowed, weeklyRemaining, weeklyAllowed > 0 ? (weeklyOptimized / weeklyAllowed).clamp(0.0, 1.0) : 0.0, isWeekExceeded, settings.weekLimit),
          const SizedBox(height: 16),
          _buildCard('Месячная оптимизация', monthlyConsumption, monthlyOptimized, monthlyAllowed, monthlyRemaining, monthlyAllowed > 0 ? (monthlyOptimized / monthlyAllowed).clamp(0.0, 1.0) : 0.0, isMonthExceeded, settings.monthLimit),
          const SizedBox(height: 24),
          const Text('Сводка по агрегатам', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          
          // 🆕 ИЗМЕНЕНО: Отрисовываем только отфильтрованные агрегаты
          if (filteredGenerators.isEmpty)
            const Center(child: Text('Нет данных об агрегатах для выбранного фильтра'))
          else
            ...filteredGenerators.map((gen) {
              // 🆕 ИЗМЕНЕНО: Считаем оптимизации только из отфильтрованного списка
              final genOpt = filteredOptimizations.where((o) => o.generatorId == gen.id).fold(0.0, (sum, o) => sum + o.fuelAmount);
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(gen.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Остаток: ${gen.currentFuel} / ${gen.capacity} л'),
                  trailing: Text('${genOpt.toStringAsFixed(1)} л', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                ),
              );
            }),
          const SizedBox(height: 24),
          const AnalyticsResetButton(),
        ],
      ),
    );
  }

  Widget _buildCard(String title, double consumption, double optimized, double allowed, double remaining, double progress, bool isExceeded, double limitPercent) {
    return Card(
      color: isExceeded ? Colors.red.shade50 : Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(isExceeded ? Icons.warning_amber_rounded : Icons.check_circle, color: isExceeded ? Colors.red : Colors.green, size: 28),
                const SizedBox(width: 8),
                Expanded(child: Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isExceeded ? Colors.red : Colors.green))),
              ],
            ),
            const SizedBox(height: 16),
            
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    'Факт. расход: ${consumption.toStringAsFixed(1)} л',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                    softWrap: true,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Лимит ($limitPercent%): ${allowed.toStringAsFixed(1)} л',
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                    textAlign: TextAlign.end,
                    softWrap: true,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            LinearProgressIndicator(value: progress, backgroundColor: Colors.grey.shade300, valueColor: AlwaysStoppedAnimation<Color>(isExceeded ? Colors.red : Colors.green), minHeight: 10),
            const SizedBox(height: 8),
            
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    'Оптимизировано: ${optimized.toStringAsFixed(1)} л',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    softWrap: true,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Доступно: ${remaining.toStringAsFixed(1)} л',
                    style: TextStyle(fontWeight: FontWeight.bold, color: isExceeded ? Colors.red : Colors.green, fontSize: 13),
                    textAlign: TextAlign.end,
                    softWrap: true,
                  ),
                ),
              ],
            ),
            
            if (isExceeded) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.red.shade100, borderRadius: BorderRadius.circular(8)),
                child: const Text(
                  'Совет: Объем оптимизации превышает допустимый лимит от фактического расхода.', 
                  style: TextStyle(fontSize: 13, color: Colors.red, fontWeight: FontWeight.w500),
                  softWrap: true,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}