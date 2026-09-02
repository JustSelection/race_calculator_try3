import 'package:flutter/material.dart';
import '../models/car_model.dart';

class InventoryCarSelector extends StatelessWidget {
  final List<Car> cars;
  final int? selectedCarId;
  final ValueChanged<int?> onChanged;

  const InventoryCarSelector({
    super.key,
    required this.cars,
    required this.selectedCarId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<int>(
      key: ValueKey(selectedCarId),
      initialValue: selectedCarId,
      decoration: const InputDecoration(
        labelText: 'Выберите автомобиль',
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      hint: const Text('Выберите автомобиль или категорию'),
      items: [
        const DropdownMenuItem<int>(
          value: -1,
          child: Text('Не привязанные агрегаты'),
        ),
        // 🆕 ИСПРАВЛЕНО: убран лишний .toList() внутри spread-оператора
        ...cars.map((car) => DropdownMenuItem<int>(
              value: car.id,
              child: Text('${car.brand} (${car.licensePlate})'),
            )),
      ],
      onChanged: onChanged,
      validator: (value) => value == null ? 'Обязательно выберите категорию' : null,
    );
  }
}