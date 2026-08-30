import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/generator_model.dart';
import '../providers/generator_provider.dart';
import '../providers/car_provider.dart';
import '../providers/transfer_fuel_provider.dart';
import '../widgets/transfer_fuel_widgets.dart';

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
              buildTransferDropdown(
                label: 'Из агрегата (источник)',
                value: _sourceId,
                items: generators.map((g) => DropdownMenuItem(
                  value: g.id,
                  child: buildTransferGeneratorItem(
                    name: g.name,
                    carInfo: getTransferCarInfo(cars, g.carId),
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
              buildTransferDropdown(
                label: 'В агрегат (приемник)',
                value: _destId,
                items: generators
                    .where((g) => g.id != _sourceId)
                    .map((g) => DropdownMenuItem(
                          value: g.id,
                          child: buildTransferGeneratorItem(
                            name: g.name,
                            carInfo: getTransferCarInfo(cars, g.carId),
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

  Future<void> _transfer() async {
    if (!_formKey.currentState!.validate()) return;

    // 🛡️ ЗАЩИТА: Заменяем запятую на точку и безопасно парсим число
    final textAmount = _amountController.text.replaceAll(',', '.').trim();
    final amount = double.tryParse(textAmount);

    if (amount == null || amount <= 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите корректное количество топлива'), backgroundColor: Colors.red),
      );
      return;
    }

    final transferProvider = context.read<TransferFuelProvider>();
    final genProvider = context.read<GeneratorProvider>();

    try {
      final success = await transferProvider.transferFuel(
        sourceId: _sourceId!,
        destId: _destId!,
        amount: amount,
        date: DateTime.now(),
      );

      if (!mounted) return;

      if (success) {
        await genProvider.loadGenerators();
        if (!mounted) return;
        
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Успешно перелито ${_round(amount)} л')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ошибка при обновлении данных'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Произошла ошибка: $e'), backgroundColor: Colors.red),
      );
    }
  }
}