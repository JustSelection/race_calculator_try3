import 'package:flutter/material.dart';
import '../models/generator_model.dart';
import '../models/car_model.dart';

class OptimizationGeneratorSelector extends StatelessWidget {
  final List<GeneratorModel> generators;
  final List<Car> cars;
  final int? selectedId;
  final String? errorText;
  final ValueChanged<int?> onChanged;

  const OptimizationGeneratorSelector({
    super.key,
    required this.generators,
    required this.cars,
    required this.selectedId,
    required this.errorText,
    required this.onChanged,
  });

  String _getCarInfo(int? carId) {
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

  Widget _buildItem(GeneratorModel g) {
    final carInfo = _getCarInfo(g.carId);
    final isBound = g.carId != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${g.name} — доступно: ${g.currentFuel} л',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        Text(
          carInfo,
          style: TextStyle(
            fontSize: 11,
            color: isBound ? Colors.grey.shade600 : Colors.grey.shade500,
            fontStyle: isBound ? FontStyle.normal : FontStyle.italic,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Агрегат', style: TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: errorText != null ? Colors.red : Colors.grey.shade300),
            borderRadius: BorderRadius.circular(4),
          ),
          child: DropdownButton<int?>(
            value: selectedId,
            isExpanded: true,
            underline: const SizedBox(),
            hint: const Text('Выберите агрегат'),
            items: generators.map((g) => DropdownMenuItem<int?>(value: g.id, child: _buildItem(g))).toList(),
            onChanged: onChanged,
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 12),
            child: Text(errorText!, style: const TextStyle(color: Colors.red, fontSize: 12)),
          ),
      ],
    );
  }
}