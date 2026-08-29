import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/analytics_event_provider.dart';

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
      case 'inventory': return 'Работа агрегата'; // 🆕 ИЗМЕНЕНО
      case 'optimization': return 'Оптимизация';
      case 'transfer': return 'Перелив';
      case 'calibration': return 'Глобальная инвентаризация'; // 🆕 ИЗМЕНЕНО
      default: return type;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'refuel': return Icons.local_gas_station;
      case 'inventory': return Icons.local_fire_department; // 🆕 ИЗМЕНЕНО: огонек
      case 'optimization': return Icons.delete_outline;
      case 'transfer': return Icons.swap_horiz;
      case 'calibration': return Icons.inventory; // 🆕 ИЗМЕНЕНО: иконка инвентаря
      default: return Icons.event;
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'refuel': return Colors.green;
      case 'inventory': return Colors.orange; // 🆕 ИЗМЕНЕНО: оранжевый для огонька
      case 'optimization': return Colors.red;
      case 'transfer': return Colors.blue;
      case 'calibration': return Colors.purple;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final events = context.watch<AnalyticsEventProvider>().events;
    final filtered = _filterType == null 
        ? events 
        : events.where((e) => e.type == _filterType).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Журнал событий'),
        actions: [
          PopupMenuButton<String?>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) => setState(() => _filterType = value),
            itemBuilder: (context) => [
              const PopupMenuItem(value: null, child: Text('Все события')),
              const PopupMenuItem(value: 'refuel', child: Text('Заправки')),
              const PopupMenuItem(value: 'inventory', child: Text('Работа агрегата')), // 🆕 ИЗМЕНЕНО
              const PopupMenuItem(value: 'optimization', child: Text('Оптимизации')),
              const PopupMenuItem(value: 'transfer', child: Text('Переливы')),
              const PopupMenuItem(value: 'calibration', child: Text('Глобальная инвентаризация')), // 🆕 ИЗМЕНЕНО
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
                
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getTypeColor(event.type),
                      child: Icon(_getTypeIcon(event.type), color: Colors.white),
                    ),
                    title: Text(_getTypeName(event.type)),
                    subtitle: Text('${event.description}\n$dateStr'),
                  ),
                );
              },
            ),
    );
  }
}