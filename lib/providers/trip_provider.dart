import 'package:flutter/foundation.dart';
import '../models/trip_model.dart';
import '../services/trip_dao.dart';

class TripProvider with ChangeNotifier {
  final TripDao _tripDao = TripDao();
  List<Trip> _trips = [];

  List<Trip> get trips => List.unmodifiable(_trips);

  Future<void> loadTrips(int carId) async {
    _trips = await _tripDao.getTripsByCarId(carId);
    notifyListeners();
  }

  Future<Trip?> getLastTrip(int carId) async {
    return await _tripDao.getLastTripByCarId(carId);
  }

  // ИЗМЕНЕНО: Возвращаем Trip с актуальным ID из БД
  Future<Trip> addTrip(Trip trip) async {
    final newId = await _tripDao.insertTrip(trip);
    final newTrip = trip.copyWith(id: newId);
    _trips.insert(0, newTrip);
    notifyListeners();
    return newTrip;
  }

  Future<void> updateTrip(Trip trip) async {
    await _tripDao.updateTrip(trip);
    final index = _trips.indexWhere((t) => t.id == trip.id);
    if (index != -1) {
      _trips[index] = trip;
      notifyListeners();
    }
  }

  Future<void> deleteTrip(int id) async {
    await _tripDao.deleteTrip(id);
    _trips.removeWhere((trip) => trip.id == id);
    notifyListeners();
  }
}