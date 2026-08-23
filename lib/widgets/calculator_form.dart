import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/car_model.dart';
import '../providers/car_provider.dart';
import '../providers/trip_provider.dart';
import '../providers/calculator_provider.dart';

class CalculatorForm extends StatelessWidget {
  final TextEditingController startMileageCtrl;
  final TextEditingController endMileageCtrl;
  final TextEditingController fuelDepartureCtrl;
  final TextEditingController refueledCtrl;
  final VoidCallback onSyncControllers;

  const CalculatorForm({
    super.key,
    required this.startMileageCtrl,
    required this.endMileageCtrl,
    required this.fuelDepartureCtrl,
    required this.refueledCtrl,
    required this.onSyncControllers,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer3<CarProvider, TripProvider, CalculatorProvider>(
      builder: (ctx, carProv, tripProv, calcProv, _) {
        if (carProv.cars.isEmpty) {
          return const Center(child: Text('Сначала добавьте автомобиль в профиле'));
        }
        return Column(
          children: [
            _buildCarDropdown(ctx, carProv, tripProv, calcProv),
            const SizedBox(height: 16),
            _buildDatePicker(ctx, calcProv),
            const SizedBox(height: 16),
            _buildInput(startMileageCtrl, 'Начальный пробег (км)'),
            _buildInput(endMileageCtrl, 'Конечный пробег (км)'),
            _buildInput(fuelDepartureCtrl, 'Топливо на выезде (л)'),
            _buildInput(refueledCtrl, 'Заправлено (л)'),
          ],
        );
      },
    );
  }

  Widget _buildCarDropdown(BuildContext ctx, CarProvider carProv, TripProvider tripProv, CalculatorProvider calcProv) {
    final Car? selectedCar = calcProv.selectedCar == null 
        ? null 
        : carProv.cars.firstWhere((c) => c.id == calcProv.selectedCar!.id, orElse: () => calcProv.selectedCar!);

    return DropdownButtonFormField<Car>(
      initialValue: selectedCar,
      decoration: const InputDecoration(labelText: 'Автомобиль', border: OutlineInputBorder()),
      items: carProv.cars.map((car) => DropdownMenuItem<Car>(value: car, child: Text('${car.brand} (${car.licensePlate})'))).toList(),
      onChanged: (car) async {
        if (car != null) {
          await tripProv.loadTrips(car.id!);
          final lastTrip = await tripProv.getLastTrip(car.id!);
          calcProv.initForCar(car, lastTrip);
          onSyncControllers();
        }
      },
    );
  }

  Widget _buildDatePicker(BuildContext ctx, CalculatorProvider calcProv) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(context: ctx, initialDate: calcProv.tripDate, firstDate: DateTime(2000), lastDate: DateTime(2100));
        if (picked != null) calcProv.setTripDate(picked);
      },
      child: InputDecorator(
        decoration: const InputDecoration(labelText: 'Дата', border: OutlineInputBorder(), suffixIcon: Icon(Icons.calendar_today)), 
        child: Text(DateFormat('dd.MM.yyyy').format(calcProv.tripDate)),
      ),
    );
  }

  Widget _buildInput(TextEditingController ctrl, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12), 
      child: TextField(
        controller: ctrl, 
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()), 
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
      ),
    );
  }
}