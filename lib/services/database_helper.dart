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
      version: 3, // УВЕЛИЧЕНО: добавлены новые таблицы
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
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

    await db.execute('''
      CREATE TABLE generators (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        carId INTEGER,
        name TEXT NOT NULL,
        capacity REAL NOT NULL,
        currentFuel REAL NOT NULL,
        FOREIGN KEY (carId) REFERENCES cars (id) ON DELETE SET NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE optimizations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        generatorId INTEGER NOT NULL,
        date TEXT NOT NULL,
        fuelAmount REAL NOT NULL,
        comment TEXT NOT NULL,
        FOREIGN KEY (generatorId) REFERENCES generators (id) ON DELETE CASCADE
      )
    ''');

    // НОВЫЕ ТАБЛИЦЫ для расширенного функционала
    await db.execute('''
      CREATE TABLE refuels (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        totalFuel REAL NOT NULL,
        comment TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE refuel_distribution (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        refuelId INTEGER NOT NULL,
        generatorId INTEGER NOT NULL,
        fuelAmount REAL NOT NULL,
        FOREIGN KEY (refuelId) REFERENCES refuels (id) ON DELETE CASCADE,
        FOREIGN KEY (generatorId) REFERENCES generators (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE inventories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        generatorId INTEGER NOT NULL,
        date TEXT NOT NULL,
        previousFuel REAL NOT NULL,
        actualFuel REAL NOT NULL,
        difference REAL NOT NULL,
        FOREIGN KEY (generatorId) REFERENCES generators (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE calibrations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        comment TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE analytics_events (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        date TEXT NOT NULL,
        description TEXT NOT NULL,
        relatedId INTEGER
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE generators (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          carId INTEGER,
          name TEXT NOT NULL,
          capacity REAL NOT NULL,
          currentFuel REAL NOT NULL,
          FOREIGN KEY (carId) REFERENCES cars (id) ON DELETE SET NULL
        )
      ''');

      await db.execute('''
        CREATE TABLE optimizations (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          generatorId INTEGER NOT NULL,
          date TEXT NOT NULL,
          fuelAmount REAL NOT NULL,
          comment TEXT NOT NULL,
          FOREIGN KEY (generatorId) REFERENCES generators (id) ON DELETE CASCADE
        )
      ''');
    }

    // МИГРАЦИЯ ВЕРСИИ 2 -> 3: добавление новых таблиц
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE refuels (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          date TEXT NOT NULL,
          totalFuel REAL NOT NULL,
          comment TEXT
        )
      ''');

      await db.execute('''
        CREATE TABLE refuel_distribution (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          refuelId INTEGER NOT NULL,
          generatorId INTEGER NOT NULL,
          fuelAmount REAL NOT NULL,
          FOREIGN KEY (refuelId) REFERENCES refuels (id) ON DELETE CASCADE,
          FOREIGN KEY (generatorId) REFERENCES generators (id) ON DELETE CASCADE
        )
      ''');

      await db.execute('''
        CREATE TABLE inventories (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          generatorId INTEGER NOT NULL,
          date TEXT NOT NULL,
          previousFuel REAL NOT NULL,
          actualFuel REAL NOT NULL,
          difference REAL NOT NULL,
          FOREIGN KEY (generatorId) REFERENCES generators (id) ON DELETE CASCADE
        )
      ''');

      await db.execute('''
        CREATE TABLE calibrations (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          date TEXT NOT NULL,
          comment TEXT NOT NULL
        )
      ''');

      await db.execute('''
        CREATE TABLE analytics_events (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          type TEXT NOT NULL,
          date TEXT NOT NULL,
          description TEXT NOT NULL,
          relatedId INTEGER
        )
      ''');
    }
  }
}