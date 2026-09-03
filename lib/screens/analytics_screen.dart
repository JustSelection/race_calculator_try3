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
  bool _isDefaultSet = false; // 🆕 Флаг для установки автомобиля по умолчанию

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RefuelProvider>().loadRefuels();
      context.read<OptimizationProvider>().loadOptimizations();
      context.read<OptimizationSettingsProvider>().loadSettings();
      context.read<InventoryProvider>().loadInventories();
      
      // 🆕 ЗАДАЧА 3: Выбираем первый автомобиль из списка по умолчанию при загрузке
      if (!_isDefaultSet) {
        final cars = context.read<CarProvider>().cars;
        if (cars.isNotEmpty && mounted) {
          setState(() {
            _selectedCarId = cars.first.id;
            _isDefaultSet = true;
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cars = context.watch<CarProvider>().cars;

    // 🆕 Реактивная защита: если список машин обновился, а дефолтный еще не выбран
    if (!_isDefaultSet && cars.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_isDefaultSet) {
          setState(() {
            _selectedCarId = cars.first.id;
            _isDefaultSet = true;
          });
        }
      });
    }

    // 🆕 ЗАЩИТА: гарантируем, что initialValue всегда валиден и существует в списке
    final safeInitialValue = cars.any((c) => c.id == _selectedCarId)
        ? _selectedCarId
        : (cars.isNotEmpty ? cars.first.id : null);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Аналитика агрегатов'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: DropdownButtonFormField<int?>(
              initialValue: safeInitialValue,
              decoration: const InputDecoration(
                labelText: 'Автомобиль',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              // 🆕 ЗАДАЧА 3: Пункт "Все автомобили" полностью удален. Остались только реальные машины.
              items: [
                ...cars.map((car) => DropdownMenuItem<int?>(
                      value: car.id,
                      child: Text('${car.brand} (${car.licensePlate})'),
                    )),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedCarId = value;
                  });
                }
              },
            ),
          ),
          
          Expanded(
            child: safeInitialValue != null 
                ? AnalyticsOptimizationTab(selectedCarId: safeInitialValue)
                : const Center(child: Text('Нет добавленных автомобилей')),
          ),
        ],
      ),
    );
  }
}