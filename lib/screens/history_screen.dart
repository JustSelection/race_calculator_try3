import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/analytics_event_provider.dart';
import '../widgets/event_details_dialog.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String? _filterType;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AnalyticsEventProvider>().loadEvents();
    });
  }

  String _getTypeName(String type) {
    switch (type) {
      case 'refuel': return 'Заправка';
      case 'inventory': return 'Работа агрегата';
      case 'transfer': return 'Перелив';
      case 'calibration': return 'Инвентаризация';
      default: return type;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'refuel': return Icons.local_gas_station;
      case 'inventory': return Icons.local_fire_department;
      case 'transfer': return Icons.swap_horiz;
      case 'calibration': return Icons.inventory;
      default: return Icons.event;
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'refuel': return Colors.green;
      case 'inventory': return Colors.orange;
      case 'transfer': return Colors.blue;
      case 'calibration': return Colors.purple;
      default: return Colors.grey;
    }
  }

  Future<void> _clearAllEvents() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Очистить журнал?'),
        content: const Text('Вы уверены, что хотите удалить ВСЕ события из журнала? Это действие необратимо.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Очистить', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await context.read<AnalyticsEventProvider>().clearAllEvents(); 
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Журнал событий полностью очищен')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final events = context.watch<AnalyticsEventProvider>().events;
    
    final nonOptimizationEvents = events.where((e) => e.type != 'optimization').toList();
    final filtered = _filterType == null 
        ? nonOptimizationEvents 
        : nonOptimizationEvents.where((e) => e.type == _filterType).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Журнал событий'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever, color: Colors.red),
            tooltip: 'Очистить весь журнал',
            onPressed: _clearAllEvents,
          ),
          PopupMenuButton<String?>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) => setState(() => _filterType = value),
            itemBuilder: (context) => [
              const PopupMenuItem(value: null, child: Text('Все события')),
              const PopupMenuItem(value: 'refuel', child: Text('Заправки')),
              const PopupMenuItem(value: 'inventory', child: Text('Работа агрегата')),
              const PopupMenuItem(value: 'transfer', child: Text('Переливы')),
              const PopupMenuItem(value: 'calibration', child: Text('Инвентаризации')),
            ],
          ),
        ],
      ),
      body: filtered.isEmpty
          ? const Center(child: Text('Нет событий'))
          : ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (_, index) {
                final event = filtered[index];
                final dateStr = DateFormat('dd.MM.yyyy HH:mm').format(event.date);
                
                return Dismissible(
                  key: Key(event.id.toString()),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20.0),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  confirmDismiss: (direction) async {
                    return await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Удалить событие?'),
                        content: const Text('Вы уверены, что хотите удалить эту запись?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
                          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Удалить', style: TextStyle(color: Colors.red))),
                        ],
                      ),
                    );
                  },
                  onDismissed: (direction) async {
                    final provider = context.read<AnalyticsEventProvider>();
                    
                    // 🆕 ИСПРАВЛЕНО: Убрали переменную success и SnackBar, 
                    // чтобы полностью исключить предупреждения use_build_context_synchronously 
                    // в сложных вложенных замыканиях. Список обновится автоматически.
                    await provider.deleteEvent(event.id!);
                    if (!mounted) return;
                    
                    await provider.loadEvents(type: _filterType);
                  },
                  child: Card(
                    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: ListTile(
                      onTap: () => showDialog(
                        context: context,
                        builder: (ctx) => EventDetailsDialog(event: event),
                      ),
                      leading: CircleAvatar(
                        backgroundColor: _getTypeColor(event.type),
                        child: Icon(_getTypeIcon(event.type), color: Colors.white),
                      ),
                      title: Text(_getTypeName(event.type)),
                      subtitle: Text('${event.description}\n$dateStr'),
                    ),
                  ),
                );
              },
            ),
    );
  }
}