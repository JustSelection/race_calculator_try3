import 'package:flutter/material.dart';
import '../screens/transfer_fuel_screen.dart';
import '../screens/optimization_screen.dart';
import '../screens/optimization_history_screen.dart';
import '../screens/optimization_settings_screen.dart';
import '../screens/refuel_screen.dart';
import '../screens/analytics_screen.dart';
import '../screens/history_screen.dart';
import '../screens/global_calibration_screen.dart';

class GeneratorMenuBuilder extends StatelessWidget {
  const GeneratorMenuBuilder({super.key});

  void _onMenuSelected(BuildContext context, String value) {
    switch (value) {
      case 'analytics':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const AnalyticsScreen()));
        break;
      case 'global_history':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen()));
        break;
      case 'inventory':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const GlobalCalibrationScreen()));
        break;
      case 'refuel':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const RefuelScreen()));
        break;
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
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      onSelected: (value) => _onMenuSelected(context, value),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'analytics',
          child: Row(children: [Icon(Icons.analytics, size: 20), SizedBox(width: 8), Text('Аналитика')]),
        ),
        const PopupMenuItem(
          value: 'global_history',
          child: Row(children: [Icon(Icons.list_alt, size: 20), SizedBox(width: 8), Text('Журнал событий')]),
        ),
        const PopupMenuItem(
          value: 'inventory',
          child: Row(children: [Icon(Icons.inventory, size: 20), SizedBox(width: 8), Text('Глобальная инвентаризация')]), // 🆕 Уточнено
        ),
        const PopupMenuItem(
          value: 'refuel',
          child: Row(children: [Icon(Icons.local_gas_station, size: 20), SizedBox(width: 8), Text('Заправка')]),
        ),
        const PopupMenuItem(
          value: 'transfer',
          child: Row(children: [Icon(Icons.swap_horiz, size: 20), SizedBox(width: 8), Text('Перелив топлива')]),
        ),
        const PopupMenuItem(
          value: 'optimize',
          // 🆕 ИЗМЕНЕНО: иконка мусорного бака заменена на понятную иконку оптимизации/снижения
          child: Row(children: [Icon(Icons.trending_down, size: 20), SizedBox(width: 8), Text('Оптимизация')]),
        ),
        const PopupMenuItem(
          value: 'history',
          child: Row(children: [Icon(Icons.history, size: 20), SizedBox(width: 8), Text('История оптимизаций')]),
        ),
        const PopupMenuItem(
          value: 'settings',
          child: Row(children: [Icon(Icons.settings, size: 20), SizedBox(width: 8), Text('Настройки лимитов')]),
        ),
      ],
    );
  }
}