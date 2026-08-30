import 'package:flutter/material.dart';
import '../screens/optimization_history_screen.dart';
import '../screens/optimization_settings_screen.dart';
import '../screens/history_screen.dart';

class GeneratorMenuBuilder extends StatelessWidget {
  const GeneratorMenuBuilder({super.key});

  void _onMenuSelected(BuildContext context, String value) {
    switch (value) {
      case 'global_history':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen()));
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
          value: 'global_history',
          child: Row(children: [Icon(Icons.list_alt, size: 20), SizedBox(width: 8), Text('Журнал событий')]),
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