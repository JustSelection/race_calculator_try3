import '../models/optimization_model.dart';
import 'database_helper.dart';

class OptimizationDao {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<int> insert(OptimizationModel optimization) async {
    try {
      final db = await _dbHelper.database;
      return await db.insert('optimizations', optimization.toMap());
    } catch (e) {
      return -1;
    }
  }

  Future<List<OptimizationModel>> getAll() async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'optimizations',
        orderBy: 'date DESC',
      );
      return List.generate(maps.length, (i) => OptimizationModel.fromMap(maps[i]));
    } catch (e) {
      return [];
    }
  }

  Future<List<OptimizationModel>> getByGeneratorId(int generatorId) async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'optimizations',
        where: 'generatorId = ?',
        whereArgs: [generatorId],
        orderBy: 'date DESC',
      );
      return List.generate(maps.length, (i) => OptimizationModel.fromMap(maps[i]));
    } catch (e) {
      return [];
    }
  }

  Future<double> getSumForWeek() async {
    try {
      final db = await _dbHelper.database;
      final weekAgo = DateTime.now().subtract(const Duration(days: 7)).toIso8601String();
      
      final result = await db.rawQuery(
        'SELECT SUM(fuelAmount) as total FROM optimizations WHERE date >= ?',
        [weekAgo],
      );
      
      if (result.isNotEmpty && result.first['total'] != null) {
        return (result.first['total'] as num).toDouble();
      }
      return 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  Future<double> getSumForMonth() async {
    try {
      final db = await _dbHelper.database;
      final monthAgo = DateTime.now().subtract(const Duration(days: 30)).toIso8601String();
      
      final result = await db.rawQuery(
        'SELECT SUM(fuelAmount) as total FROM optimizations WHERE date >= ?',
        [monthAgo],
      );
      
      if (result.isNotEmpty && result.first['total'] != null) {
        return (result.first['total'] as num).toDouble();
      }
      return 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  Future<int> delete(int id) async {
    try {
      final db = await _dbHelper.database;
      return await db.delete(
        'optimizations',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      return -1;
    }
  }

  // 🆕 ДОБАВЛЕНО: Удаление всех записей оптимизации (используется при глобальной калибровке)
  Future<int> deleteAll() async {
    try {
      final db = await _dbHelper.database;
      return await db.delete('optimizations');
    } catch (e) {
      return -1;
    }
  }
}