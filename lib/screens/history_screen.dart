import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/analytics_event_provider.dart';
import '../models/analytics_event_model.dart';

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

  void _showEventDetails(BuildContext context, AnalyticsEventModel event) {
    final dateStr = DateFormat('dd.MM.yyyy HH:mm').format(event.date);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_getTypeName(event.type)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Дата', dateStr),
            const SizedBox(height: 12),
            _buildDetailRow('Описание', event.description),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Закрыть')),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 100, child: Text('$label:', style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500))),
        Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold))),
      ],
    );
  }

  Future<void> _clearAllEvents() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Очистить журнал?'),
        content: const Text('Вы уверены, что хотите удалить ВСЕ события из журнала? Это действие необратимо и повлияет на статистику.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Очистить', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final provider = context.read<AnalyticsEventProvider>();
      await provider.clearAllEvents(); 
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Журнал событий полностью очищен')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final events = context.watch<AnalyticsEventProvider>().events;
    
    //  ИЗМЕНЕНО: Исключаем события типа 'optimization' из журнала событий
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
              itemBuilder: (context, index) {
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
                        content: const Text('Вы уверены, что хотите удалить эту запись из журнала?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
                          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Удалить', style: TextStyle(color: Colors.red))),
                        ],
                      ),
                    );
                  },
                  onDismissed: (direction) async {
                    final provider = context.read<AnalyticsEventProvider>();
                    final success = await provider.deleteEvent(event.id!);
                    
                    if (!mounted) return;

                    if (success) {
                      await provider.loadEvents(type: _filterType);
                      if (!mounted) return;
                      
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        const SnackBar(content: Text('Событие удалено')),
                      );
                    }
                  },
                  child: Card(
                    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: ListTile(
                      onTap: () => _showEventDetails(context, event),
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