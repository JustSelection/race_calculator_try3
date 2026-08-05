import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/generator_model.dart';
import '../models/car_model.dart';
import '../providers/generator_provider.dart';
import '../providers/car_provider.dart';

class TransferFuelScreen extends StatefulWidget {
  const TransferFuelScreen({super.key});

  @override
  State<TransferFuelScreen> createState() => _TransferFuelScreenState();
}

class _TransferFuelScreenState extends State<TransferFuelScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  
  int? _sourceId;
  int? _destId;

  double _round(double value) => double.parse(value.toStringAsFixed(2));

  @override
  void dispose() {
    _amountController.dispose();
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

  @override
  Widget build(BuildContext context) {
    final generators = context.watch<GeneratorProvider>().generators;
    final cars = context.watch<CarProvider>().cars;

    final sourceGen = generators.firstWhere(
      (g) => g.id == _sourceId,
      orElse: () => GeneratorModel(name: '', capacity: 0, currentFuel: 0, carId: null),
    );
    
    final destGen = generators.firstWhere(
      (g) => g.id == _destId,
      orElse: () => GeneratorModel(name: '', capacity: 0, currentFuel: 0, carId: null),
    );

    final maxTransfer = sourceGen.currentFuel;
    final maxReceive = destGen.id != null ? (destGen.capacity - destGen.currentFuel) : 0.0;
    final absoluteMax = maxTransfer < maxReceive ? maxTransfer : maxReceive;

    return Scaffold(
      appBar: AppBar(title: const Text('Перелив топлива')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildDropdown(
                label: 'Из агрегата (источник)',
                value: _sourceId,
                items: generators.map((g) => DropdownMenuItem(
                  value: g.id,
                  child: _buildGeneratorItem(
                    name: g.name,
                    carInfo: _getCarInfo(cars, g.carId),
                    isCarBound: g.carId != null,
                    extraInfo: '${g.currentFuel}/${g.capacity} л',
                  ),
                )).toList(),
                onChanged: (val) {
                  setState(() {
                    _sourceId = val;
                    if (_destId == val) _destId = null;
                    _amountController.clear();
                  });
                },
                validator: (val) => val == null ? 'Выберите источник' : null,
              ),
              const SizedBox(height: 16),
              _buildDropdown(
                label: 'В агрегат (приемник)',
                value: _destId,
                items: generators
                    .where((g) => g.id != _sourceId)
                    .map((g) => DropdownMenuItem(
                          value: g.id,
                          child: _buildGeneratorItem(
                            name: g.name,
                            carInfo: _getCarInfo(cars, g.carId),
                            isCarBound: g.carId != null,
                            extraInfo: 'свободно: ${_round(g.capacity - g.currentFuel)} л',
                          ),
                        ))
                    .toList(),
                onChanged: (val) {
                  setState(() {
                    _destId = val;
                    _amountController.clear();
                  });
                },
                validator: (val) => val == null ? 'Выберите приемник' : null,
              ),
              const SizedBox(height: 16),
              if (_sourceId != null && _destId != null) ...[
                Text(
                  'Доступно для перелива: до $absoluteMax л',
                  style: TextStyle(
                    color: absoluteMax > 0 ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _amountController,
                  decoration: const InputDecoration(labelText: 'Количество (л)'),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value?.trim().isEmpty ?? true) return 'Введите количество';
                    final val = double.tryParse(value!);
                    if (val == null || val <= 0) return 'Некорректное значение';
                    if (val > absoluteMax) return 'Превышает доступный лимит ($absoluteMax л)';
                    return null;
                  },
                ),
              ],
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _transfer,
                child: const Text('Перелить'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGeneratorItem({
    required String name,
    required String carInfo,
    required bool isCarBound,
    required String extraInfo,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$name — $extraInfo',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
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
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required int? value,
    required List<DropdownMenuItem<int?>> items,
    required ValueChanged<int?> onChanged,
    required String? Function(int?) validator,
  }) {
    return FormField<int?>(
      validator: validator,
      builder: (state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            DropdownButton<int?>(
              isExpanded: true,
              value: value,
              itemHeight: null, // ВАЖНО: разрешает автоматическую высоту для многострочного текста
              hint: const Text('Выберите...'),
              items: items.isEmpty 
                  ? [const DropdownMenuItem(value: null, child: Text('Нет доступных агрегатов'))] 
                  : items,
              onChanged: items.isEmpty ? null : (val) {
                onChanged(val);
                state.didChange(val);
              },
            ),
            if (state.hasError)
              Padding(
                padding: const EdgeInsets.only(left: 12, top: 4),
                child: Text(state.errorText!, style: const TextStyle(color: Colors.red, fontSize: 12)),
              ),
          ],
        );
      },
    );
  }

  Future<void> _transfer() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.parse(_amountController.text);
    final provider = context.read<GeneratorProvider>();
    final generators = provider.generators;

    final source = generators.firstWhere((g) => g.id == _sourceId);
    final dest = generators.firstWhere((g) => g.id == _destId);

    final newSourceFuel = _round(source.currentFuel - amount);
    final newDestFuel = _round(dest.currentFuel + amount);

    final success1 = await provider.updateFuel(source.id!, newSourceFuel);
    final success2 = await provider.updateFuel(dest.id!, newDestFuel);

    if (!mounted) return;

    if (success1 && success2) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Успешно перелито ${_round(amount)} л')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ошибка при переливе')),
      );
    }
  }
}