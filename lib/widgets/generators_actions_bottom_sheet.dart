import 'package:flutter/material.dart';
import '../screens/refuel_screen.dart';
import '../screens/transfer_fuel_screen.dart';
import '../screens/optimization_screen.dart';
import '../screens/global_calibration_screen.dart';

/// Показывает нижнюю шторку с доступными действиями для агрегатов
void showGeneratorsActionsBottomSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Выберите действие',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.local_gas_station, color: Colors.blue),
            title: const Text('Заправка'),
            onTap: () {
              Navigator.pop(ctx);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const RefuelScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.swap_horiz, color: Colors.blue),
            title: const Text('Перелив топлива'),
            onTap: () {
              Navigator.pop(ctx);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const TransferFuelScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.trending_down, color: Colors.blue),
            title: const Text('Оптимизация'),
            onTap: () {
              Navigator.pop(ctx);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const OptimizationScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.inventory, color: Colors.blue),
            title: const Text('Инвентаризация'),
            onTap: () {
              Navigator.pop(ctx);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const GlobalCalibrationScreen()));
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.close, color: Colors.red),
            title: const Text('Отмена', style: TextStyle(color: Colors.red)),
            onTap: () => Navigator.pop(ctx),
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}