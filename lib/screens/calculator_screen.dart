import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/car_provider.dart';
import '../providers/trip_provider.dart';
import '../providers/calculator_provider.dart';
import '../widgets/calculator_form.dart';
import '../widgets/trip_result_dialog.dart';

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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final calcProv = Provider.of<CalculatorProvider>(context, listen: false);
    final carProv = Provider.of<CarProvider>(context, listen: false);
    final tripProv = Provider.of<TripProvider>(context, listen: false);

    if (calcProv.selectedCar != null) {
      final freshCar = carProv.getCarById(calcProv.selectedCar!.id!);
      if (freshCar != null) {
        final isStale = calcProv.selectedCar!.currentMileage != freshCar.currentMileage ||
                        calcProv.selectedCar!.fuelInTank != freshCar.fuelInTank ||
                        calcProv.selectedCar!.fuelConsumption != freshCar.fuelConsumption;
        if (isStale) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            tripProv.getLastTrip(freshCar.id!).then((lastTrip) {
              if (!mounted) return;
              calcProv.forceRefreshData(freshCar, lastTrip);
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

  void _calculateAndSave() {
    final calc = Provider.of<CalculatorProvider>(context, listen: false);
    final tripProv = Provider.of<TripProvider>(context, listen: false);
    final carProv = Provider.of<CarProvider>(context, listen: false);

    if (int.tryParse(_startMileageCtrl.text) != null) {
      calc.setStartMileage(int.parse(_startMileageCtrl.text));
    }
    if (int.tryParse(_endMileageCtrl.text) != null) {
      calc.setEndMileage(int.parse(_endMileageCtrl.text));
    }
    if (double.tryParse(_fuelDepartureCtrl.text) != null) {
      calc.setFuelAtDeparture(double.parse(_fuelDepartureCtrl.text));
    }
    if (double.tryParse(_refueledCtrl.text) != null) {
      calc.setRefueled(double.parse(_refueledCtrl.text));
    }
    
    calc.calculateAndSave(tripProv, carProv).then((_) {
      if (mounted && calc.isCalculated && calc.result != null) {
        showDialog(
          context: context, 
          barrierDismissible: false, 
          builder: (ctx) => const TripResultDialog(),
        );
      } else if (mounted && calc.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(calc.errorMessage!), backgroundColor: Colors.red),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Калькулятор рейса')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CalculatorForm(
              startMileageCtrl: _startMileageCtrl,
              endMileageCtrl: _endMileageCtrl,
              fuelDepartureCtrl: _fuelDepartureCtrl,
              refueledCtrl: _refueledCtrl,
              onSyncControllers: () => _syncControllers(
                Provider.of<CalculatorProvider>(context, listen: false),
              ),
            ),
            const SizedBox(height: 16),
            Consumer<CalculatorProvider>(
              builder: (ctx, calcProv, _) {
                if (calcProv.errorMessage != null) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16), 
                    child: Text(
                      calcProv.errorMessage!, 
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            const SizedBox(height: 16),
            Consumer<CalculatorProvider>(
              builder: (ctx, calcProv, _) {
                return SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: calcProv.isSaving ? null : _calculateAndSave,
                    child: calcProv.isSaving
                        ? const SizedBox(
                            width: 20, 
                            height: 20, 
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Рассчитать и Сохранить'),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}