import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/car.dart';
import '../models/fuel_entry.dart';
import '../models/user_settings.dart';
import '../models/developer_note.dart';
import '../models/maintenance_entry.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('tank_app_v5.db'); 
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 3, // Versie verhoogd voor nieuwe velden
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    print('Database upgrade: v$oldVersion -> v$newVersion');
    
    if (oldVersion < 2) {
      print('Adding maintenance table...');
      await _createMaintenanceTable(db);
    }
    
    if (oldVersion < 3) {
      print('Adding fuel_type and owner columns to cars table...');
      try {
        await db.execute('ALTER TABLE cars ADD COLUMN fuel_type TEXT');
        print('✓ fuel_type column added');
      } catch (e) {
        print('fuel_type column already exists or error: $e');
      }
      
      try {
        await db.execute('ALTER TABLE cars ADD COLUMN owner TEXT');
        print('✓ owner column added');
      } catch (e) {
        print('owner column already exists or error: $e');
      }
    }
    
    print('Database upgrade complete!');
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT';
    const numType = 'REAL';
    const intType = 'INTEGER';

    await db.execute('CREATE TABLE IF NOT EXISTS cars (id $idType, name $textType, license_plate $textType, type $textType, apk_date $textType, insurance $numType, road_tax $numType, road_tax_freq $textType, fuel_type $textType, owner $textType)');
    await db.execute('CREATE TABLE IF NOT EXISTS entries (id $idType, car_id $intType, date $textType, odometer $numType, liters $numType, price_total $numType, price_per_liter $numType, fuel_type $textType, FOREIGN KEY (car_id) REFERENCES cars (id) ON DELETE CASCADE)');
    await db.execute('CREATE TABLE IF NOT EXISTS user_settings (id $idType, first_name $textType, theme_mode $textType, accent_color $textType, use_greeting $intType, show_quotes $intType)');
    await db.execute('CREATE TABLE IF NOT EXISTS developer_notes (id $idType, content $textType, date $textType, is_completed $intType)');
    await _createMaintenanceTable(db);
  }

  Future _createMaintenanceTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS maintenance (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        car_id INTEGER,
        date TEXT,
        odometer REAL,
        type TEXT,
        description TEXT,
        cost REAL,
        FOREIGN KEY (car_id) REFERENCES cars (id) ON DELETE CASCADE
      )
    ''');
  }

  // --- CARS ---
  Future<int> insertCar(Car car) async { 
    final db = await database; 
    print('Inserting car: ${car.name} (${car.licensePlate})');
    return await db.insert('cars', car.toMap()); 
  }
  
  Future<List<Car>> getAllCars() async { 
    final db = await database; 
    final result = await db.query('cars');
    print('getAllCars: Found ${result.length} cars in database');
    
    if (result.isEmpty) {
      print('⚠ Database is leeg - geen auto\'s gevonden!');
      return [];
    }
    
    try {
      final cars = result.map((json) {
        print('  - Loading car: ${json['name']} (${json['license_plate']})');
        return Car.fromMap(json);
      }).toList();
      print('✓ Successfully loaded ${cars.length} cars');
      return cars;
    } catch (e) {
      print('❌ Error loading cars: $e');
      rethrow;
    }
  }
  
  Future<int> updateCar(Car car) async { final db = await database; return await db.update('cars', car.toMap(), where: 'id = ?', whereArgs: [car.id]); }
  Future<int> deleteCar(int id) async { final db = await database; return await db.delete('cars', where: 'id = ?', whereArgs: [id]); }

  // --- ENTRIES ---
  Future<int> insertEntry(FuelEntry entry) async { final db = await database; return await db.insert('entries', entry.toMap()); }
  Future<List<FuelEntry>> getEntriesByCar(int carId) async { final db = await database; final result = await db.query('entries', where: 'car_id = ?', whereArgs: [carId], orderBy: 'date DESC'); return result.map((json) => FuelEntry.fromMap(json)).toList(); }
  Future<int> updateEntry(FuelEntry entry) async { final db = await database; return await db.update('entries', entry.toMap(), where: 'id = ?', whereArgs: [entry.id]); }
  Future<int> deleteEntry(int id) async { final db = await database; return await db.delete('entries', where: 'id = ?', whereArgs: [id]); }
  Future<int> deleteEntriesByCar(int carId) async { final db = await database; return await db.delete('entries', where: 'car_id = ?', whereArgs: [carId]); }

  // --- MAINTENANCE ---
  Future<int> insertMaintenance(MaintenanceEntry entry) async { final db = await database; return await db.insert('maintenance', entry.toMap()); }
  Future<List<MaintenanceEntry>> getMaintenanceByCar(int carId) async { final db = await database; final result = await db.query('maintenance', where: 'car_id = ?', whereArgs: [carId], orderBy: 'date DESC'); return result.map((json) => MaintenanceEntry.fromMap(json)).toList(); }
  Future<int> updateMaintenance(MaintenanceEntry entry) async { final db = await database; return await db.update('maintenance', entry.toMap(), where: 'id = ?', whereArgs: [entry.id]); }
  Future<int> deleteMaintenance(int id) async { final db = await database; return await db.delete('maintenance', where: 'id = ?', whereArgs: [id]); }

  // --- NOTES ---
  Future<int> insertNote(DeveloperNote note) async { final db = await database; return await db.insert('developer_notes', note.toMap()); }
  Future<List<DeveloperNote>> getAllNotes() async { final db = await database; final result = await db.query('developer_notes', orderBy: 'is_completed ASC, date DESC'); return result.map((json) => DeveloperNote.fromMap(json)).toList(); }
  Future<int> updateNote(DeveloperNote note) async { final db = await database; return await db.update('developer_notes', note.toMap(), where: 'id = ?', whereArgs: [note.id]); }
  Future<int> deleteNote(int id) async { final db = await database; return await db.delete('developer_notes', where: 'id = ?', whereArgs: [id]); }

  // --- SETTINGS ---
  Future<UserSettings> getSettings() async { final db = await database; final maps = await db.query('user_settings', limit: 1); return maps.isNotEmpty ? UserSettings.fromMap(maps.first) : UserSettings(id: 1, firstName: 'Gebruiker', themeMode: 'System', accentColor: 'Mint', useGreeting: true, showQuotes: true); }
  
  // FIXED: Syntax error corrected here (removed triple dot)
  Future<int> saveSettings(UserSettings settings) async { 
    final db = await database; 
    return await db.insert('user_settings', settings.toMap()..['id'] = 1, conflictAlgorithm: ConflictAlgorithm.replace); 
  }

  Future<void> deleteAllData() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('entries');
      await txn.delete('cars');
      await txn.delete('maintenance');
      await txn.delete('developer_notes');
      await txn.delete('user_settings');
    });
  }
}