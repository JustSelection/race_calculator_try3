import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/car_model.dart';
import '../models/trip_model.dart';
import '../providers/trip_provider.dart';
import '../providers/car_provider.dart';
import '../services/calculation_service.dart';

class TripDetailsScreen extends StatefulWidget {
  final Trip trip;
  final Car car;

  const TripDetailsScreen({super.key, required this.trip, required this.car});

  @override
  State<TripDetailsScreen> createState() => _TripDetailsScreenState();
}

class _TripDetailsScreenState extends State<TripDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _startCtrl;
  late TextEditingController _endCtrl;
  late TextEditingController _fuelDepCtrl;
  late TextEditingController _refueledCtrl;
  late DateTime _date;

  @override
  void initState() {
    super.initState();
    _date = widget.trip.date;
    _startCtrl = TextEditingController(text: widget.trip.startMileage.toString());
    _endCtrl = TextEditingController(text: widget.trip.endMileage.toString());
    _fuelDepCtrl = TextEditingController(text: widget.trip.fuelAtDeparture.toStringAsFixed(2));
    _refueledCtrl = TextEditingController(text: widget.trip.refueled.toStringAsFixed(2));
  }

  @override
  void dispose() {
    _startCtrl.dispose();
    _endCtrl.dispose();
    _fuelDepCtrl.dispose();
    _refueledCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final start = int.parse(_startCtrl.text);
      final end = int.parse(_endCtrl.text);
      final fuelDep = double.parse(_fuelDepCtrl.text);
      final refueled = double.parse(_refueledCtrl.text);

      // Пересчитываем через надежный сервис
      final result = CalculationService.calculate(
        startMileage: start,
        endMileage: end,
        fuelAtDeparture: fuelDep,
        refueled: refueled,
        fuelConsumption: widget.car.fuelConsumption,
      );

      final updatedTrip = widget.trip.copyWith(
        date: _date,
        startMileage: start,
        endMileage: end,
        fuelAtDeparture: fuelDep,
        refueled: refueled,
        remainingFuel: result.remainingFuel,
      );

      final tripProv = Provider.of<TripProvider>(context, listen: false);
      await tripProv.updateTrip(updatedTrip);

      // 1-я защита: прерываем, если виджет удален во время сохранения
      if (!mounted) return;

      final lastTrip = await tripProv.getLastTrip(widget.car.id!);

      // 2-я защита: прерываем перед использованием context после второго await
      if (!mounted) return;

      if (lastTrip != null && lastTrip.id == updatedTrip.id) {
        final carProv = Provider.of<CarProvider>(context, listen: false);
        final updatedCar = widget.car.copyWith(
          currentMileage: updatedTrip.endMileage,
          fuelInTank: updatedTrip.remainingFuel,
        );
        await carProv.updateCar(updatedCar);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Рейс обновлен')));
      }
    } on CalculationException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ошибка ввода данных'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Детали рейса')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) setState(() => _date = picked);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Дата', border: OutlineInputBorder(), suffixIcon: Icon(Icons.calendar_today)),
                  child: Text(DateFormat('dd.MM.yyyy').format(_date)),
                ),
              ),
              const SizedBox(height: 16),
              _buildIntField(_startCtrl, 'Начальный пробег (км)'),
              _buildIntField(_endCtrl, 'Конечный пробег (км)'),
              _buildDoubleField(_fuelDepCtrl, 'Топливо на выезде (л)'),
              _buildDoubleField(_refueledCtrl, 'Заправлено (л)'),
              const SizedBox(height: 24),
              SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _save, child: const Text('Сохранить изменения'))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIntField(TextEditingController ctrl, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctrl,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        keyboardType: TextInputType.number,
        validator: (v) => (v == null || int.tryParse(v) == null) ? 'Введите целое число' : null,
      ),
    );
  }

  Widget _buildDoubleField(TextEditingController ctrl, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctrl,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        validator: (v) => (v == null || double.tryParse(v) == null) ? 'Введите число' : null,
      ),
    );
  }
}