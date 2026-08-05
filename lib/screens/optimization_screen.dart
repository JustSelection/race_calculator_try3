import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/generator_model.dart';
import '../models/optimization_model.dart';
import '../models/car_model.dart';
import '../providers/generator_provider.dart';
import '../providers/optimization_provider.dart';
import '../providers/car_provider.dart';

class OptimizationScreen extends StatefulWidget {
  final int? preselectedGeneratorId;

  const OptimizationScreen({super.key, this.preselectedGeneratorId});

  @override
  State<OptimizationScreen> createState() => _OptimizationScreenState();
}

class _OptimizationScreenState extends State<OptimizationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _commentController = TextEditingController();
  
  int? _selectedGeneratorId;
  String? _generatorError;

  double _round(double value) => double.parse(value.toStringAsFixed(2));

  @override
  void initState() {
    super.initState();
    _selectedGeneratorId = widget.preselectedGeneratorId;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  String _getCarInfo(List<Car> cars, int? carId) {
    if (carId == null) return 'Не привязан';
    final car = cars.firstWhere(
      (c) => c.id == carId,
      orElse: () => Car(
        id: -1, brand: 'Неизвестно', licensePlate: '',
        fuelConsumption: 0, currentMileage: 0, fuelInTank: 0, tankCapacity: 0,
      ),
    );
    return '${car.brand} (${car.licensePlate})';
  }

  Widget _buildGeneratorItem({
    required String name,
    required String carInfo,
    required bool isCarBound,
    required String extraInfo,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$name — $extraInfo',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          carInfo,
          style: TextStyle(
            fontSize: 11,
            color: isCarBound ? Colors.grey.shade600 : Colors.grey.shade500,
            fontStyle: isCarBound ? FontStyle.normal : FontStyle.italic,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final generators = context.watch<GeneratorProvider>().generators;
    final cars = context.watch<CarProvider>().cars;

    final selectedGen = generators.firstWhere(
      (g) => g.id == _selectedGeneratorId,
      orElse: () => GeneratorModel(name: '', capacity: 0, currentFuel: 0, carId: null),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Списание топлива (Оптимизация)')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Кастомное поле с валидацией
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Агрегат', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _generatorError != null ? Colors.red : Colors.grey.shade300,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: DropdownButton<int?>(
                      value: _selectedGeneratorId,
                      isExpanded: true,
                      underline: const SizedBox(), // Убираем стандартное подчеркивание
                      hint: const Text('Выберите агрегат'),
                      items: generators.map((g) => DropdownMenuItem<int?>(
                        value: g.id,
                        child: _buildGeneratorItem(
                          name: g.name,
                          carInfo: _getCarInfo(cars, g.carId),
                          isCarBound: g.carId != null,
                          extraInfo: 'доступно: ${g.currentFuel} л',
                        ),
                      )).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedGeneratorId = val;
                          _generatorError = null;
                        });
                      },
                    ),
                  ),
                  if (_generatorError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4, left: 12),
                      child: Text(_generatorError!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              if (_selectedGeneratorId != null) ...[
                TextFormField(
                  controller: _amountController,
                  decoration: const InputDecoration(labelText: 'Количество для списания (л)'),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value?.trim().isEmpty ?? true) return 'Введите количество';
                    final val = double.tryParse(value!);
                    if (val == null || val <= 0) return 'Некорректное значение';
                    if (val > selectedGen.currentFuel) {
                      return 'Превышает доступный остаток (${selectedGen.currentFuel} л)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _commentController,
                  decoration: const InputDecoration(labelText: 'Комментарий (куда затрачено)'),
                  maxLines: 3,
                  validator: (value) => value?.trim().isEmpty ?? true ? 'Введите комментарий' : null,
                ),
              ],
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _saveOptimization,
                child: const Text('Списать топливо'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveOptimization() async {
    // Валидация агрегата
    if (_selectedGeneratorId == null) {
      setState(() => _generatorError = 'Выберите агрегат');
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    final amount = double.parse(_amountController.text);
    final comment = _commentController.text.trim();
    
    final genProvider = context.read<GeneratorProvider>();
    final optProvider = context.read<OptimizationProvider>();
    
    final generator = genProvider.generators.firstWhere((g) => g.id == _selectedGeneratorId);
    final newFuel = _round(generator.currentFuel - amount);

    final fuelUpdated = await genProvider.updateFuel(generator.id!, newFuel);
    
    if (!mounted) return;

    if (fuelUpdated) {
      final optimization = OptimizationModel(
        generatorId: generator.id!,
        date: DateTime.now(),
        fuelAmount: amount,
        comment: comment,
      );
      
      final optSaved = await optProvider.addOptimization(optimization);

      if (!mounted) return;

      if (optSaved) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Успешно списано ${_round(amount)} л')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ошибка при сохранении истории')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ошибка при обновлении уровня топлива')),
      );
    }
  }
}