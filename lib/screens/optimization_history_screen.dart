import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/optimization_model.dart';
import '../providers/generator_provider.dart';
import '../providers/optimization_provider.dart';
import '../widgets/optimization_history_list_item.dart';

enum HistoryFilter { all, week, month }

class OptimizationHistoryScreen extends StatefulWidget {
  const OptimizationHistoryScreen({super.key});

  @override
  State<OptimizationHistoryScreen> createState() => _OptimizationHistoryScreenState();
}

class _OptimizationHistoryScreenState extends State<OptimizationHistoryScreen> {
  HistoryFilter _filter = HistoryFilter.all;
  bool _isAscending = false; // false = новые сверху (по умолчанию)

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OptimizationProvider>().loadOptimizations();
    });
  }

  List<OptimizationModel> _applyFilterAndSort(List<OptimizationModel> items) {
    final now = DateTime.now();
    List<OptimizationModel> filtered;
    
    switch (_filter) {
      case HistoryFilter.week:
        final weekAgo = now.subtract(const Duration(days: 7));
        filtered = items.where((i) => i.date.isAfter(weekAgo)).toList();
        break;
      case HistoryFilter.month:
        final monthAgo = now.subtract(const Duration(days: 30));
        filtered = items.where((i) => i.date.isAfter(monthAgo)).toList();
        break;
      default:
        filtered = items;
    }

    filtered.sort((a, b) => _isAscending 
        ? a.date.compareTo(b.date) 
        : b.date.compareTo(a.date));
        
    return filtered;
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
    final filtered = _applyFilterAndSort(optProv.optimizations);

    return Scaffold(
      appBar: AppBar(
        title: const Text('История оптимизаций'),
        actions: [
          IconButton(
            icon: Icon(_isAscending ? Icons.arrow_upward : Icons.arrow_downward),
            tooltip: _isAscending ? 'Сначала старые' : 'Сначала новые',
            onPressed: () => setState(() => _isAscending = !_isAscending),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: HistoryFilter.values.map((f) {
                final label = f == HistoryFilter.all ? 'Все' : f == HistoryFilter.week ? 'Неделя' : 'Месяц';
                return FilterChip(
                  label: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
                  selected: _filter == f,
                  showCheckmark: false,
                  selectedColor: Colors.blue.shade100,
                  checkmarkColor: Colors.blue.shade700,
                  side: BorderSide(color: _filter == f ? Colors.blue.shade700 : Colors.grey.shade300),
                  onSelected: (sel) {
                    if (sel) setState(() => _filter = f);
                  },
                );
              }).toList(),
            ),
          ),
          const Divider(height: 1),
          
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox_outlined, size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text('Нет записей за выбранный период', style: TextStyle(color: Colors.grey.shade600)),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (ctx, i) {
                      final opt = filtered[i];
                      final genName = _getGeneratorName(genProv.generators, opt.generatorId);

                      return OptimizationHistoryListItem(
                        opt: opt,
                        genName: genName,
                        generators: genProv.generators,
                        onDelete: () => _confirmDelete(context, optProv, opt.id!),
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
        content: const Text('Запись будет удалена из истории оптимизаций. Топливо в агрегат НЕ вернется.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Удалить', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      await provider.deleteOptimization(id);
    }
  }
}