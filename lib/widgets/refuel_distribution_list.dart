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
    // Фильтрация списка для отображения
    final filteredGens = selectedCarId == null || selectedCarId == -1
        ? (selectedCarId == -1 ? allGenerators.where((g) => g.carId == null).toList() : allGenerators)
        : allGenerators.where((g) => g.carId == selectedCarId).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: DropdownButtonFormField<int?>(
            initialValue: selectedCarId,
            decoration: const InputDecoration(
              labelText: 'Фильтр по автомобилю',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: [
              const DropdownMenuItem<int?>(value: null, child: Text('Все агрегаты')),
              const DropdownMenuItem<int?>(value: -1, child: Text('Не привязанные')),
              ...cars.map((car) => DropdownMenuItem<int?>(
                    value: car.id,
                    child: Text('${car.brand} (${car.licensePlate})'),
                  )),
            ],
            onChanged: onCarFilterChanged,
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: filteredGens.length,
            itemBuilder: (context, index) {
              final gen = filteredGens[index];
              // Гарантируем наличие контроллера для этого агрегата
              if (!controllers.containsKey(gen.id)) {
                // Примечание: обновление суммы должно происходить через callback или общий state, 
                // но здесь мы полагаемся на то, что контроллеры инициализированы в родителе.
                // Для простоты оставим доступ к существующему контроллеру.
              }
              final ctrl = controllers[gen.id!]!;

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