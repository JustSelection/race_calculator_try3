import 'package:flutter/foundation.dart';
import '../models/car_model.dart';
import '../services/car_dao.dart';

class CarProvider with ChangeNotifier {
  final CarDao _carDao = CarDao();
  List<Car> _cars = [];

  List<Car> get cars => List.unmodifiable(_cars);

  Car? getCarById(int id) {
    try {
      return _cars.firstWhere((car) => car.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> loadCars() async {
    _cars = await _carDao.getAllCars();
    notifyListeners();
  }

  Future<void> addCar(Car car) async {
    final newId = await _carDao.insertCar(car);
    final newCar = car.copyWith(id: newId);
    _cars.add(newCar);
    notifyListeners();
  }

  Future<void> updateCar(Car car) async {
    await _carDao.updateCar(car);
    final index = _cars.indexWhere((c) => c.id == car.id);
    if (index != -1) {
      _cars[index] = car;
      notifyListeners();
    }
  }

  Future<void> deleteCar(int id) async {
    await _carDao.deleteCar(id);
    _cars.removeWhere((car) => car.id == id);
    notifyListeners();
  }
}