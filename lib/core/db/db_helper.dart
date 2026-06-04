import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DBHelper {
  static const _dbName = 'cartPracticeItems.db';
  static const _dbVersion = 2;
  static const tableName = 'items';
  static const dbId = 'dbId';

  DBHelper._privateConstructor();

  static DBHelper instance = DBHelper._privateConstructor();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    } else {
      _database = await openMyDB();
      return _database!;
    }
  }

  Future<Database> openMyDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);
    final database = await openDatabase(path, version: _dbVersion,
        onCreate: (db, version) async {
          db.execute('''
        CREATE TABLE $tableName (
        $dbId INTEGER PRIMARY KEY AUTOINCREMENT,
        )
        ''');
        });
    return database;
  }

}
