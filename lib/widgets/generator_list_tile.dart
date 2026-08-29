import 'package:flutter/material.dart';
import '../models/car_model.dart';
import '../models/generator_model.dart';
import '../screens/generator_edit_screen.dart';
import '../screens/inventory_screen.dart';

class GeneratorListTile extends StatelessWidget {
  final GeneratorModel gen;
  final List<Car> cars;
  final VoidCallback onDelete;

  const GeneratorListTile({
    super.key,
    required this.gen,
    required this.cars,
    required this.onDelete,
  });

  String _getCarInfo() {
    if (gen.carId == null) return 'Не привязан';
    final car = cars.firstWhere(
      (c) => c.id == gen.carId,
      orElse: () => Car(
        id: -1, brand: 'Не привязан', licensePlate: '',
        fuelConsumption: 0, currentMileage: 0,
        fuelInTank: 0, tankCapacity: 0,
      ),
    );
    return '${car.brand} (${car.licensePlate})';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        // ️ УДАЛЕНО: долгий тап для редактирования
        title: Text(gen.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('Топливо: ${gen.currentFuel} / ${gen.capacity} л\nАвто: ${_getCarInfo()}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.local_fire_department, color: Colors.orange),
              tooltip: 'Работа агрегата',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => InventoryScreen(preselectedGeneratorId: gen.id),
                ),
              ),
            ),
            // 🆕 ДОБАВЛЕНО: Кнопка редактирования (карандаш)
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              tooltip: 'Редактировать',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => GeneratorEditScreen(generator: gen)),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              tooltip: 'Удалить',
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}