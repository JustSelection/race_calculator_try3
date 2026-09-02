import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/refuel_provider.dart';
import '../providers/optimization_provider.dart';
import '../providers/optimization_settings_provider.dart';
import '../providers/inventory_provider.dart';
import '../providers/car_provider.dart';
import '../widgets/analytics_optimization_tab.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  int? _selectedCarId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RefuelProvider>().loadRefuels();
      context.read<OptimizationProvider>().loadOptimizations();
      context.read<OptimizationSettingsProvider>().loadSettings();
      context.read<InventoryProvider>().loadInventories();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cars = context.watch<CarProvider>().cars;

    // 🆕 ЗАЩИТА: гарантируем, что initialValue всегда есть в списке items.
    // Если _selectedCarId вдруг окажется не в списке cars, сбрасываем его в null,
    // чтобы избежать фатальной ошибки "There should be exactly one item with [DropdownButton]'s value".
    final safeInitialValue = _selectedCarId == null || cars.any((c) => c.id == _selectedCarId)
        ? _selectedCarId
        : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Аналитика агрегатов'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: DropdownButtonFormField<int?>(
              // 🆕 ИСПРАВЛЕНО: используем initialValue вместо value (value is deprecated after v3.33.0)
              initialValue: safeInitialValue,
              decoration: const InputDecoration(
                labelText: 'Автомобиль',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: [
                const DropdownMenuItem<int?>(
                  value: null, 
                  child: Text('Все автомобили'),
                ),
                ...cars.map((car) => DropdownMenuItem<int?>(
                      value: car.id,
                      child: Text('${car.brand} (${car.licensePlate})'),
                    )),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedCarId = value;
                });
              },
            ),
          ),
          
          Expanded(
            child: AnalyticsOptimizationTab(
              selectedCarId: _selectedCarId,
            ),
          ),
        ],
      ),
    );
  }
}