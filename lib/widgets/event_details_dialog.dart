import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/analytics_event_model.dart';
import '../models/generator_model.dart';
import '../models/car_model.dart';
import '../providers/generator_provider.dart';
import '../providers/car_provider.dart';

class EventDetailsDialog extends StatelessWidget {
  final AnalyticsEventModel event;

  const EventDetailsDialog({super.key, required this.event});

  String _getTypeName(String type) {
    switch (type) {
      case 'refuel': return 'Заправка';
      case 'inventory': return 'Работа агрегата';
      case 'transfer': return 'Перелив';
      case 'calibration': return 'Инвентаризация';
      default: return type;
    }
  }

  // 🆕 Метод для извлечения числа литров из описания (та же логика, что в аналитике)
  double? _extractFuelAmount(String description) {
    final match = RegExp(r'(\d+\.?\d*)\s*л').firstMatch(description);
    if (match != null) {
      return double.tryParse(match.group(1)!);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final generators = context.watch<GeneratorProvider>().generators;
    final cars = context.watch<CarProvider>().cars;

    final generator = (event.relatedId != null && event.relatedId! > 0)
        ? generators.firstWhere(
            (g) => g.id == event.relatedId,
            orElse: () => GeneratorModel(
              name: 'Неизвестный агрегат', 
              capacity: 0, 
              currentFuel: 0, 
              carId: null,
            ),
          )
        : null;

    final car = (generator != null && generator.carId != null)
        ? cars.firstWhere(
            (c) => c.id == generator.carId,
            orElse: () => Car(
              id: -1, 
              brand: 'Не привязан', 
              licensePlate: '', 
              fuelConsumption: 0, 
              currentMileage: 0, 
              fuelInTank: 0, 
              tankCapacity: 0,
            ),
          )
        : null;

    final dateStr = DateFormat('dd.MM.yyyy HH:mm').format(event.date);
    final fuelAmount = _extractFuelAmount(event.description);

    return AlertDialog(
      title: Text(_getTypeName(event.type)),
      content: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Дата и время', dateStr),
              const Divider(height: 24),
              
              // 🆕 ОТДЕЛЬНЫЙ ПУНКТ: Заправлено по чеку
              if (fuelAmount != null && event.type == 'refuel')
                _buildDetailRow('Заправлено по чеку', '${fuelAmount.toStringAsFixed(2)} л'),
              
              // 🆕 ОТДЕЛЬНЫЙ ПУНКТ: Расход при заправке
              if (fuelAmount != null && event.type == 'inventory' && event.description.contains('расход при заправке'))
                _buildDetailRow('Расход при заправке', '${fuelAmount.toStringAsFixed(2)} л'),

              // Если это другой тип события или не удалось извлечь число, показываем полное описание
              if (fuelAmount == null || (event.type != 'refuel' && !(event.type == 'inventory' && event.description.contains('расход при заправке'))))
                _buildDetailRow('Описание', event.description),
              
              if (generator != null) ...[
                const Divider(height: 24),
                _buildDetailRow('Агрегат', generator.name),
                if (car != null)
                  _buildDetailRow('Автомобиль', '${car.brand} (${car.licensePlate})'),
              ],

              if (event.type == 'refuel') ...[
                const Divider(height: 24),
                const Text(
                  'Детали операции:', 
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.blue),
                ),
                const SizedBox(height: 8),
                Text(
                  'Топливо было распределено по агрегатам согласно введенным фактическим уровням. Разница между ожидаемым и фактическим остатком автоматически зафиксирована как отдельное событие "Работа агрегата" (расход при заправке).',
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 13, height: 1.4),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Закрыть'),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130, // 🆕 Чуть шире, чтобы длинные заголовки ("Заправлено по чеку") помещались
            child: Text(
              '$label:',
              style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, height: 1.3),
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }
}