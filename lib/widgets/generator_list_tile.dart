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

  // 🆕 Метод для определения цвета прогресс-бара в зависимости от уровня топлива
  Color _getFuelColor(double current, double capacity) {
    if (capacity <= 0) return Colors.grey;
    final percentage = current / capacity;
    if (percentage >= 0.3) return Colors.blue; // Норма
    if (percentage >= 0.1) return Colors.orange; // Мало
    return Colors.red; // Критически мало
  }

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
    // 🆕 Расчет процента заполнения (защита от деления на ноль)
    final fuelPercentage = gen.capacity > 0 
        ? (gen.currentFuel / gen.capacity).clamp(0.0, 1.0) 
        : 0.0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        onTap: () => _showSummary(context),
        title: Text(
          gen.name, 
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        // 🆕 ИЗМЕНЕНО: Подпись заменена на колонку с информацией об авто и трек-баром
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'Авто: ${_getCarInfo()}', 
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            // Трек-бар уровня топлива
            LinearProgressIndicator(
              value: fuelPercentage,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(_getFuelColor(gen.currentFuel, gen.capacity)),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 6),
            // Точные цифры под трек-баром
            Text(
              '${gen.currentFuel.toStringAsFixed(1)} / ${gen.capacity} л',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.local_fire_department, color: Colors.orange, size: 22),
              tooltip: 'Работа агрегата',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => InventoryScreen(preselectedGeneratorId: gen.id),
                ),
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue, size: 22),
              tooltip: 'Редактировать',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => GeneratorEditScreen(generator: gen)),
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red, size: 22),
              tooltip: 'Удалить',
              onPressed: onDelete,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }
}