import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/inventory_model.dart';
import '../providers/generator_provider.dart';
import '../providers/inventory_provider.dart';

class InventoryScreen extends StatefulWidget {
  final int? preselectedGeneratorId;

  const InventoryScreen({super.key, this.preselectedGeneratorId});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _actualFuelController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  int? _selectedGeneratorId;

  @override
  void initState() {
    super.initState();
    _selectedGeneratorId = widget.preselectedGeneratorId;
  }

  @override
  void dispose() {
    _actualFuelController.dispose();
    super.dispose();
  }

  double _round(double value) => double.parse(value.toStringAsFixed(2));

  void _saveInventory() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedGeneratorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выберите агрегат'), backgroundColor: Colors.red),
      );
      return;
    }

    final genProv = context.read<GeneratorProvider>();
    final invProv = context.read<InventoryProvider>();
    final generator = genProv.generators.firstWhere((g) => g.id == _selectedGeneratorId);

    final actualFuel = double.parse(_actualFuelController.text);
    final difference = _round(actualFuel - generator.currentFuel);

    final inventory = InventoryModel(
      generatorId: generator.id!,
      date: _selectedDate,
      previousFuel: generator.currentFuel,
      actualFuel: actualFuel,
      difference: difference,
    );

    invProv.addInventory(inventory).then((success) {
      if (!mounted) return;
      if (success) {
        // 🆕 АВТООБНОВЛЕНИЕ: принудительно перезагружаем список агрегатов, чтобы уровни обновились мгновенно
        genProv.loadGenerators();
        
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Уровень обновлен. Расход зафиксирован.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ошибка при сохранении'), backgroundColor: Colors.red),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final generators = context.watch<GeneratorProvider>().generators;
    final safeInitialValue = generators.any((g) => g.id == _selectedGeneratorId) ? _selectedGeneratorId : null;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.local_fire_department, color: Colors.orange),
            SizedBox(width: 8),
            Text('Работа агрегата'),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const Text(
                'Укажите текущий уровень. Он должен быть меньше или равен предыдущему, так как агрегат только расходует топливо.',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                initialValue: safeInitialValue,
                decoration: const InputDecoration(
                  labelText: 'Выберите агрегат',
                  border: OutlineInputBorder(),
                ),
                items: generators.map((g) {
                  return DropdownMenuItem<int>(
                    value: g.id,
                    child: Text('${g.name} (сейчас: ${g.currentFuel} л)'),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedGeneratorId = value;
                    _actualFuelController.clear();
                  });
                },
                validator: (value) => value == null ? 'Обязательно выберите агрегат' : null,
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) setState(() => _selectedDate = picked);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Дата замера',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(DateFormat('dd.MM.yyyy').format(_selectedDate)),
                ),
              ),
              const SizedBox(height: 16),
              if (_selectedGeneratorId != null) ...[
                Builder(
                  builder: (context) {
                    final gen = generators.firstWhere((g) => g.id == _selectedGeneratorId);
                    return TextFormField(
                      controller: _actualFuelController,
                      decoration: const InputDecoration(
                        labelText: 'Текущий уровень топлива (л)',
                        border: OutlineInputBorder(),
                        helperText: 'Максимум: текущий уровень',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value?.trim().isEmpty ?? true) return 'Введите уровень';
                        final val = double.tryParse(value!);
                        if (val == null || val < 0) return 'Некорректное значение';
                        if (val > gen.currentFuel) {
                          return 'Уровень не может быть больше текущего (${gen.currentFuel} л). Для пополнения используйте "Заправку" или "Инвентаризацию".';
                        }
                        return null;
                      },
                    );
                  },
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: _saveInventory,
                  icon: const Icon(Icons.local_fire_department),
                  label: const Text('Зафиксировать расход'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}