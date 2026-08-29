import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/optimization_model.dart';
import '../models/generator_model.dart';
import '../providers/generator_provider.dart';
import '../providers/optimization_provider.dart';
import '../providers/car_provider.dart';
import '../widgets/optimization_generator_selector.dart';

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

  Future<void> _saveOptimization() async {
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
        await optProvider.loadAnalytics();
        await genProvider.loadGenerators();

        if (!mounted) return;

        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          // 🆕 ИЗМЕНЕНО: "списано" -> "оптимизировано"
          SnackBar(content: Text('Успешно оптимизировано ${_round(amount)} л')),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ошибка при сохранении истории')),
        );
      }
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ошибка при обновлении уровня топлива')),
      );
    }
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
      // 🆕 ИЗМЕНЕНО: Заголовок экрана
      appBar: AppBar(title: const Text('Оптимизация топлива')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              OptimizationGeneratorSelector(
                generators: generators,
                cars: cars,
                selectedId: _selectedGeneratorId,
                errorText: _generatorError,
                onChanged: (val) => setState(() {
                  _selectedGeneratorId = val;
                  _generatorError = null;
                }),
              ),
              const SizedBox(height: 16),
              if (_selectedGeneratorId != null) ...[
                TextFormField(
                  controller: _amountController,
                  // 🆕 ИЗМЕНЕНО: Подпись поля ввода
                  decoration: const InputDecoration(labelText: 'Количество для оптимизации (л)'),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value?.trim().isEmpty ?? true) return 'Введите количество';
                    final val = double.tryParse(value!);
                    if (val == null || val <= 0) return 'Некорректное значение';
                    if (val > selectedGen.currentFuel) return 'Превышает доступный остаток (${selectedGen.currentFuel} л)';
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
              // 🆕 ИЗМЕНЕНО: Текст кнопки
              ElevatedButton(onPressed: _saveOptimization, child: const Text('Оптимизировать')),
            ],
          ),
        ),
      ),
    );
  }
}