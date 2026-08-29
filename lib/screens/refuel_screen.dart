import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
// Примечание: refuel_distribution_screen.dart будет создан на следующем шаге
import 'refuel_distribution_screen.dart';

class RefuelScreen extends StatefulWidget {
  const RefuelScreen({super.key});

  @override
  State<RefuelScreen> createState() => _RefuelScreenState();
}

class _RefuelScreenState extends State<RefuelScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _commentController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  @override
  void dispose() {
    _amountController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  void _goToDistribution() {
    if (!_formKey.currentState!.validate()) return;
    
    final totalFuel = double.parse(_amountController.text);
    final comment = _commentController.text.trim();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RefuelDistributionScreen(
          totalFuel: totalFuel,
          date: _selectedDate,
          comment: comment,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Новая заправка (Шаг 1/2)')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
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
                    labelText: 'Дата заправки',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(DateFormat('dd.MM.yyyy').format(_selectedDate)),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Общее количество топлива по чеку (л)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value?.trim().isEmpty ?? true) return 'Введите количество';
                  final val = double.tryParse(value!);
                  if (val == null || val <= 0) return 'Некорректное значение';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _commentController,
                decoration: const InputDecoration(
                  labelText: 'Комментарий (необязательно)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _goToDistribution,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Далее: Распределить по агрегатам'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}