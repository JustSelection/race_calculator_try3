import '../models/analytics_event_model.dart';
import 'database_helper.dart';

class AnalyticsEventDao {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<int> insert(AnalyticsEventModel event) async {
    try {
      final db = await _dbHelper.database;
      return await db.insert('analytics_events', event.toMap());
    } catch (e) {
      return -1;
    }
  }

  Future<List<AnalyticsEventModel>> getAll() async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'analytics_events',
        orderBy: 'date DESC',
      );
      return List.generate(maps.length, (i) => AnalyticsEventModel.fromMap(maps[i]));
    } catch (e) {
      return [];
    }
  }

  Future<List<AnalyticsEventModel>> getByType(String type) async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'analytics_events',
        where: 'type = ?',
        whereArgs: [type],
        orderBy: 'date DESC',
      );
      return List.generate(maps.length, (i) => AnalyticsEventModel.fromMap(maps[i]));
    } catch (e) {
      return [];
    }
  }

  Future<int> delete(int id) async {
    try {
      final db = await _dbHelper.database;
      return await db.delete(
        'analytics_events',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      return -1;
    }
  }
}