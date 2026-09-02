import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/calibration_model.dart';
import '../providers/generator_provider.dart';
import '../providers/calibration_provider.dart';
import '../providers/optimization_provider.dart';
import '../providers/inventory_provider.dart';
import '../providers/car_provider.dart';
import '../widgets/calibration_generator_list.dart';

class GlobalCalibrationScreen extends StatefulWidget {
  const GlobalCalibrationScreen({super.key});

  @override
  State<GlobalCalibrationScreen> createState() => _GlobalCalibrationScreenState();
}

class _GlobalCalibrationScreenState extends State<GlobalCalibrationScreen> {
  final Map<int, TextEditingController> _controllers = {};
  DateTime _selectedDate = DateTime.now();
  int? _selectedCarId; 

  @override
  void dispose() {
    for (final ctrl in _controllers.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  void _showWarningAndSave() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Подтверждение'),
        content: const Text(
          'Проведение инвентаризации остатков принудительно изменит уровни топлива во всех агрегатах. '
          'Это действие также сбросит накопленную аналитику и лимиты оптимизации с текущего момента. '
          'Продолжить?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _performCalibration();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Провести', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _performCalibration() async {
    final genProv = context.read<GeneratorProvider>();
    final calProv = context.read<CalibrationProvider>();
    final optProv = context.read<OptimizationProvider>();
    final invProv = context.read<InventoryProvider>();
    
    final Map<int, double> newFuelLevels = {};
    for (final gen in genProv.generators) {
      final ctrl = _controllers[gen.id];
      if (ctrl != null && ctrl.text.isNotEmpty) {
        final val = double.tryParse(ctrl.text);
        if (val != null) {
          newFuelLevels[gen.id!] = val;
        }
      } else {
        newFuelLevels[gen.id!] = gen.currentFuel;
      }
    }

    final calibration = CalibrationModel(
      date: _selectedDate,
      comment: 'полная инвентаризация остатков',
    );

    final success = await calProv.performCalibration(calibration, newFuelLevels);
    if (!mounted) return;

    if (success) {
      await optProv.clearOptimizations();
      await invProv.clearInventories();
      await genProv.loadGenerators();

      if (!mounted) return;

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Инвентаризация проведена. История агрегатов обновлена.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ошибка при проведении инвентаризации'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final generators = context.watch<GeneratorProvider>().generators;
    final cars = context.watch<CarProvider>().cars;

    final filteredGenerators = _selectedCarId == null
        ? generators
        : _selectedCarId == -1
            ? generators.where((g) => g.carId == null).toList()
            : generators.where((g) => g.carId == _selectedCarId).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Инвентаризация')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: DropdownButtonFormField<int>(
              key: ValueKey(_selectedCarId),
              initialValue: _selectedCarId,
              decoration: const InputDecoration(
                labelText: 'Фильтр по автомобилю',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              hint: const Text('Все агрегаты'),
              items: [
                const DropdownMenuItem<int>(value: null, child: Text('Все агрегаты')),
                const DropdownMenuItem<int>(value: -1, child: Text('Не привязанные')),
                // 🆕 ИСПРАВЛЕНО: убран лишний .toList() внутри spread-оператора
                ...cars.map((car) => DropdownMenuItem<int>(
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

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context, initialDate: _selectedDate,
                  firstDate: DateTime(2000), lastDate: DateTime(2100),
                );
                if (picked != null) setState(() => _selectedDate = picked);
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Дата инвентаризации', border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(DateFormat('dd.MM.yyyy').format(_selectedDate)),
              ),
            ),
          ),
          
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Введите фактические остатки для проведения полной инвентаризации.',
              style: TextStyle(color: Colors.grey, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 8),
          
          Expanded(
            child: filteredGenerators.isEmpty
                ? const Center(
                    child: Text(
                      'Нет агрегатов для выбранного фильтра.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : CalibrationGeneratorList(
                    generators: filteredGenerators,
                    controllers: _controllers,
                  ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: filteredGenerators.isEmpty ? null : _showWarningAndSave,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14), backgroundColor: Colors.orange,
                ),
                child: const Text('Провести инвентаризацию', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}