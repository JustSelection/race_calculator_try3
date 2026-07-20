import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/car_model.dart';
import '../providers/car_provider.dart';
import '../providers/trip_provider.dart';
import '../providers/calculator_provider.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});
  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  final _startMileageCtrl = TextEditingController();
  final _endMileageCtrl = TextEditingController();
  final _fuelDepartureCtrl = TextEditingController();
  final _refueledCtrl = TextEditingController();

  @override
  void dispose() {
    _startMileageCtrl.dispose();
    _endMileageCtrl.dispose();
    _fuelDepartureCtrl.dispose();
    _refueledCtrl.dispose();
    super.dispose();
  }

  // --- ДОБАВЛЕНО: Автоматическая синхронизация при изменении данных в профиле ---
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    final calcProv = Provider.of<CalculatorProvider>(context, listen: false);
    final carProv = Provider.of<CarProvider>(context, listen: false);
    final tripProv = Provider.of<TripProvider>(context, listen: false);

    if (calcProv.selectedCar != null) {
      final freshCar = carProv.getCarById(calcProv.selectedCar!.id!);
      if (freshCar != null) {
        // Проверяем, устарели ли данные в калькуляторе по сравнению с профилем
        final isStale = calcProv.selectedCar!.currentMileage != freshCar.currentMileage ||
                        calcProv.selectedCar!.fuelInTank != freshCar.fuelInTank ||
                        calcProv.selectedCar!.fuelConsumption != freshCar.fuelConsumption;
        
        if (isStale) {
          // Откладываем обновление до конца текущего кадра сборки, чтобы избежать ошибок Flutter
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            tripProv.getLastTrip(freshCar.id!).then((lastTrip) {
              if (!mounted) return;
              // Жестко обновляем данные в провайдере калькулятора
              calcProv.forceRefreshData(freshCar, lastTrip);
              // Синхронизируем текстовые поля на экране
              _syncControllers(calcProv); 
            });
          });
        }
      }
    }
  }

  void _syncControllers(CalculatorProvider calc) {
    _startMileageCtrl.text = calc.startMileage.toString();
    _endMileageCtrl.text = calc.endMileage.toString();
    _fuelDepartureCtrl.text = calc.fuelAtDeparture.toStringAsFixed(2);
    _refueledCtrl.text = calc.refueled.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Калькулятор рейса')),
      body: Consumer3<CarProvider, TripProvider, CalculatorProvider>(
        builder: (ctx, carProv, tripProv, calcProv, _) {
          if (carProv.cars.isEmpty) {
            return const Center(child: Text('Сначала добавьте автомобиль в профиле'));
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              _buildCarDropdown(ctx, carProv, tripProv, calcProv),
              const SizedBox(height: 16),
              _buildDatePicker(ctx, calcProv),
              const SizedBox(height: 16),
              _buildInput(_startMileageCtrl, 'Начальный пробег (км)'),
              _buildInput(_endMileageCtrl, 'Конечный пробег (км)'),
              _buildInput(_fuelDepartureCtrl, 'Топливо на выезде (л)'),
              _buildInput(_refueledCtrl, 'Заправлено (л)'),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: ElevatedButton(onPressed: _calculate, child: const Text('Рассчитать'))),
                const SizedBox(width: 8),
                Expanded(child: ElevatedButton(
                  onPressed: calcProv.isCalculated && !calcProv.isSaving ? _save : null, 
                  child: calcProv.isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Сохранить'),
                )),
              ]),
              if (calcProv.errorMessage != null) 
                Padding(padding: const EdgeInsets.only(top: 16), child: Text(calcProv.errorMessage!, style: const TextStyle(color: Colors.red))),
              if (calcProv.isCalculated) ...[
                const SizedBox(height: 24),
                _buildResults(calcProv),
              ]
            ]),
          );
        },
      ),
    );
  }

  Widget _buildCarDropdown(BuildContext ctx, CarProvider carProv, TripProvider tripProv, CalculatorProvider calcProv) {
    final Car? selectedCar = calcProv.selectedCar == null 
        ? null 
        : carProv.cars.firstWhere(
            (c) => c.id == calcProv.selectedCar!.id, 
            orElse: () => calcProv.selectedCar!,
          );

    return DropdownButtonFormField<Car>(
      initialValue: selectedCar,
      decoration: const InputDecoration(labelText: 'Автомобиль', border: OutlineInputBorder()),
      items: carProv.cars.map((car) {
        return DropdownMenuItem<Car>(
          value: car,
          child: Text('${car.brand} (${car.licensePlate})'),
        );
      }).toList(),
      onChanged: (car) async {
        if (car != null) {
          await tripProv.loadTrips(car.id!);
          final lastTrip = await tripProv.getLastTrip(car.id!);
          calcProv.initForCar(car, lastTrip);
          _syncControllers(calcProv);
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
      child: InputDecorator(decoration: const InputDecoration(labelText: 'Дата', border: OutlineInputBorder(), suffixIcon: Icon(Icons.calendar_today)), child: Text(DateFormat('dd.MM.yyyy').format(calcProv.tripDate))),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(padding: const EdgeInsets.only(bottom: 12), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: const TextStyle(fontSize: 16)), Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))]));
  }

  Widget _buildInput(TextEditingController ctrl, String label) {
    return Padding(padding: const EdgeInsets.only(bottom: 12), child: TextField(controller: ctrl, decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()), keyboardType: const TextInputType.numberWithOptions(decimal: true)));
  }

  Widget _buildResults(CalculatorProvider calcProv) {
    final r = calcProv.result!;
    return Card(color: Colors.blue.shade50, child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Результат', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      const Divider(),
      _buildInfoRow('Дата:', DateFormat('dd.MM.yyyy').format(calcProv.tripDate)),
      _buildInfoRow('Кон. пробег:', '${calcProv.endMileage} км'),
      _buildInfoRow('Остаток:', '${r.remainingFuel.toStringAsFixed(2)} л'),
      _buildInfoRow('Заправлено:', '${calcProv.refueled.toStringAsFixed(2)} л'),
      const Divider(),
      _buildInfoRow('Дистанция:', '${r.distance} км'),
      _buildInfoRow('Расход (профиль):', '${calcProv.selectedCar!.fuelConsumption.toStringAsFixed(2)} л/100км'),
      _buildInfoRow('Топливо на выезде:', '${calcProv.fuelAtDeparture.toStringAsFixed(2)} л'),
      _buildInfoRow('Затрачено:', '${r.fuelConsumed.toStringAsFixed(2)} л'),
    ])));
  }

  void _calculate() {
    final calc = Provider.of<CalculatorProvider>(context, listen: false);
    if (int.tryParse(_startMileageCtrl.text) != null) {
      calc.setStartMileage(int.parse(_startMileageCtrl.text));
    }
    if (int.tryParse(_endMileageCtrl.text) != null) calc.setEndMileage(int.parse(_endMileageCtrl.text));
    if (double.tryParse(_fuelDepartureCtrl.text) != null) calc.setFuelAtDeparture(double.parse(_fuelDepartureCtrl.text));
    if (double.tryParse(_refueledCtrl.text) != null) calc.setRefueled(double.parse(_refueledCtrl.text));
    calc.calculate();
  }

  Future<void> _save() async {
    final calc = Provider.of<CalculatorProvider>(context, listen: false);
    final tripProv = Provider.of<TripProvider>(context, listen: false);
    final carProv = Provider.of<CarProvider>(context, listen: false);
    await calc.saveTrip(tripProv, carProv);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Рейс успешно сохранен!')));
    }
  }
}