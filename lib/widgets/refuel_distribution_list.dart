import 'package:flutter/material.dart';
import '../models/car_model.dart';
import '../models/generator_model.dart';

class RefuelDistributionList extends StatelessWidget {
  final List<GeneratorModel> allGenerators;
  final List<Car> cars;
  final int? selectedCarId;
  final Map<int, TextEditingController> controllers;
  final ValueChanged<int?> onCarFilterChanged;

  const RefuelDistributionList({
    super.key,
    required this.allGenerators,
    required this.cars,
    required this.selectedCarId,
    required this.controllers,
    required this.onCarFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Строгая фильтрация: показываем только агрегаты выбранного автомобиля
    final filteredGens = selectedCarId == null
        ? <GeneratorModel>[]
        : allGenerators.where((g) => g.carId == selectedCarId).toList();

    // 🆕 ЗАЩИТА: Проверяем, что selectedCarId реально существует в списке cars
    final safeInitialValue = cars.any((c) => c.id == selectedCarId) ? selectedCarId : null;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: DropdownButtonFormField<int>(
            // 🆕 Ключ гарантирует перерисовку виджета при смене автомобиля, решая проблему реактивности initialValue
            key: ValueKey(safeInitialValue),
            initialValue: safeInitialValue, 
            decoration: const InputDecoration(
              labelText: 'Выберите автомобиль для заправки',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            hint: const Text('Выберите автомобиль'), // 🆕 Показывает подсказку, пока safeInitialValue == null
            items: cars.map((car) => DropdownMenuItem<int>(
                  value: car.id,
                  child: Text('${car.brand} (${car.licensePlate})'),
                )).toList(),
            onChanged: onCarFilterChanged,
            validator: (value) => value == null ? 'Обязательно выберите автомобиль' : null,
          ),
        ),
        Expanded(
          child: filteredGens.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Text(
                      selectedCarId == null
                          ? 'Пожалуйста, выберите автомобиль из списка выше, чтобы начать распределение.'
                          : 'К выбранному автомобилю не привязано ни одного агрегата.\n\nВесь объем заправки будет автоматически учтен как расход (работа агрегатов).',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: filteredGens.length,
                  itemBuilder: (context, index) {
                    final gen = filteredGens[index];
                    final ctrl = controllers[gen.id!];

                    if (ctrl == null) return const SizedBox.shrink();

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: ListTile(
                        title: Text(gen.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Было: ${gen.currentFuel} л / Макс: ${gen.capacity} л'),
                        trailing: SizedBox(
                          width: 100,
                          child: TextFormField(
                            controller: ctrl,
                            decoration: const InputDecoration(labelText: 'Стало (л)', border: OutlineInputBorder()),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            validator: (value) {
                              final val = double.tryParse(value ?? '');
                              if (val == null) return 'Число';
                              if (val < 0) return '>= 0';
                              if (val > gen.capacity) return '<= ${gen.capacity}';
                              return null;
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}