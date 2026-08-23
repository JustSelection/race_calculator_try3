import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/calculator_provider.dart';
import '../providers/car_provider.dart';
import '../providers/trip_provider.dart';

class TripResultDialog extends StatefulWidget {
  const TripResultDialog({super.key});

  @override
  State<TripResultDialog> createState() => _TripResultDialogState();
}

class _TripResultDialogState extends State<TripResultDialog> {
  bool _isUndoing = false;
  // ignore: prefer_final_fields
  bool _isUndone = false;

  void _closeAndReset() {
    final calcProv = Provider.of<CalculatorProvider>(context, listen: false);
    calcProv.resetForNewCalculation();
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _undoSave() async {
    if (_isUndone) return; // Идемпотентность: повторные нажатия игнорируются
    setState(() => _isUndoing = true);
    
    final calcProv = Provider.of<CalculatorProvider>(context, listen: false);
    final tripProv = Provider.of<TripProvider>(context, listen: false);
    final carProv = Provider.of<CarProvider>(context, listen: false);

    try {
      await calcProv.undoLastSave(tripProv, carProv);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Рейс отменен и удален из истории')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка при отмене: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      // ИНТЕГРИРОВАНО: Сброс и явное закрытие диалога для устранения "серого экрана"
      if (mounted) {
        calcProv.resetForNewCalculation();
        Navigator.of(context).pop();
      }
    }
  }

  Widget _buildRow(String label, String value, {bool isHighlighted = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label, 
            style: TextStyle(
              color: isHighlighted ? Colors.black87 : Colors.grey,
              fontSize: isHighlighted ? 16 : 14,
              fontWeight: isHighlighted ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          Text(
            value, 
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: isHighlighted ? 18 : 15,
              color: isHighlighted ? Colors.blue.shade800 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final calc = context.watch<CalculatorProvider>();
    final r = calc.result;
    
    if (r == null || calc.selectedCar == null) return const SizedBox.shrink();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Результат рейса', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _closeAndReset,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Закрыть и начать новый расчет',
                ),
              ],
            ),
            const Divider(height: 24),
            
            // --- ОСНОВНЫЕ ВЫДЕЛЕННЫЕ ПУНКТЫ ---
            _buildRow('Конечный пробег:', '${calc.endMileage} км', isHighlighted: true),
            _buildRow('Остаток топлива:', '${r.remainingFuel} л', isHighlighted: true),
            _buildRow('Заправлено:', '${calc.refueled} л', isHighlighted: true),
            
            const Divider(height: 32),
            
            // --- ДЕТАЛИ ---
            _buildRow('Дата:', DateFormat('dd.MM.yyyy').format(calc.tripDate)),
            _buildRow('Дистанция:', '${r.distance} км'),
            _buildRow('Расход (профиль):', '${calc.selectedCar!.fuelConsumption} л/100км'),
            _buildRow('Топливо на выезде:', '${calc.fuelAtDeparture} л'),
            _buildRow('Затрачено:', '${r.fuelConsumed} л'),
            
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isUndone ? null : _undoSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isUndone ? Colors.grey : const Color.fromARGB(255, 155, 66, 66),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _isUndoing 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(_isUndone ? 'Рейс отменен' : 'Не сохранять'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}