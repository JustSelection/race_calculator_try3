import '../models/generator_model.dart';
import 'database_helper.dart';

class GeneratorDao {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<int> insert(GeneratorModel generator) async {
    try {
      final db = await _dbHelper.database;
      return await db.insert('generators', generator.toMap());
    } catch (e) {
      return -1;
    }
  }

  Future<List<GeneratorModel>> getAll() async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query('generators');
      return List.generate(maps.length, (i) => GeneratorModel.fromMap(maps[i]));
    } catch (e) {
      return [];
    }
  }

  Future<GeneratorModel?> getById(int id) async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'generators',
        where: 'id = ?',
        whereArgs: [id],
      );
      if (maps.isNotEmpty) {
        return GeneratorModel.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<List<GeneratorModel>> getByCarId(int carId) async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'generators',
        where: 'carId = ?',
        whereArgs: [carId],
      );
      return List.generate(maps.length, (i) => GeneratorModel.fromMap(maps[i]));
    } catch (e) {
      return [];
    }
  }

  Future<int> update(GeneratorModel generator) async {
    try {
      final db = await _dbHelper.database;
      return await db.update(
        'generators',
        generator.toMap(),
        where: 'id = ?',
        whereArgs: [generator.id],
      );
    } catch (e) {
      return -1;
    }
  }

  Future<int> updateFuel(int id, double newFuel) async {
    try {
      final db = await _dbHelper.database;
      return await db.update(
        'generators',
        {'currentFuel': newFuel},
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      return -1;
    }
  }

  Future<int> delete(int id) async {
    try {
      final db = await _dbHelper.database;
      return await db.delete(
        'generators',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      return -1;
    }
  }
}