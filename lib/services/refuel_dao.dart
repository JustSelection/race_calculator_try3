import '../models/refuel_model.dart';
import 'database_helper.dart';

class RefuelDao {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<int> insert(RefuelModel refuel) async {
    try {
      final db = await _dbHelper.database;
      return await db.insert('refuels', refuel.toMap());
    } catch (e) {
      return -1;
    }
  }

  Future<List<RefuelModel>> getAll() async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'refuels',
        orderBy: 'date DESC',
      );
      return List.generate(maps.length, (i) => RefuelModel.fromMap(maps[i]));
    } catch (e) {
      return [];
    }
  }

  Future<int> insertDistribution(Map<String, dynamic> distribution) async {
    try {
      final db = await _dbHelper.database;
      return await db.insert('refuel_distribution', distribution);
    } catch (e) {
      return -1;
    }
  }

  Future<List<Map<String, dynamic>>> getDistributionByRefuelId(int refuelId) async {
    try {
      final db = await _dbHelper.database;
      return await db.query(
        'refuel_distribution',
        where: 'refuelId = ?',
        whereArgs: [refuelId],
      );
    } catch (e) {
      return [];
    }
  }

  Future<int> delete(int id) async {
    try {
      final db = await _dbHelper.database;
      return await db.delete(
        'refuels',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      return -1;
    }
  }

  // 🆕 ДОБАВЛЕНО: Удаление всех записей заправок (для полного сброса оборота в аналитике)
  Future<int> deleteAll() async {
    try {
      final db = await _dbHelper.database;
      // Сначала очищаем таблицу распределения, затем основную таблицу для чистоты
      await db.delete('refuel_distribution');
      return await db.delete('refuels');
    } catch (e) {
      return -1;
    }
  }
}