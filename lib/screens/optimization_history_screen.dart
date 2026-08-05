import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/optimization_model.dart';
import '../models/car_model.dart';
import '../providers/generator_provider.dart';
import '../providers/optimization_provider.dart';
import '../providers/car_provider.dart';

enum HistoryFilter { all, week, month }

class OptimizationHistoryScreen extends StatefulWidget {
  const OptimizationHistoryScreen({super.key});

  @override
  State<OptimizationHistoryScreen> createState() => _OptimizationHistoryScreenState();
}

class _OptimizationHistoryScreenState extends State<OptimizationHistoryScreen> {
  HistoryFilter _filter = HistoryFilter.all;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OptimizationProvider>().loadOptimizations();
    });
  }

  List<OptimizationModel> _applyFilter(List<OptimizationModel> items) {
    final now = DateTime.now();
    switch (_filter) {
      case HistoryFilter.week:
        final weekAgo = now.subtract(const Duration(days: 7));
        return items.where((i) => i.date.isAfter(weekAgo)).toList();
      case HistoryFilter.month:
        final monthAgo = now.subtract(const Duration(days: 30));
        return items.where((i) => i.date.isAfter(monthAgo)).toList();
      default:
        return items;
    }
  }

  String _getGeneratorName(List<dynamic> generators, int genId) {
    for (final g in generators) {
      if (g.id == genId) return g.name;
    }
    return 'Удаленный агрегат';
  }

  String _getCarInfo(List<Car> cars, int? carId) {
    if (carId == null) return 'Не привязан';
    final car = cars.firstWhere(
      (c) => c.id == carId,
      orElse: () => Car(
        id: -1, brand: 'Неизвестно', licensePlate: '',
        fuelConsumption: 0, currentMileage: 0, fuelInTank: 0, tankCapacity: 0,
      ),
    );
    return '${car.brand} (${car.licensePlate})';
  }

  @override
  Widget build(BuildContext context) {
    final optProv = context.watch<OptimizationProvider>();
    final genProv = context.watch<GeneratorProvider>();
    final filtered = _applyFilter(optProv.optimizations);

    return Scaffold(
      appBar: AppBar(title: const Text('История оптимизаций')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: HistoryFilter.values.map((f) {
                final label = f == HistoryFilter.all ? 'Все' : f == HistoryFilter.week ? 'Неделя' : 'Месяц';
                return ChoiceChip(
                  label: Text(label),
                  selected: _filter == f,
                  onSelected: (sel) {
                    if (sel) setState(() => _filter = f);
                  },
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? const Center(child: Text('Нет записей за выбранный период'))
                : ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (ctx, i) {
                      final opt = filtered[i];
                      final genName = _getGeneratorName(genProv.generators, opt.generatorId);
                      final dateStr = '${opt.date.day.toString().padLeft(2, '0')}.${opt.date.month.toString().padLeft(2, '0')}.${opt.date.year}';

                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: ListTile(
                          onTap: () => _showDetails(context, opt, genName, genProv.generators),
                          title: Text('$genName — ${opt.fuelAmount.toStringAsFixed(2)} л'),
                          subtitle: Text(
                            '$dateStr\n${opt.comment}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _confirmDelete(context, optProv, opt.id!),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showDetails(BuildContext context, OptimizationModel opt, String genName, List<dynamic> generators) {
    final dateStr =
        '${opt.date.day.toString().padLeft(2, '0')}.'
        '${opt.date.month.toString().padLeft(2, '0')}.'
        '${opt.date.year} '
        '${opt.date.hour.toString().padLeft(2, '0')}:'
        '${opt.date.minute.toString().padLeft(2, '0')}';

    // Получаем текущую привязку агрегата к автомобилю
    dynamic gen;
    try {
      gen = generators.firstWhere((g) => g.id == opt.generatorId);
    } catch (_) {
      gen = null;
    }
    final cars = context.read<CarProvider>().cars;
    final carInfo = gen != null ? _getCarInfo(cars, gen.carId) : 'Агрегат удалён';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20.0),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.75,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Сводка списания', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Divider(),
              _detailRow('Агрегат', genName),
              _detailRow('Автомобиль', carInfo),
              _detailRow('Дата', dateStr),
              _detailRow('Списано', '${opt.fuelAmount.toStringAsFixed(2)} л'),
              const SizedBox(height: 8),
              const Text('Комментарий:', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 4),
              Flexible(
                child: SingleChildScrollView(
                  child: Text(
                    opt.comment,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 110, child: Text('$label:', style: const TextStyle(color: Colors.grey))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, OptimizationProvider provider, int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить запись?'),
        content: const Text('Запись будет удалена из истории. Топливо в агрегат НЕ вернется.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Удалить', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      await provider.deleteOptimization(id);
    }
  }
}