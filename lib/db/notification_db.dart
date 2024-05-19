import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBHelper {
  static Database? _database;
  static const String DB_NAME = 'notifications.db';
  static const String TABLE_NAME = 'NotificationTimes';
  static const String COLUMN_ID = 'id';
  static const String COLUMN_TIME = 'time';

  static Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDB();
    return _database!;
  }

  static Future<Database> _initDB() async {
    String path = join(await getDatabasesPath(), DB_NAME);
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) {
        return db.execute(
          '''
          CREATE TABLE $TABLE_NAME (
            $COLUMN_ID INTEGER PRIMARY KEY AUTOINCREMENT,
            $COLUMN_TIME TEXT NOT NULL
          )
          ''',
        );
      },
    );
  }

  static Future<void> insertNotificationTime(String time) async {
    final db = await database;
    await db.insert(
      TABLE_NAME,
      {'time': time},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<Map<String, dynamic>>> getNotificationTimes() async {
    final db = await database;
    return await db.query(TABLE_NAME);
  }
}
