import 'package:flutter/material.dart';

class RefuelDistributionHeader extends StatelessWidget {
  final double totalFuel;
  final double oldTotal;
  final double expectedTotal;
  final double newTotalSum;

  const RefuelDistributionHeader({
    super.key,
    required this.totalFuel,
    required this.oldTotal,
    required this.expectedTotal,
    required this.newTotalSum,
  });

  double _round(double value) => double.parse(value.toStringAsFixed(2));

  @override
  Widget build(BuildContext context) {
    final consumption = _round(expectedTotal - newTotalSum);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: Colors.blue.shade50,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('По чеку: +$totalFuel л', style: const TextStyle(fontWeight: FontWeight.bold)),
          Text('Было в системе: $oldTotal л'),
          Text('Ожидалось: $expectedTotal л', style: const TextStyle(fontWeight: FontWeight.bold)),
          const Divider(height: 16),
          Text('Стало (сумма): $newTotalSum л', style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(
            // 🆕 ИЗМЕНЕНО: убрано "/потери" для лаконичности
            'Расчетный расход: $consumption л',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: consumption > 0 ? Colors.red : (consumption < 0 ? Colors.orange : Colors.green),
            ),
          ),
        ],
      ),
    );
  }
}