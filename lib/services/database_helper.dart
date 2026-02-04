import 'dart:async';
import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../data_provider.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('tankbuddy_v3.db'); // Naam iets veranderd om verse start te forceren als je wilt
    return _database!;
  }

  Future<String> getDbPath() async {
    final dbPath = await getDatabasesPath();
    return join(dbPath, 'tankbuddy_v3.db');
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 2, onCreate: _createDB, onUpgrade: _onUpgrade);
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT';
    const numType = 'REAL';

    // AUTO TABEL (AANGEPAST MET NIEUWE VELDEN)
    await db.execute('''
      CREATE TABLE cars (
        id $idType,
        name $textType,
        license_plate $textType,
        type $textType,
        apk_date $textType,
        insurance $numType,
        road_tax $numType,
        road_tax_freq $textType
      )
    ''');

    await db.execute('''
      CREATE TABLE entries (
        id $idType,
        car_id INTEGER,
        date $textType,
        odometer $numType,
        liters $numType,
        price_total $numType,
        price_per_liter $numType
      )
    ''');

    await db.execute('''
      CREATE TABLE user_settings (
        id $idType,
        first_name $textType,
        theme_mode $textType,
        use_greeting INTEGER,
        show_quotes INTEGER
      )
    ''');
    
    // Default user record
    await db.insert('user_settings', {'first_name': 'Bestuurder', 'theme_mode': 'system', 'use_greeting': 1, 'show_quotes': 1});
  }

  // Eenvoudige upgrade logica: als je een oude app hebt, voegt hij de kolommen toe zonder dataverlies
  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      try {
        await db.execute("ALTER TABLE cars ADD COLUMN insurance REAL");
        await db.execute("ALTER TABLE cars ADD COLUMN road_tax REAL");
        await db.execute("ALTER TABLE cars ADD COLUMN road_tax_freq TEXT");
      } catch (e) {
        // Kolommen bestaan misschien al, negeer
      }
    }
  }

  // --- CRUD CARS ---
  Future<List<Car>> getCars() async {
    final db = await instance.database;
    final result = await db.query('cars');
    return result.map((json) => Car.fromMap(json)).toList();
  }

  Future<int> addCar(Car car) async {
    final db = await instance.database;
    return await db.insert('cars', car.toMap());
  }

  Future<int> updateCar(Car car) async {
    final db = await instance.database;
    return await db.update('cars', car.toMap(), where: 'id = ?', whereArgs: [car.id]);
  }

  Future<int> deleteCar(int id) async {
    final db = await instance.database;
    await db.delete('entries', where: 'car_id = ?', whereArgs: [id]); // Cascade delete entries
    return await db.delete('cars', where: 'id = ?', whereArgs: [id]);
  }

  // --- CRUD ENTRIES ---
  Future<List<Map<String, dynamic>>> getEntries() async {
    final db = await instance.database;
    return await db.query('entries');
  }

  Future<int> addEntry(Map<String, dynamic> entry) async {
    final db = await instance.database;
    return await db.insert('entries', entry);
  }

  Future<int> deleteEntry(int id) async {
    final db = await instance.database;
    return await db.delete('entries', where: 'id = ?', whereArgs: [id]);
  }
  
  Future<void> clearAllData() async {
    final db = await instance.database;
    await db.delete('entries');
    await db.delete('cars');
    // User settings resetten we liever niet helemaal, of wel:
    // await db.delete('user_settings'); 
    // await db.insert('user_settings', {'first_name': 'Bestuurder', 'theme_mode': 'system', 'use_greeting': 1, 'show_quotes': 1});
  }

  // --- USER SETTINGS ---
  Future<Map<String, dynamic>> getUserSettings() async {
    final db = await instance.database;
    final res = await db.query('user_settings');
    if (res.isNotEmpty) return res.first;
    return {};
  }

  Future<int> updateUser(Map<String, dynamic> updates) async {
    final db = await instance.database;
    return await db.update('user_settings', updates, where: 'id = ?', whereArgs: [1]); // Altijd row 1
  }

  // --- RESTORE ---
  Future<void> restoreBackup(String path) async {
    final dbPath = await getDbPath();
    // Sluit huidige connectie
    if (_database != null && _database!.isOpen) {
      await _database!.close();
      _database = null;
    }
    // Overschrijf bestand
    await File(path).copy(dbPath);
    // Heropen
    _database = await _initDB('tankbuddy_v3.db');
  }
}