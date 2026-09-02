import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/generator_model.dart';

class InventoryGeneratorForm extends StatelessWidget {
  final List<GeneratorModel> filteredGenerators;
  final int? selectedGeneratorId;
  final DateTime selectedDate;
  final TextEditingController actualFuelController;
  final ValueChanged<int?> onGeneratorChanged;
  final ValueChanged<DateTime> onDateChanged;
  final VoidCallback onSave;

  const InventoryGeneratorForm({
    super.key,
    required this.filteredGenerators,
    required this.selectedGeneratorId,
    required this.selectedDate,
    required this.actualFuelController,
    required this.onGeneratorChanged,
    required this.onDateChanged,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    // 🆕 ЗАЩИТА: Проверяем, что selectedGeneratorId реально существует в отфильтрованном списке
    final safeGeneratorValue = filteredGenerators.any((g) => g.id == selectedGeneratorId) 
        ? selectedGeneratorId 
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Выбор агрегата
        DropdownButtonFormField<int>(
          key: ValueKey(safeGeneratorValue),
          initialValue: safeGeneratorValue,
          decoration: const InputDecoration(
            labelText: 'Выберите агрегат',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          hint: const Text('Выберите агрегат'),
          items: filteredGenerators.map((g) {
            return DropdownMenuItem<int>(
              value: g.id,
              child: Text('${g.name} (сейчас: ${g.currentFuel} л)'),
            );
          }).toList(),
          onChanged: onGeneratorChanged,
          validator: (value) => value == null ? 'Обязательно выберите агрегат' : null,
        ),
        
        // Предупреждение, если у выбранной категории нет агрегатов
        if (filteredGenerators.isEmpty) ...[
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.orange, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'К выбранной категории не привязано ни одного агрегата.',
                    style: TextStyle(color: Colors.grey.shade800, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 16),
        
        // Выбор даты
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: selectedDate,
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            if (picked != null) {
              onDateChanged(picked);
            }
          },
          child: InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Дата замера',
              border: OutlineInputBorder(),
              suffixIcon: Icon(Icons.calendar_today),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            child: Text(DateFormat('dd.MM.yyyy').format(selectedDate)),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Ввод фактического уровня топлива (показываем только если агрегат выбран)
        if (selectedGeneratorId != null) ...[
          Builder(
            builder: (context) {
              // 🆕 ИСПРАВЛЕНО: Безопасный поиск с orElse, чтобы избежать краша, 
              // если по какой-то причине ID нет в списке
              final gen = filteredGenerators.firstWhere(
                (g) => g.id == selectedGeneratorId,
                orElse: () => filteredGenerators.isNotEmpty ? filteredGenerators.first : GeneratorModel(name: '', capacity: 0, currentFuel: 0, carId: null),
              );
              
              return TextFormField(
                controller: actualFuelController,
                decoration: const InputDecoration(
                  labelText: 'Текущий уровень топлива (л)',
                  border: OutlineInputBorder(),
                  helperText: 'Максимум: текущий уровень',
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value?.trim().isEmpty ?? true) return 'Введите уровень';
                  final val = double.tryParse(value!);
                  if (val == null || val < 0) return 'Некорректное значение';
                  if (val > gen.currentFuel) {
                    return 'Уровень не может быть больше текущего (${gen.currentFuel} л). Для пополнения используйте "Заправку".';
                  }
                  return null;
                },
              );
            },
          ),
          
          const SizedBox(height: 32),
          
          // Кнопка сохранения
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: filteredGenerators.isEmpty ? null : onSave,
              icon: const Icon(Icons.local_fire_department),
              label: const Text('Зафиксировать расход'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ],
    );
  }
}