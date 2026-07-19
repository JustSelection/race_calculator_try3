import 'package:flutter/foundation.dart';
import '../models/car_model.dart';
import '../models/trip_model.dart';
import '../services/calculation_service.dart';
import 'car_provider.dart';
import 'trip_provider.dart';

class CalculatorProvider with ChangeNotifier {
  Car? _selectedCar;
  DateTime _tripDate = DateTime.now();
  int _startMileage = 0;
  int _endMileage = 0;
  double _fuelAtDeparture = 0.0;
  double _refueled = 0.0;
  
  CalculationResult? _result;
  String? _errorMessage;
  bool _isCalculated = false;

  // Getters
  Car? get selectedCar => _selectedCar;
  DateTime get tripDate => _tripDate;
  int get startMileage => _startMileage;
  int get endMileage => _endMileage;
  double get fuelAtDeparture => _fuelAtDeparture;
  double get refueled => _refueled;
  CalculationResult? get result => _result;
  String? get errorMessage => _errorMessage;
  bool get isCalculated => _isCalculated;

  /// Инициализация калькулятора при выборе авто
  void initForCar(Car car, Trip? lastTrip) {
    _selectedCar = car;
    _tripDate = DateTime.now();
    _startMileage = lastTrip?.endMileage ?? car.currentMileage;
    _endMileage = _startMileage;
    _fuelAtDeparture = lastTrip?.remainingFuel ?? car.fuelInTank;
    _refueled = 0.0;
    _clearResult();
    notifyListeners();
  }

  // Сеттеры с очисткой результата при изменении вводных
  void setTripDate(DateTime value) { _tripDate = value; _clearResult(); notifyListeners(); }
  void setStartMileage(int value) { _startMileage = value; _clearResult(); notifyListeners(); }
  void setEndMileage(int value) { _endMileage = value; _clearResult(); notifyListeners(); }
  void setFuelAtDeparture(double value) { _fuelAtDeparture = value; _clearResult(); notifyListeners(); }
  void setRefueled(double value) { _refueled = value; _clearResult(); notifyListeners(); }

  void _clearResult() {
    _result = null;
    _errorMessage = null;
    _isCalculated = false;
  }

  /// Запуск расчета через защищенный сервис
  void calculate() {
    if (_selectedCar == null) {
      _errorMessage = 'Сначала выберите автомобиль';
      notifyListeners();
      return;
    }
    try {
      _result = CalculationService.calculate(
        startMileage: _startMileage,
        endMileage: _endMileage,
        fuelAtDeparture: _fuelAtDeparture,
        refueled: _refueled,
        fuelConsumption: _selectedCar!.fuelConsumption,
      );
      _errorMessage = null;
      _isCalculated = true;
    } on CalculationException catch (e) {
      _errorMessage = e.message;
      _result = null;
      _isCalculated = false;
    }
    notifyListeners();
  }

  /// Сохранение рейса и обновление профиля авто
  Future<void> saveTrip(TripProvider tripProvider, CarProvider carProvider) async {
    if (!_isCalculated || _result == null || _selectedCar == null) return;

    final newTrip = Trip(
      carId: _selectedCar!.id!,
      date: _tripDate,
      startMileage: _startMileage,
      endMileage: _endMileage,
      fuelAtDeparture: _fuelAtDeparture,
      refueled: _refueled,
      remainingFuel: _result!.remainingFuel,
    );

    // 1. Сохраняем рейс
    await tripProvider.addTrip(newTrip);

    // 2. Обновляем текущий пробег и остаток топлива в профиле авто
    final updatedCar = _selectedCar!.copyWith(
      currentMileage: _endMileage,
      fuelInTank: _result!.remainingFuel,
    );
    await carProvider.updateCar(updatedCar);
    
    _selectedCar = updatedCar;
    notifyListeners();
  }
}