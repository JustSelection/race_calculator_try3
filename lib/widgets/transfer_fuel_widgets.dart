import 'package:flutter/material.dart';
import '../models/generator_model.dart';
import '../models/car_model.dart';
import '../providers/car_provider.dart';

String getTransferCarInfo(List<Car> cars, int? carId) {
  if (carId == null) return 'Не привязан';
  final car = cars.firstWhere(
    (c) => c.id == carId,
    orElse: () => Car(
      id: -1, brand: 'Неизвестно', licensePlate: '',
      fuelConsumption: 0, currentMileage: 0, fuelInTank: 0, tankCapacity: 0,
    ),
  );
  return '${car.brand} (${car.licensePlate})';
}

Widget buildTransferGeneratorItem({
  required String name,
  required String carInfo,
  required bool isCarBound,
  required String extraInfo,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$name — $extraInfo',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          carInfo,
          style: TextStyle(
            fontSize: 11,
            color: isCarBound ? Colors.grey.shade600 : Colors.grey.shade500,
            fontStyle: isCarBound ? FontStyle.normal : FontStyle.italic,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    ),
  );
}

Widget buildTransferDropdown({
  required String label,
  required int? value,
  required List<DropdownMenuItem<int?>> items,
  required ValueChanged<int?> onChanged,
  required String? Function(int?) validator,
}) {
  return FormField<int?>(
    validator: validator,
    builder: (state) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          DropdownButton<int?>(
            isExpanded: true,
            value: value,
            itemHeight: null, // Разрешает автоматическую высоту для многострочного текста
            hint: const Text('Выберите...'),
            items: items.isEmpty
                ? [const DropdownMenuItem(value: null, child: Text('Нет доступных агрегатов'))]
                : items,
            onChanged: items.isEmpty ? null : (val) {
              onChanged(val);
              state.didChange(val);
            },
          ),
          if (state.hasError)
            Padding(
              padding: const EdgeInsets.only(left: 12, top: 4),
              child: Text(state.errorText!, style: const TextStyle(color: Colors.red, fontSize: 12)),
            ),
        ],
      );
    },
  );
}