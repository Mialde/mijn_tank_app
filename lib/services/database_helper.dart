import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class Car {
  final int? id;
  String name;
  String? licensePlate;
  String? apkDate;
  String type; // Nieuw: auto, motor, scooter, etc.

  Car({
    this.id, 
    required this.name, 
    this.licensePlate, 
    this.apkDate,
    this.type = 'auto' // Standaard is het een auto
  });

  Map<String, dynamic> toMap() => {
    'id': id, 
    'name': name, 
    'license_plate': licensePlate, 
    'apk_date': apkDate,
    'type': type
  };

  factory Car.fromMap(Map<String, dynamic> map) => Car(
    id: map['id'], 
    name: map['name'] ?? '', 
    licensePlate: map['license_plate'], 
    apkDate: map['apk_date'],
    type: map['type'] ?? 'auto'
  );
}

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('tankbuddy_v45.db'); // Versienummer iets opgehoogd voor verse start
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getApplicationDocumentsDirectory();
    return await openDatabase(join(dbPath.path, filePath), version: 1, onCreate: (db, v) async {
      // Tabel aangepast met 'type' kolom
      await db.execute('CREATE TABLE cars (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, license_plate TEXT, apk_date TEXT, type TEXT)');
      await db.execute('CREATE TABLE user_settings (id INTEGER PRIMARY KEY, first_name TEXT, theme_mode TEXT, use_greeting INTEGER, show_quotes INTEGER, greeting_type TEXT)');
      await db.execute('CREATE TABLE entries (id INTEGER PRIMARY KEY AUTOINCREMENT, car_id INTEGER, date TEXT, odometer REAL, liters REAL, price_total REAL)');
      await db.insert('user_settings', {'id': 1, 'first_name': 'Bestuurder', 'theme_mode': 'system', 'use_greeting': 1, 'show_quotes': 1, 'greeting_type': 'time'});
    });
  }

  Future<void> clearAllData() async { final db = await database; await db.delete('entries'); await db.delete('cars'); }
  Future<int> createCar(Car car) async => (await database).insert('cars', car.toMap());
  Future<int> updateCar(Car car) async => (await database).update('cars', car.toMap(), where: 'id = ?', whereArgs: [car.id]);
  Future<int> deleteCar(int id) async => (await database).delete('cars', where: 'id = ?', whereArgs: [id]);
  Future<List<Car>> getAllCars() async => (await (await database).query('cars')).map((json) => Car.fromMap(json)).toList();
  Future<int> insertEntry(Map<String, dynamic> row) async => (await database).insert('entries', row);
  Future<int> updateEntry(Map<String, dynamic> row) async => (await database).update('entries', row, where: 'id = ?', whereArgs: [row['id']]);
  Future<int> deleteEntry(int id) async => (await database).delete('entries', where: 'id = ?', whereArgs: [id]);
  Future<List<Map<String, dynamic>>> getAllEntries() async => (await (await database).query('entries', orderBy: 'date DESC'));
  Future<Map<String, dynamic>> getUser() async => (await (await database).query('user_settings', where: 'id = 1')).first;
  Future<int> updateUser(Map<String, dynamic> data) async => (await database).update('user_settings', data, where: 'id = 1');
}