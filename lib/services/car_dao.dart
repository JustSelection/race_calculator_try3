import 'package:sqflite/sqflite.dart';
import '../models/car_model.dart';
import 'database_helper.dart';

class CarDao {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<int> insertCar(Car car) async {
    final Database db = await _dbHelper.database;
    return await db.insert(
      'cars',
      car.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Car>> getAllCars() async {
    final Database db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('cars');
    return List.generate(maps.length, (i) => Car.fromMap(maps[i]));
  }

  Future<int> updateCar(Car car) async {
    final Database db = await _dbHelper.database;
    return await db.update(
      'cars',
      car.toMap(),
      where: 'id = ?',
      whereArgs: [car.id],
    );
  }

  Future<int> deleteCar(int id) async {
    final Database db = await _dbHelper.database;
    return await db.delete(
      'cars',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
