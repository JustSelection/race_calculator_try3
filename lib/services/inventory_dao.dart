import '../models/inventory_model.dart';
import 'database_helper.dart';

class InventoryDao {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<int> insert(InventoryModel inventory) async {
    try {
      final db = await _dbHelper.database;
      return await db.insert('inventories', inventory.toMap());
    } catch (e) {
      return -1;
    }
  }

  Future<List<InventoryModel>> getAll() async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'inventories',
        orderBy: 'date DESC',
      );
      return List.generate(maps.length, (i) => InventoryModel.fromMap(maps[i]));
    } catch (e) {
      return [];
    }
  }

  Future<List<InventoryModel>> getByGeneratorId(int generatorId) async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'inventories',
        where: 'generatorId = ?',
        whereArgs: [generatorId],
        orderBy: 'date DESC',
      );
      return List.generate(maps.length, (i) => InventoryModel.fromMap(maps[i]));
    } catch (e) {
      return [];
    }
  }

  Future<int> delete(int id) async {
    try {
      final db = await _dbHelper.database;
      return await db.delete(
        'inventories',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      return -1;
    }
  }

  // 🆕 ДОБАВЛЕНО: Удаление всех записей инвентаризации (сброс оборота агрегатов при калибровке)
  Future<int> deleteAll() async {
    try {
      final db = await _dbHelper.database;
      return await db.delete('inventories');
    } catch (e) {
      return -1;
    }
  }
}