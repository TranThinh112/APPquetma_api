  import 'dart:io';

  import 'package:flutter/foundation.dart';
  import 'package:flutter/services.dart';
  import 'package:path/path.dart';
  import 'package:sqflite/sqflite.dart';

  class OrderDatabase {
    static final OrderDatabase instance = OrderDatabase._init();

    static Database? _database;

    OrderDatabase._init();

    // Trong bản web, chúng ta giữ dữ liệu trong bộ nhớ thay vì mở tệp SQLite.
    final Map<String, Map<String, dynamic>> _inMemoryOrders = {};

    Future<Database> get database async {
      if (kIsWeb) {
        // Web không hỗ trợ sqflite, nên không mở DB thật ở đây.
        throw UnsupportedError(
          'SQLite không hỗ trợ trên web. Sử dụng lưu tạm trong bộ nhớ.',
        );
      }

      if (_database != null) return _database!;

      _database = await _initDB();
      return _database!;
    }

    Future<Database> _initDB() async {
      final dbPath = await getDatabasesPath();
      final orderDbPath = join(dbPath, 'order_db.db');
      final assetPath = 'assets/orders_db.db';

      if (await databaseExists(orderDbPath)) {
        bool needsCopy = false;
        try {
          final existingDb = await openDatabase(orderDbPath, readOnly: true);
          final tables = await existingDb.rawQuery(
            "SELECT name FROM sqlite_master WHERE type='table' AND name='orders';",
          );
          if (tables.isEmpty) {
            needsCopy = true;
          } else {
            final countResult = await existingDb.rawQuery(
              'SELECT COUNT(*) AS c FROM orders',
            );
            final count = Sqflite.firstIntValue(countResult) ?? 0;
            if (count == 0) needsCopy = true;
          }
          await existingDb.close();
        } catch (e) {
          needsCopy = true;
        }

        if (needsCopy) {
          try {
            final data = await rootBundle.load(assetPath);
            final bytes = data.buffer.asUint8List();
            await File(orderDbPath).writeAsBytes(bytes, flush: true);
            print('order_db.db cũ trống / sai bảng -> copy lại từ $assetPath');
          } catch (e) {
            print('Không thể copy asset DB khi cần phục hồi: $e');
          }
        }
      } else {
        try {
          final data = await rootBundle.load(assetPath);
          final bytes = data.buffer.asUint8List();
          await File(orderDbPath).create(recursive: true);
          await File(orderDbPath).writeAsBytes(bytes, flush: true);
          print('Đã copy DB mẫu từ $assetPath đến $orderDbPath');
        } catch (e) {
          print('Không tìm thấy asset DB $assetPath hoặc copy bị lỗi: $e');
        }
      }

      print('Đường dẫn cơ sở dữ liệu: $orderDbPath');

      final db = await openDatabase(
        orderDbPath,
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS orders (
              id TEXT PRIMARY KEY,
              station TEXT,
              weight REAL
            )
          ''');
          await db.execute('''
            CREATE TABLE IF NOT EXISTS users (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              username TEXT,
              password TEXT,
              created_at TEXT
            )
          ''');
          await db.execute('''
            CREATE TABLE IF NOT EXISTS login_logs (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              username TEXT,
              login_at TEXT
            )
          ''');
        },
      );

      // Đảm bảo các bảng cần thiết luôn tồn tại, ngay cả khi DB đã có sẵn từ trước.
      // Điều này cần thiết khi chúng ta copy DB mẫu (asset) vào.
      await db.execute('''
        CREATE TABLE IF NOT EXISTS users (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          username TEXT,
          password TEXT,
          created_at TEXT
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS login_logs (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          username TEXT,
          login_at TEXT
        )
      ''');

      // Nếu DB cũ chưa có cột created_at trên bảng users thì thêm cột.
      final userCols = await db.rawQuery("PRAGMA table_info('users')");
      final hasCreatedAt = userCols.any((c) => c['name'] == 'created_at');
      if (!hasCreatedAt) {
        await db.execute('ALTER TABLE users ADD COLUMN created_at TEXT');
      }

      // Nếu DB chưa có user nào, tạo 1 user mặc định để test.
      final userCountResult = await db.rawQuery('SELECT COUNT(*) as count FROM users');
      final userCount = Sqflite.firstIntValue(userCountResult) ?? 0;
      if (userCount == 0) {
        await db.insert('users', {
          'username': 'admin',
          'password': '123456',
          'created_at': DateTime.now().toIso8601String(),
        });
        await db.insert('users', {
          'username': 'dong',
          'password': 'dongdeptrai',
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      return db;
    }

    /// tìm đơn theo ID
    Future<Map<String, dynamic>?> getOrder(String id) async {
      if (kIsWeb) {
        return _inMemoryOrders[id];
      }

      final db = await instance.database;

      final result = await db.query(
        'orders',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (result.isNotEmpty) {
        return result.first;
      }

      return null;
    }

    /// lấy tất cả đơn hàng
    Future<List<Map<String, dynamic>>> getAllOrders() async {
      if (kIsWeb) {
        return _inMemoryOrders.values.toList();
      }

      final db = await instance.database;
      return await db.query('orders');
    }

    /// đếm số lượng đơn hàng
    Future<int> countOrders() async {
      if (kIsWeb) {
        return _inMemoryOrders.length;
      }

      final db = await instance.database;

      final result = await db.rawQuery('SELECT COUNT(*) as count FROM orders');

      return Sqflite.firstIntValue(result) ?? 0;
    }

    /// Đăng nhập người dùng và ghi lại lần đăng nhập
    Future<Map<String, dynamic>?> login(String username, String password) async {
      final db = await instance.database;

      final result = await db.query(
        'users',
        where: 'username = ? AND password = ?',
        whereArgs: [username, password],
        limit: 1,
      );

      if (result.isNotEmpty) {
        await db.insert(
          'login_logs',
          {
            'username': username,
            'login_at': DateTime.now().toIso8601String(),
          },
        );
        return result.first;
      }
      return null;
    }

    /// Tìm user bằng username (dùng cho quên mật khẩu)
    Future<Map<String, dynamic>?> getUserByUsername(String username) async {
      final db = await instance.database;
      final result = await db.query(
        'users',
        where: 'username = ?',
        whereArgs: [username],
        limit: 1,
      );

      if (result.isNotEmpty) {
        return result.first;
      }
      return null;
    }

    /// Cập nhật mật khẩu người dùng bằng id
    Future<int> updateUserPasswordById(int id, String newPassword) async {
      final db = await instance.database;
      return await db.update(
        'users',
        {'password': newPassword},
        where: 'id = ?',
        whereArgs: [id],
      );
    }

    /// Chèn hoặc cập nhật user theo username
    Future<int> upsertUser(String username, String password) async {
      final db = await instance.database;

      // Nếu user tồn tại, cập nhật password
      final existing = await db.query(
        'users',
        where: 'username = ?',
        whereArgs: [username],
        limit: 1,
      );

      if (existing.isNotEmpty) {
        return await db.update(
          'users',
          {'password': password},
          where: 'username = ?',
          whereArgs: [username],
        );
      }

      return await db.insert(
        'users',
        {
          'username': username,
          'password': password,
          'created_at': DateTime.now().toIso8601String(),
        },
      );
    }
  }
