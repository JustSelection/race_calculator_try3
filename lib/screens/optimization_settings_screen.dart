import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/optimization_settings_provider.dart';

class OptimizationSettingsScreen extends StatefulWidget {
  const OptimizationSettingsScreen({super.key});

  @override
  State<OptimizationSettingsScreen> createState() => _OptimizationSettingsScreenState();
}

class _OptimizationSettingsScreenState extends State<OptimizationSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _weekController;
  late TextEditingController _monthController;

  @override
  void initState() {
    super.initState();
    final settings = context.read<OptimizationSettingsProvider>();
    _weekController = TextEditingController(text: settings.weekLimit.toString());
    _monthController = TextEditingController(text: settings.monthLimit.toString());
  }

  @override
  void dispose() {
    _weekController.dispose();
    _monthController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Настройки лимитов оптимизации')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const Text(
                'Настройте лимиты оптимизации как процент от фактического расхода топлива за период.',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _weekController,
                decoration: const InputDecoration(
                  labelText: 'Недельный лимит',
                  hintText: 'Например: 10',
                  suffixText: '%',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value?.trim().isEmpty ?? true) return 'Введите лимит';
                  final val = double.tryParse(value!);
                  if (val == null || val <= 0 || val > 100) {
                    return 'Значение должно быть от 1 до 100';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _monthController,
                decoration: const InputDecoration(
                  labelText: 'Месячный лимит',
                  hintText: 'Например: 15',
                  suffixText: '%',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value?.trim().isEmpty ?? true) return 'Введите лимит';
                  final val = double.tryParse(value!);
                  if (val == null || val <= 0 || val > 100) {
                    return 'Значение должно быть от 1 до 100';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _save,
                child: const Text('Сохранить настройки'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final weekLimit = double.parse(_weekController.text);
    final monthLimit = double.parse(_monthController.text);

    final provider = context.read<OptimizationSettingsProvider>();
    final success = await provider.updateLimits(weekLimit, monthLimit);

    if (!mounted) return;

    if (success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Настройки процентов сохранены')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ошибка при сохранении')),
      );
    }
  }
}