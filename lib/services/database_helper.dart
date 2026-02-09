import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/car.dart';
import '../models/fuel_entry.dart';
import '../models/user_settings.dart';
import '../models/developer_note.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    // Versie v5 forceert een nieuwe, schone database
    _database = await _initDB('tank_app_v5.db'); 
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT';
    const numType = 'REAL';
    const intType = 'INTEGER';

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

    // Tabel ENTRIES met juiste kolomnamen (snake_case)
    await db.execute('''
      CREATE TABLE entries (
        id $idType,
        car_id $intType,
        date $textType,
        odometer $numType,
        liters $numType,
        price_total $numType,
        price_per_liter $numType,
        fuel_type $textType,
        FOREIGN KEY (car_id) REFERENCES cars (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE user_settings (
        id $idType,
        first_name $textType,
        theme_mode $textType,
        accent_color $textType, 
        use_greeting $intType,
        show_quotes $intType
      )
    ''');

    await db.execute('''
      CREATE TABLE developer_notes (
        id $idType,
        content $textType,
        date $textType,
        is_completed $intType
      )
    ''');
  }

  // --- CRUD OPERATIONS ---

  Future<int> insertCar(Car car) async {
    final db = await instance.database;
    return await db.insert('cars', car.toMap());
  }

  Future<List<Car>> getAllCars() async {
    final db = await instance.database;
    final result = await db.query('cars');
    return result.map((json) => Car.fromMap(json)).toList();
  }

  Future<int> updateCar(Car car) async {
    final db = await instance.database;
    return await db.update('cars', car.toMap(), where: 'id = ?', whereArgs: [car.id]);
  }

  Future<int> deleteCar(int id) async {
    final db = await instance.database;
    return await db.delete('cars', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> insertEntry(FuelEntry entry) async {
    final db = await instance.database;
    return await db.insert('entries', entry.toMap());
  }

  Future<List<FuelEntry>> getEntriesByCar(int carId) async {
    final db = await instance.database;
    // Query op car_id (snake_case)
    final result = await db.query('entries', where: 'car_id = ?', whereArgs: [carId], orderBy: 'date DESC');
    return result.map((json) => FuelEntry.fromMap(json)).toList();
  }

  Future<int> updateEntry(FuelEntry entry) async {
    final db = await instance.database;
    return await db.update('entries', entry.toMap(), where: 'id = ?', whereArgs: [entry.id]);
  }

  Future<int> deleteEntry(int id) async {
    final db = await instance.database;
    return await db.delete('entries', where: 'id = ?', whereArgs: [id]);
  }

  // --- SETTINGS ---
  Future<UserSettings> getSettings() async {
    final db = await instance.database;
    final maps = await db.query('user_settings', limit: 1);
    if (maps.isNotEmpty) {
      return UserSettings.fromMap(maps.first);
    } else {
      return UserSettings(
        id: 1, 
        firstName: 'Gebruiker', 
        themeMode: 'System', 
        accentColor: 'Mint',
        useGreeting: true, 
        showQuotes: true
      );
    }
  }

  Future<int> saveSettings(UserSettings settings) async {
    final db = await instance.database;
    return await db.insert('user_settings', settings.toMap()..['id'] = 1, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // --- NOTES ---
  Future<int> insertNote(DeveloperNote note) async {
    final db = await instance.database;
    return await db.insert('developer_notes', note.toMap());
  }

  Future<List<DeveloperNote>> getAllNotes() async {
    final db = await instance.database;
    final result = await db.query('developer_notes', orderBy: 'is_completed ASC, date DESC');
    return result.map((json) => DeveloperNote.fromMap(json)).toList();
  }

  Future<int> updateNote(DeveloperNote note) async {
    final db = await instance.database;
    return await db.update('developer_notes', note.toMap(), where: 'id = ?', whereArgs: [note.id]);
  }

  Future<int> deleteNote(int id) async {
    final db = await instance.database;
    return await db.delete('developer_notes', where: 'id = ?', whereArgs: [id]);
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}