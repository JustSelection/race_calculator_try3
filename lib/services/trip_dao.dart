import 'package:sqflite/sqflite.dart';
import '../models/trip_model.dart';
import 'database_helper.dart';

class TripDao {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<int> insertTrip(Trip trip) async {
    final Database db = await _dbHelper.database;
    return await db.insert(
      'trips',
      trip.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Trip>> getTripsByCarId(int carId) async {
    final Database db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'trips',
      where: 'carId = ?',
      whereArgs: [carId],
      orderBy: 'date DESC',
    );
    return List.generate(maps.length, (i) => Trip.fromMap(maps[i]));
  }

  Future<Trip?> getLastTripByCarId(int carId) async {
    final Database db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'trips',
      where: 'carId = ?',
      whereArgs: [carId],
      orderBy: 'date DESC',
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return Trip.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateTrip(Trip trip) async {
    final Database db = await _dbHelper.database;
    return await db.update(
      'trips',
      trip.toMap(),
      where: 'id = ?',
      whereArgs: [trip.id],
    );
  }

  Future<int> deleteTrip(int id) async {
    final Database db = await _dbHelper.database;
    return await db.delete(
      'trips',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}