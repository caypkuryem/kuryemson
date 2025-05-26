// lib/services/database_helper.dart

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../profile/models/user.dart'; // User modelini import edin

class DatabaseHelper {
  static const int _version = 4; // VERİTABANI VERSİYONU ARTIRILDI (3'ten 4'e)
  static const String _dbName = 'kuryem.db';

  // Sütun adları için sabitler
  static const String tableUsers = 'users';
  static const String columnId = 'id';
  static const String columnName = 'name';
  static const String columnSurname = 'surname';
  static const String columnEmail = 'email';
  static const String columnPhone = 'phone';
  static const String columnCompany = 'company';
  static const String columnPassword = 'password';
  static const String columnMotorPlakasi = 'motor_plakasi';
  static const String columnCalistigiIlIlce = 'calistigi_il_ilce';
  static const String columnAvatarUrl = 'avatar_url';       // YENİ
  static const String columnHesapDurumu = 'hesap_durumu';   // YENİ (opsiyonel)

  // Singleton Pattern
  static final DatabaseHelper instance = DatabaseHelper._internal();
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String documentsDirectory = await getDatabasesPath();
    String path = join(documentsDirectory, _dbName);

    return await openDatabase(
      path,
      version: _version,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableUsers (
        $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
        $columnName TEXT NOT NULL,
        $columnSurname TEXT NOT NULL,
        $columnEmail TEXT UNIQUE NOT NULL,
        $columnPhone TEXT NOT NULL,
        $columnCompany TEXT NOT NULL,
        $columnPassword TEXT NOT NULL,
        $columnMotorPlakasi TEXT,
        $columnCalistigiIlIlce TEXT,
        $columnAvatarUrl TEXT,
        $columnHesapDurumu TEXT
      )
    ''');
    print("DatabaseHelper: Users table created with all columns including avatar_url and hesap_durumu.");
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    print("DatabaseHelper: Upgrading database from version $oldVersion to $newVersion");

    if (oldVersion < 2) {
      try {
        await db.execute("ALTER TABLE $tableUsers ADD COLUMN $columnMotorPlakasi TEXT;");
        print("DatabaseHelper: Upgraded users table, added $columnMotorPlakasi column (from <2).");
      } catch (e) {
        print("DatabaseHelper: Error or $columnMotorPlakasi already exists (when upgrading from <2): $e");
      }
    }

    if (oldVersion < 3) {
      // motor_plakasi <2'de eklenmemişse diye tekrar (genelde gereksiz ama güvenli)
      if (oldVersion < 2) {
        try {
          await db.execute("ALTER TABLE $tableUsers ADD COLUMN $columnMotorPlakasi TEXT;");
          print("DatabaseHelper: Added $columnMotorPlakasi column (if not exists from <3, previously <2).");
        } catch (e) {
          // Hata vermesi normal eğer zaten varsa
        }
      }
      try {
        await db.execute("ALTER TABLE $tableUsers ADD COLUMN $columnCalistigiIlIlce TEXT;");
        print("DatabaseHelper: Upgraded users table, added $columnCalistigiIlIlce column (from <3).");
      } catch (e) {
        print("DatabaseHelper: Error or $columnCalistigiIlIlce already exists (when upgrading from <3): $e");
      }
    }

    if (oldVersion < 4) {
      try {
        await db.execute("ALTER TABLE $tableUsers ADD COLUMN $columnAvatarUrl TEXT;");
        print("DatabaseHelper: Upgraded users table, added $columnAvatarUrl column (from <4).");
      } catch (e) {
        print("DatabaseHelper: Error or $columnAvatarUrl already exists (when upgrading from <4): $e");
      }
      try {
        await db.execute("ALTER TABLE $tableUsers ADD COLUMN $columnHesapDurumu TEXT;");
        print("DatabaseHelper: Upgraded users table, added $columnHesapDurumu column (from <4).");
      } catch (e) {
        print("DatabaseHelper: Error or $columnHesapDurumu already exists (when upgrading from <4): $e");
      }
    }
  }

  Future<int> insertUser(User user) async {
    Database db = await instance.database;
    return await db.insert(tableUsers, user.toMap(), conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<List<User>> getAllUsers() async {
    Database db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(tableUsers);
    if (maps.isEmpty) return [];
    return List.generate(maps.length, (i) {
      return User.fromMap(maps[i]);
    });
  }

  Future<User?> getUserById(int id) async {
    Database db = await instance.database;
    List<Map<String, dynamic>> maps = await db.query(
      tableUsers,
      columns: [columnId, columnName, columnSurname, columnEmail, columnPhone, columnCompany, columnPassword, columnMotorPlakasi, columnCalistigiIlIlce, columnAvatarUrl, columnHesapDurumu],
      where: '$columnId = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    } else {
      return null;
    }
  }

  Future<User?> getUserByEmail(String email) async {
    Database db = await instance.database;
    List<Map<String, dynamic>> maps = await db.query(
      tableUsers,
      columns: [columnId, columnName, columnSurname, columnEmail, columnPhone, columnCompany, columnPassword, columnMotorPlakasi, columnCalistigiIlIlce, columnAvatarUrl, columnHesapDurumu],
      where: '$columnEmail = ?',
      whereArgs: [email],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    } else {
      return null;
    }
  }

  Future<User?> getUserByEmailAndPassword(String email, String password) async {
    Database db = await instance.database;
    List<Map<String, dynamic>> maps = await db.query(
      tableUsers,
      columns: [columnId, columnName, columnSurname, columnEmail, columnPhone, columnCompany, columnPassword, columnMotorPlakasi, columnCalistigiIlIlce, columnAvatarUrl, columnHesapDurumu],
      where: '$columnEmail = ? AND $columnPassword = ?',
      whereArgs: [email, password],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    } else {
      return null;
    }
  }

  Future<int> updateUser(User user) async {
    Database db = await instance.database;
    return await db.update(
      tableUsers,
      user.toMap(),
      where: '$columnId = ?',
      whereArgs: [user.id],
    );
  }

  Future<int> deleteUser(int id) async {
    Database db = await instance.database;
    return await db.delete(
      tableUsers,
      where: '$columnId = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteAllUsers() async {
    Database db = await instance.database;
    return await db.delete(tableUsers);
  }

  Future<void> close() async {
    final db = _database;
    if (db != null && db.isOpen) {
      await db.close();
      _database = null;
      print("DatabaseHelper: Database closed.");
    }
  }
}