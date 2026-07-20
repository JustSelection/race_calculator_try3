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

          final generators = genProv.generators;
          final cars = context.read<CarProvider>().cars;
          final isWeekExceeded = optProv.weekSum > settingsProv.weekLimit;
          final isMonthExceeded = optProv.monthSum > settingsProv.monthLimit;

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
              Expanded(
                child: generators.isEmpty
                    ? const Center(child: Text('Нет агрегатов. Добавьте первый.'))
                    : ListView.builder(
                        itemCount: generators.length,
                        itemBuilder: (context, index) {
                          final gen = generators[index];
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
                                'Авто: ${car?.brand ?? "Не привязан"}',
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blue),
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
        content: const Text('Это действие также удалит всю историю оптимизаций этого агрегата.'),
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