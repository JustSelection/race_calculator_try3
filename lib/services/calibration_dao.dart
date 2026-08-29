import '../models/calibration_model.dart';
import 'database_helper.dart';

class CalibrationDao {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<int> insert(CalibrationModel calibration) async {
    try {
      final db = await _dbHelper.database;
      return await db.insert('calibrations', calibration.toMap());
    } catch (e) {
      return -1;
    }
  }

  Future<List<CalibrationModel>> getAll() async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'calibrations',
        orderBy: 'date DESC',
      );
      return List.generate(maps.length, (i) => CalibrationModel.fromMap(maps[i]));
    } catch (e) {
      return [];
    }
  }

  Future<int> delete(int id) async {
    try {
      final db = await _dbHelper.database;
      return await db.delete(
        'calibrations',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      return -1;
    }
  }
}