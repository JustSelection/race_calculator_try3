import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'mileage_calculator.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE cars (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        brand TEXT NOT NULL,
        licensePlate TEXT NOT NULL,
        fuelConsumption REAL NOT NULL,
        currentMileage INTEGER NOT NULL,
        fuelInTank REAL NOT NULL,
        tankCapacity REAL NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE trips (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        carId INTEGER NOT NULL,
        date TEXT NOT NULL,
        startMileage INTEGER NOT NULL,
        endMileage INTEGER NOT NULL,
        fuelAtDeparture REAL NOT NULL,
        refueled REAL NOT NULL,
        remainingFuel REAL NOT NULL,
        FOREIGN KEY (carId) REFERENCES cars (id) ON DELETE CASCADE
      )
    ''');
  }
}