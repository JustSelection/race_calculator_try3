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
  bool get isSaving => _isSaving;

  /// Инициализация калькулятора при выборе авто
  void initForCar(Car car, Trip? lastTrip) {
    _selectedCar = car;
    _tripDate = DateTime.now();
    _applySmartDefaults(car, lastTrip);
    _clearResult();
    notifyListeners();
  }

  /// ЖЕСТКОЕ обновление данных из актуального профиля (вызывается экраном при необходимости)
  void forceRefreshData(Car freshCar, Trip? lastTrip) {
    if (_selectedCar == null || _selectedCar!.id != freshCar.id) return;

    _selectedCar = freshCar;
    _applySmartDefaults(freshCar, lastTrip);
    
    _clearResult(); 
    notifyListeners();
  }

  /// Умная логика автозаполнения: профиль побеждает, если он был изменен вручную
  void _applySmartDefaults(Car car, Trip? lastTrip) {
    // Проверяем, совпадают ли текущие данные авто с концом последнего рейса
    final bool matchesLastTrip = lastTrip != null && 
                                 car.currentMileage == lastTrip.endMileage && 
                                 car.fuelInTank == lastTrip.remainingFuel;

    if (matchesLastTrip) {
      // Стандартный сценарий: продолжаем с того места, где закончили
      _startMileage = lastTrip.endMileage; // <-- ИСПРАВЛЕНО: убран лишний '!'
      _fuelAtDeparture = lastTrip.remainingFuel;
    } else {
      // Сценарий ручной правки: пользователь изменил профиль, берем данные из профиля
      _startMileage = car.currentMileage;
      _fuelAtDeparture = car.fuelInTank;
    }
    
    // Сбрасываем конечные значения на начальные для нового расчета
    _endMileage = _startMileage;
    _refueled = 0.0;
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
    _isSaving = false;
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
    if (_isSaving) return;
    if (!_isCalculated || _result == null || _selectedCar == null) return;

    _isSaving = true;
    notifyListeners();

    try {
      final newTrip = Trip(
        carId: _selectedCar!.id!,
        date: _tripDate,
        startMileage: _startMileage,
        endMileage: _endMileage,
        fuelAtDeparture: _fuelAtDeparture,
        refueled: _refueled,
        remainingFuel: _result!.remainingFuel,
      );

      await tripProvider.addTrip(newTrip);

      final updatedCar = _selectedCar!.copyWith(
        currentMileage: _endMileage,
        fuelInTank: _result!.remainingFuel,
      );
      await carProvider.updateCar(updatedCar);
      
      _selectedCar = updatedCar;
      _clearResult();
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }
}