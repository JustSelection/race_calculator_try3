import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/optimization_model.dart';
import '../models/car_model.dart';
import '../providers/car_provider.dart';

/// Показывает нижнюю шторку с деталями оптимизации
void showOptimizationDetailsBottomSheet(
  BuildContext context,
  OptimizationModel opt,
  String genName,
  List<dynamic> generators,
) {
  final dateStr = DateFormat('dd.MM.yyyy, HH:mm').format(opt.date);

  dynamic gen;
  try {
    gen = generators.firstWhere((g) => g.id == opt.generatorId);
  } catch (_) {
    gen = null;
  }

  final cars = context.read<CarProvider>().cars;
  String carInfo = 'Агрегат удалён';
  if (gen != null) {
    if (gen.carId == null) {
      carInfo = 'Не привязан';
    } else {
      final car = cars.firstWhere(
        (c) => c.id == gen.carId,
        orElse: () => Car(
          id: -1, brand: 'Неизвестно', licensePlate: '',
          fuelConsumption: 0, currentMileage: 0, fuelInTank: 0, tankCapacity: 0,
        ),
      );
      carInfo = '${car.brand} (${car.licensePlate})';
    }
  }

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      final maxHeight = MediaQuery.of(ctx).size.height * 0.85;
      return ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Padding(
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Детали оптимизации',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _detailRow('Агрегат', genName),
              _detailRow('Автомобиль', carInfo),
              _detailRow('Дата и время', dateStr),
              _detailRow('Объем оптимизации', '${opt.fuelAmount.toStringAsFixed(2)} л', isHighlight: true),
              if (opt.comment.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Комментарий:',
                  style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 6),
                //  ИЗМЕНЕНО: Оборачиваем в Expanded + SingleChildScrollView для прокрутки длинных комментариев
                Expanded(
                  child: SingleChildScrollView(
                    child: Text(
                      opt.comment,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      );
    },
  );
}

Widget _detailRow(String label, String value, {bool isHighlight = false}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 130,
          child: Text('$label:', style: const TextStyle(color: Colors.grey, fontSize: 14)),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: isHighlight ? Colors.blue : Colors.black87,
            ),
          ),
        ),
      ],
    ),
  );
}