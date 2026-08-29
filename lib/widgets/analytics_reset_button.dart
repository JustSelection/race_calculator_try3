import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/optimization_provider.dart';
import '../providers/inventory_provider.dart';
import '../providers/refuel_provider.dart'; // 🆕 ДОБАВЛЕНО

class AnalyticsResetButton extends StatelessWidget {
  const AnalyticsResetButton({super.key});

  void _confirmReset(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Сбросить аналитику?'),
        content: const Text(
          'Это действие удалит всю историю заправок, оптимизаций и инвентаризаций (работы агрегатов). '
          'Аналитика автомобилей (рейсы) не будет затронута. Продолжить?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              
              final optProv = context.read<OptimizationProvider>();
              final invProv = context.read<InventoryProvider>();
              final refProv = context.read<RefuelProvider>(); // 🆕 Читаем провайдер заправок
              
              await optProv.clearOptimizations();
              await invProv.clearInventories();
              await refProv.clearRefuels(); // 🆕 Сброс заправок для полного обнуления оборота
              
              if (!context.mounted) return;
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Аналитика агрегатов успешно сброшена')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Сбросить', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _confirmReset(context),
        icon: const Icon(Icons.delete_forever, size: 20),
        label: const Text('Сбросить аналитику агрегатов'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red.shade50,
          foregroundColor: Colors.red,
          side: BorderSide(color: Colors.red.shade200),
        ),
      ),
    );
  }
}