import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/optimization_model.dart';
import '../providers/generator_provider.dart';
import '../providers/optimization_provider.dart';

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