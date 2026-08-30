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

  // 🆕 Метод для отображения сводки по агрегату
  void _showSummary(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(gen.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Объем бака', '${gen.capacity} л'),
            const SizedBox(height: 8),
            _buildDetailRow('Текущий остаток', '${gen.currentFuel} л'),
            const SizedBox(height: 8),
            _buildDetailRow('Привязка к авто', _getCarInfo()),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  // 🆕 Вспомогательный виджет для строк сводки
  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        onTap: () => _showSummary(context), // 🆕 Добавлен вызов сводки при нажатии на карточку
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