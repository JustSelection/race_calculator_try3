import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/car_model.dart';
import '../providers/car_provider.dart';
import '../providers/generator_provider.dart';
import '../providers/optimization_provider.dart';
import '../providers/optimization_settings_provider.dart';
import 'generator_edit_screen.dart';
import 'transfer_fuel_screen.dart';
import 'optimization_screen.dart';
import 'optimization_history_screen.dart';
import 'optimization_settings_screen.dart';

class GeneratorsListScreen extends StatefulWidget {
  const GeneratorsListScreen({super.key});

  @override
  State<GeneratorsListScreen> createState() => _GeneratorsListScreenState();
}

class _GeneratorsListScreenState extends State<GeneratorsListScreen> {
  int? _selectedCarId; // null = все агрегаты

  double _round(double value) => double.parse(value.toStringAsFixed(2));

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GeneratorProvider>().loadGenerators();
      context.read<OptimizationProvider>().loadAnalytics();
      context.read<OptimizationSettingsProvider>().loadSettings();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cars = context.watch<CarProvider>().cars;

    // 🛡️ ЗАЩИТА: Если выбранный автомобиль был удален, сбрасываем фильтр на "Все"
    if (_selectedCarId != null && _selectedCarId != -1) {
      final isValid = cars.any((c) => c.id == _selectedCarId);
      if (!isValid) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => _selectedCarId = null);
        });
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Агрегаты'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              switch (value) {
                case 'transfer':
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const TransferFuelScreen()));
                  break;
                case 'optimize':
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const OptimizationScreen()));
                  break;
                case 'history':
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const OptimizationHistoryScreen()));
                  break;
                case 'settings':
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const OptimizationSettingsScreen()));
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'transfer', 
                child: Row(children: [Icon(Icons.swap_horiz, size: 20), SizedBox(width: 8), Text('Перелив топлива')]),
              ),
              const PopupMenuItem(
                value: 'optimize', 
                child: Row(children: [Icon(Icons.delete_outline, size: 20), SizedBox(width: 8), Text('Списание (Оптимизация)')]),
              ),
              const PopupMenuItem(
                value: 'history', 
                child: Row(children: [Icon(Icons.history, size: 20), SizedBox(width: 8), Text('История списаний')]),
              ),
              const PopupMenuItem(
                value: 'settings', 
                child: Row(children: [Icon(Icons.settings, size: 20), SizedBox(width: 8), Text('Настройки лимитов')]),
              ),
            ],
          ),
        ],
      ),
      body: Consumer3<GeneratorProvider, OptimizationProvider, OptimizationSettingsProvider>(
        builder: (context, genProv, optProv, settingsProv, _) {
          if (genProv.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final allGenerators = genProv.generators;
          final isWeekExceeded = optProv.weekSum > settingsProv.weekLimit;
          final isMonthExceeded = optProv.monthSum > settingsProv.monthLimit;

          // Фильтрация по автомобилю
          final filteredGenerators = _selectedCarId == null || _selectedCarId == -1
              ? (_selectedCarId == -1 
                  ? allGenerators.where((g) => g.carId == null).toList() 
                  : allGenerators)
              : allGenerators.where((g) => g.carId == _selectedCarId).toList();

          // Общее топливо для отфильтрованных агрегатов
          final totalFuel = _round(filteredGenerators.fold(0.0, (sum, g) => sum + g.currentFuel));

          return Column(
            children: [
              if (isWeekExceeded || isMonthExceeded)
                Container(
                  width: double.infinity,
                  color: Colors.orange.shade100,
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    '⚠️ Превышен лимит оптимизации: '
                    '${isWeekExceeded ? "недельный " : ""}'
                    '${isMonthExceeded ? "месячный" : ""}',
                    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
              // Фильтр по автомобилю
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: DropdownButtonFormField<int?>(
                  initialValue: _selectedCarId,
                  decoration: const InputDecoration(
                    labelText: 'Фильтр по автомобилю',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: [
                    const DropdownMenuItem<int?>(value: null, child: Text('Все агрегаты')),
                    const DropdownMenuItem<int?>(value: -1, child: Text('Не привязанные')),
                    ...cars.map((car) => DropdownMenuItem<int?>(
                          value: car.id,
                          child: Text('${car.brand} (${car.licensePlate})'),
                        )),
                  ],
                  onChanged: (value) => setState(() => _selectedCarId = value),
                ),
              ),
              // Общее топливо
              Container(
                width: double.infinity,
                color: Colors.blue.shade50,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: Text(
                  'Общее топливо: $totalFuel л',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                child: filteredGenerators.isEmpty
                    ? const Center(child: Text('Нет агрегатов для выбранного фильтра.'))
                    : ListView.builder(
                        itemCount: filteredGenerators.length,
                        itemBuilder: (context, index) {
                          final gen = filteredGenerators[index];
                          final car = gen.carId != null
                              ? cars.firstWhere(
                                  (c) => c.id == gen.carId,
                                  orElse: () => Car(
                                    id: -1, brand: 'Не привязан', licensePlate: '',
                                    fuelConsumption: 0, currentMileage: 0,
                                    fuelInTank: 0, tankCapacity: 0,
                                  ),
                                )
                              : null;

                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: ListTile(
                              title: Text(gen.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(
                                'Топливо: ${gen.currentFuel} / ${gen.capacity} л\n'
                                'Авто: ${car != null ? "${car.brand} (${car.licensePlate})" : "Не привязан"}',
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.oil_barrel, color: Colors.blue),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => GeneratorEditScreen(generator: gen),
                                        ),
                                      );
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _confirmDelete(context, genProv, gen.id!),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const GeneratorEditScreen()),
          );
        },
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
    if (confirm == true && context.mounted) {
      await provider.deleteGenerator(id);
    }
  }
}