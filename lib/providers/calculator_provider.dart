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
  bool _isSaving = false;

  // Для отмены последнего сохранения
  Trip? _lastSavedTrip;
  Car? _carStateBeforeSave;

  Car? get selectedCar => _selectedCar;
  DateTime get tripDate => _tripDate;
  int get startMileage => _startMileage;
  int get endMileage => _endMileage;
  double get fuelAtDeparture => _fuelAtDeparture;
  double get refueled => _refueled;
  CalculationResult? get result => _result;
  String? get errorMessage => _errorMessage;
  bool get isCalculated => _isCalculated;
  bool get isSaving => _isSaving;
  bool get canUndo => _lastSavedTrip != null;

  void initForCar(Car car, Trip? lastTrip) {
    _selectedCar = car;
    _tripDate = DateTime.now();
    _applySmartDefaults(car, lastTrip);
    _clearResult();
    notifyListeners();
  }

  void forceRefreshData(Car freshCar, Trip? lastTrip) {
    if (_selectedCar == null || _selectedCar!.id != freshCar.id) return;
    _selectedCar = freshCar;
    _applySmartDefaults(freshCar, lastTrip);
    _clearResult(); 
    notifyListeners();
  }

  void _applySmartDefaults(Car car, Trip? lastTrip) {
    final bool matches = lastTrip != null && car.currentMileage == lastTrip.endMileage && car.fuelInTank == lastTrip.remainingFuel;
    if (matches) {
      _startMileage = lastTrip.endMileage;
      _fuelAtDeparture = lastTrip.remainingFuel;
    } else {
      _startMileage = car.currentMileage;
      _fuelAtDeparture = car.fuelInTank;
    }
    _endMileage = _startMileage;
    _refueled = 0.0;
  }

  void setTripDate(DateTime v) { _tripDate = v; _clearResult(); notifyListeners(); }
  void setStartMileage(int v) { _startMileage = v; _clearResult(); notifyListeners(); }
  void setEndMileage(int v) { _endMileage = v; _clearResult(); notifyListeners(); }
  void setFuelAtDeparture(double v) { _fuelAtDeparture = v; _clearResult(); notifyListeners(); }
  void setRefueled(double v) { _refueled = v; _clearResult(); notifyListeners(); }

  void _clearResult() {
    _result = null; _errorMessage = null; _isCalculated = false; _isSaving = false;
  }

  void calculate() {
    if (_selectedCar == null) { _errorMessage = 'Сначала выберите автомобиль'; notifyListeners(); return; }
    try {
      _result = CalculationService.calculate(
        startMileage: _startMileage, endMileage: _endMileage,
        fuelAtDeparture: _fuelAtDeparture, refueled: _refueled,
        fuelConsumption: _selectedCar!.fuelConsumption,
      );
      _errorMessage = null; _isCalculated = true;
    } on CalculationException catch (e) {
      _errorMessage = e.message; _result = null; _isCalculated = false;
    }
    notifyListeners();
  }

  Future<void> calculateAndSave(TripProvider tripProvider, CarProvider carProvider) async {
    calculate();
    if (_isCalculated && _result != null && _selectedCar != null) {
      await saveTrip(tripProvider, carProvider);
    }
  }

  Future<void> saveTrip(TripProvider tripProvider, CarProvider carProvider) async {
    if (_isSaving || !_isCalculated || _result == null || _selectedCar == null) return;
    _isSaving = true; notifyListeners();
    try {
      _carStateBeforeSave = _selectedCar;
      final newTrip = Trip(
        carId: _selectedCar!.id!, date: _tripDate, startMileage: _startMileage,
        endMileage: _endMileage, fuelAtDeparture: _fuelAtDeparture,
        refueled: _refueled, remainingFuel: _result!.remainingFuel,
      );
      
      // ИСПРАВЛЕНО: сохраняем объект, который уже имеет ID из БД
      _lastSavedTrip = await tripProvider.addTrip(newTrip);

      final updatedCar = _selectedCar!.copyWith(currentMileage: _endMileage, fuelInTank: _result!.remainingFuel);
      await carProvider.updateCar(updatedCar);
      _selectedCar = updatedCar;
    } finally {
      _isSaving = false; notifyListeners();
    }
  }

  Future<void> undoLastSave(TripProvider tripProvider, CarProvider carProvider) async {
    // ИСПРАВЛЕНО: безопасная проверка ID и try-finally для гарантии сброса состояния
    if (_lastSavedTrip?.id == null || _carStateBeforeSave == null) return;
    try {
      await tripProvider.deleteTrip(_lastSavedTrip!.id!);
      await carProvider.updateCar(_carStateBeforeSave!);
      _selectedCar = _carStateBeforeSave;
    } finally {
      _lastSavedTrip = null; 
      _carStateBeforeSave = null;
      _clearResult(); 
      notifyListeners();
    }
  }

  void resetForNewCalculation() {
    _clearResult();
    if (_selectedCar != null) {
      _startMileage = _selectedCar!.currentMileage;
      _endMileage = _startMileage;
      _fuelAtDeparture = _selectedCar!.fuelInTank;
      _refueled = 0.0;
    }
    notifyListeners();
  }
}