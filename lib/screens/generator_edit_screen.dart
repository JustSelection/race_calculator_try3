import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/generator_model.dart';
import '../providers/car_provider.dart';
import '../providers/generator_provider.dart';

class GeneratorEditScreen extends StatefulWidget {
  final GeneratorModel? generator;

  const GeneratorEditScreen({super.key, this.generator});

  @override
  State<GeneratorEditScreen> createState() => _GeneratorEditScreenState();
}

class _GeneratorEditScreenState extends State<GeneratorEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _capacityController;
  late TextEditingController _fuelController;
  int? _selectedCarId;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.generator?.name ?? '');
    _capacityController = TextEditingController(
      text: widget.generator?.capacity.toString() ?? '',
    );
    _fuelController = TextEditingController(
      text: widget.generator?.currentFuel.toString() ?? '',
    );
    _selectedCarId = widget.generator?.carId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _capacityController.dispose();
    _fuelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cars = context.watch<CarProvider>().cars;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.generator == null ? 'Новый агрегат' : 'Редактировать агрегат'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Название (напр. Генератор, Канистра ERA)'),
                validator: (value) => value?.trim().isEmpty ?? true ? 'Введите название' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _capacityController,
                decoration: const InputDecoration(labelText: 'Объем бака (л)'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value?.trim().isEmpty ?? true) return 'Введите объем';
                  final val = double.tryParse(value!);
                  if (val == null || val <= 0) return 'Некорректный объем';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _fuelController,
                decoration: const InputDecoration(labelText: 'Текущее топливо (л)'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value?.trim().isEmpty ?? true) return 'Введите количество топлива';
                  final val = double.tryParse(value!);
                  if (val == null || val < 0) return 'Некорректное значение';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int?>(
                initialValue: _selectedCarId, // Исправлено: value -> initialValue
                decoration: const InputDecoration(labelText: 'Привязать к автомобилю'),
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('Не привязан / Временно не используется'),
                  ),
                  ...cars.map((car) => DropdownMenuItem<int?>(
                        value: car.id,
                        child: Text('${car.brand} (${car.licensePlate})'),
                      )),
                ],
                onChanged: (value) => setState(() => _selectedCarId = value),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _save,
                child: const Text('Сохранить'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final capacity = double.parse(_capacityController.text);
    final currentFuel = double.parse(_fuelController.text);

    if (currentFuel > capacity) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Текущее топливо не может превышать объем бака')),
      );
      return;
    }

    final generator = GeneratorModel(
      id: widget.generator?.id,
      carId: _selectedCarId,
      name: _nameController.text.trim(),
      capacity: capacity,
      currentFuel: currentFuel,
    );

    final provider = context.read<GeneratorProvider>();
    final success = widget.generator == null
        ? await provider.addGenerator(generator)
        : await provider.updateGenerator(generator);

    if (!mounted) return;

    if (success) {
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ошибка при сохранении')),
      );
    }
  }
}