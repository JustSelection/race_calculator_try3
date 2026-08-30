import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/car_provider.dart';
import '../providers/generator_provider.dart';
import '../providers/optimization_provider.dart';
import '../providers/optimization_settings_provider.dart';
import '../providers/inventory_provider.dart';
import 'generator_edit_screen.dart';
import '../widgets/generator_list_tile.dart';
import '../widgets/generator_menu_builder.dart';
import '../widgets/generators_actions_bottom_sheet.dart';
import 'analytics_screen.dart';

class GeneratorsListScreen extends StatefulWidget {
  const GeneratorsListScreen({super.key});

  @override
  State<GeneratorsListScreen> createState() => _GeneratorsListScreenState();
}

class _GeneratorsListScreenState extends State<GeneratorsListScreen> {
  int? _selectedCarId;

  double _round(double value) => double.parse(value.toStringAsFixed(2));

  List<T> _filterLastDays<T>(List<T> items, DateTime Function(T) getDate, int days) {
    final threshold = DateTime.now().subtract(Duration(days: days));
    return items.where((item) => getDate(item).isAfter(threshold)).toList();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GeneratorProvider>().loadGenerators();
      context.read<OptimizationProvider>().loadAnalytics();
      context.read<OptimizationSettingsProvider>().loadSettings();
      context.read<InventoryProvider>().loadInventories();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cars = context.watch<CarProvider>().cars;
    final inventories = context.watch<InventoryProvider>().inventories;
    final optimizations = context.watch<OptimizationProvider>().optimizations;
    final settings = context.watch<OptimizationSettingsProvider>();

    if (_selectedCarId != null && _selectedCarId != -1) {
      final isValid = cars.any((c) => c.id == _selectedCarId);
      if (!isValid) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => _selectedCarId = null);
        });
      }
    }

    final weeklyConsumption = _filterLastDays(inventories, (i) => i.date, 7)
        .where((i) => i.difference < 0).fold(0.0, (sum, i) => sum + i.difference.abs());
    final weeklyOptimized = _filterLastDays(optimizations, (o) => o.date, 7).fold(0.0, (sum, o) => sum + o.fuelAmount);
    final isWeekExceeded = weeklyOptimized > (weeklyConsumption * (settings.weekLimit / 100));

    final monthlyConsumption = _filterLastDays(inventories, (i) => i.date, 30)
        .where((i) => i.difference < 0).fold(0.0, (sum, i) => sum + i.difference.abs());
    final monthlyOptimized = _filterLastDays(optimizations, (o) => o.date, 30).fold(0.0, (sum, o) => sum + o.fuelAmount);
    final isMonthExceeded = monthlyOptimized > (monthlyConsumption * (settings.monthLimit / 100));

    return Scaffold(
      appBar: AppBar(title: const Text('Агрегаты'), actions: const [GeneratorMenuBuilder()]),
      body: Consumer<GeneratorProvider>(
        builder: (context, genProv, _) {
          if (genProv.isLoading) return const Center(child: CircularProgressIndicator());

          final allGenerators = genProv.generators;
          final filteredGenerators = _selectedCarId == null || _selectedCarId == -1
              ? (_selectedCarId == -1 ? allGenerators.where((g) => g.carId == null).toList() : allGenerators)
              : allGenerators.where((g) => g.carId == _selectedCarId).toList();

          final totalFuel = _round(filteredGenerators.fold(0.0, (sum, g) => sum + g.currentFuel));

          return Column(
            children: [
              if (isWeekExceeded || isMonthExceeded)
                Container(
                  width: double.infinity, color: Colors.orange.shade100, padding: const EdgeInsets.all(8.0),
                  child: Text('⚠️ Превышен лимит: ${isWeekExceeded ? "недельный " : ""}${isMonthExceeded ? "месячный" : ""}', 
                    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                ),
              
              // 🆕 ОБНОВЛЕНО: Стильный бело-синий дизайн кнопок без серого цвета
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AnalyticsScreen())),
                        icon: const Icon(Icons.analytics), 
                        label: const Text('Аналитика'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue, 
                          foregroundColor: Colors.white, 
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => showGeneratorsActionsBottomSheet(context),
                        icon: const Icon(Icons.local_gas_station), 
                        label: const Text('Действия'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white, // Белый фон
                          foregroundColor: Colors.blue,  // Синий текст и иконка
                          side: const BorderSide(color: Colors.blue, width: 1.5), // Синяя окантовка
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(8.0),
                child: DropdownButtonFormField<int?>(
                  initialValue: _selectedCarId,
                  decoration: const InputDecoration(
                    labelText: 'Фильтр по автомобилю', 
                    border: OutlineInputBorder(), 
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)
                  ),
                  items: [
                    const DropdownMenuItem<int?>(value: null, child: Text('Все агрегаты')),
                    const DropdownMenuItem<int?>(value: -1, child: Text('Не привязанные')),
                    ...cars.map((car) => DropdownMenuItem<int?>(value: car.id, child: Text('${car.brand} (${car.licensePlate})'))),
                  ],
                  onChanged: (value) => setState(() => _selectedCarId = value),
                ),
              ),
              Container(
                width: double.infinity, color: Colors.blue.shade50, padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: Text('Общее топливо: $totalFuel л', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              ),
              Expanded(
                child: filteredGenerators.isEmpty
                    ? const Center(child: Text('Нет агрегатов для выбранного фильтра.'))
                    : ListView.builder(
                        itemCount: filteredGenerators.length,
                        itemBuilder: (context, index) {
                          final gen = filteredGenerators[index];
                          return GeneratorListTile(gen: gen, cars: cars, onDelete: () => _confirmDelete(context, genProv, gen.id!));
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GeneratorEditScreen())),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, GeneratorProvider provider, int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить агрегат?'),
        content: const Text('Вы уверены, что хотите удалить этот агрегат?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Удалить', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true && context.mounted) await provider.deleteGenerator(id);
  }
}