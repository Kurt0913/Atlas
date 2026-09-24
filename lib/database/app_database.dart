import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../models/client.dart';
import '../models/task_item.dart';

class CurrencySplit {
  final String currency;
  final double total;

  const CurrencySplit({required this.currency, required this.total});
}

class AppDatabase {
  static final AppDatabase instance = AppDatabase._init();
  static Database? _database;

  AppDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('atlas_tracker.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      try {
        databaseFactory;
      } catch (_) {
        sqfliteFfiInit();
        databaseFactory = databaseFactoryFfi;
      }
    }

    String dbPath;
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      final appDocDir = await getApplicationDocumentsDirectory();
      dbPath = join(appDocDir.path, 'Atlas', filePath);
      final directory = Directory(dirname(dbPath));
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
    } else {
      final databasesPath = await getDatabasesPath();
      dbPath = join(databasesPath, filePath);
    }

    return await openDatabase(
      dbPath,
      version: 1,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON;');
      },
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE clients (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        platform TEXT DEFAULT 'Direct',
        rate REAL DEFAULT 0,
        rate_type TEXT DEFAULT 'Per Task',
        currency TEXT DEFAULT 'PHP',
        contact_type TEXT DEFAULT 'Other',
        contact_method TEXT DEFAULT '',
        timezone TEXT DEFAULT 'UTC',
        notes TEXT DEFAULT ''
      );
    ''');

    await db.execute('''
      CREATE TABLE tasks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        client_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        due_date TEXT NOT NULL,
        status TEXT DEFAULT 'todo',
        notes TEXT DEFAULT '',
        notification_id_day_before TEXT,
        notification_id_day_of TEXT,
        notification_id_overdue TEXT,
        overdue_notified INTEGER DEFAULT 0,
        FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE CASCADE
      );
    ''');
  }

  // --- Clients CRUD ---

  Future<List<Client>> getClients() async {
    final db = await instance.database;
    final result = await db.rawQuery('''
      SELECT c.*,
        COUNT(CASE WHEN t.status != 'done' THEN 1 END) AS active_tasks
      FROM clients c
      LEFT JOIN tasks t ON t.client_id = c.id
      GROUP BY c.id
      ORDER BY c.name COLLATE NOCASE ASC
    ''');
    return result.map((json) => Client.fromMap(json)).toList();
  }

  Future<Client?> getClientById(int id) async {
    final db = await instance.database;
    final result = await db.query('clients', where: 'id = ?', whereArgs: [id]);
    if (result.isNotEmpty) {
      return Client.fromMap(result.first);
    }
    return null;
  }

  Future<int> createClient(Client client) async {
    final db = await instance.database;
    return await db.insert('clients', client.toMap());
  }

  Future<int> updateClient(Client client) async {
    final db = await instance.database;
    return await db.update(
      'clients',
      client.toMap(),
      where: 'id = ?',
      whereArgs: [client.id],
    );
  }

  Future<int> deleteClient(int clientId) async {
    final db = await instance.database;
    return await db.delete('clients', where: 'id = ?', whereArgs: [clientId]);
  }

  // --- Tasks CRUD ---

  Future<List<TaskItem>> getAllTasks() async {
    final db = await instance.database;
    final result = await db.rawQuery('''
      SELECT t.*, c.name AS client_name, c.rate AS rate, c.currency AS currency
      FROM tasks t
      JOIN clients c ON c.id = t.client_id
      ORDER BY t.due_date ASC
    ''');
    return result.map((json) => TaskItem.fromMap(json)).toList();
  }

  Future<List<TaskItem>> getClientTasks(int clientId) async {
    final db = await instance.database;
    final result = await db.rawQuery('''
      SELECT t.*, c.name AS client_name, c.rate AS rate, c.currency AS currency
      FROM tasks t
      JOIN clients c ON c.id = t.client_id
      WHERE t.client_id = ?
      ORDER BY t.due_date ASC
    ''', [clientId]);
    return result.map((json) => TaskItem.fromMap(json)).toList();
  }

  Future<TaskItem?> getTaskById(int taskId) async {
    final db = await instance.database;
    final result = await db.rawQuery('''
      SELECT t.*, c.name AS client_name, c.rate AS rate, c.currency AS currency
      FROM tasks t
      JOIN clients c ON c.id = t.client_id
      WHERE t.id = ?
    ''', [taskId]);
    if (result.isNotEmpty) {
      return TaskItem.fromMap(result.first);
    }
    return null;
  }

  Future<int> createTask(TaskItem task) async {
    final db = await instance.database;
    return await db.insert('tasks', task.toMap());
  }

  Future<int> updateTask(TaskItem task) async {
    final db = await instance.database;
    return await db.update(
      'tasks',
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  Future<int> updateTaskStatus(int taskId, String status) async {
    final db = await instance.database;
    return await db.update(
      'tasks',
      {'status': status},
      where: 'id = ?',
      whereArgs: [taskId],
    );
  }

  Future<int> deleteTask(int taskId) async {
    final db = await instance.database;
    return await db.delete('tasks', where: 'id = ?', whereArgs: [taskId]);
  }

  // --- Financial Overview Queries ---

  Future<List<CurrencySplit>> getEarningsSplit({String timeframe = 'month'}) async {
    final db = await instance.database;
    final timeQuery = timeframe == 'week'
        ? "strftime('%Y-%W', t.due_date) = strftime('%Y-%W', 'now', 'localtime')"
        : "strftime('%Y-%m', t.due_date) = strftime('%Y-%m', 'now', 'localtime')";

    final result = await db.rawQuery('''
      SELECT c.currency, SUM(c.rate) as total
      FROM tasks t
      JOIN clients c ON t.client_id = c.id
      WHERE t.status = 'done' AND $timeQuery
      GROUP BY c.currency
    ''');

    return result.map((row) {
      return CurrencySplit(
        currency: row['currency'] as String? ?? 'PHP',
        total: (row['total'] as num?)?.toDouble() ?? 0.0,
      );
    }).toList();
  }

  Future<List<TaskItem>> getEarningsTasks({String timeframe = 'month'}) async {
    final db = await instance.database;
    final timeQuery = timeframe == 'week'
        ? "strftime('%Y-%W', t.due_date) = strftime('%Y-%W', 'now', 'localtime')"
        : "strftime('%Y-%m', t.due_date) = strftime('%Y-%m', 'now', 'localtime')";

    final result = await db.rawQuery('''
      SELECT t.id, t.title, t.due_date, t.status, t.client_id, c.name as client_name, c.rate, c.currency
      FROM tasks t
      JOIN clients c ON t.client_id = c.id
      WHERE t.status = 'done' AND $timeQuery
      ORDER BY t.due_date DESC
    ''');

    return result.map((json) => TaskItem.fromMap(json)).toList();
  }

  /// Returns all done tasks whose due_date falls within [dateFrom]..[dateTo].
  Future<List<TaskItem>> getInvoiceTasks({
    required DateTime dateFrom,
    required DateTime dateTo,
  }) async {
    final db = await instance.database;
    final from = DateFormat('yyyy-MM-dd').format(dateFrom);
    final to = DateFormat('yyyy-MM-dd').format(dateTo);
    final result = await db.rawQuery('''
      SELECT t.id, t.title, t.due_date, t.status, t.client_id,
             c.name as client_name, c.rate, c.currency
      FROM tasks t
      JOIN clients c ON t.client_id = c.id
      WHERE t.status = 'done'
        AND t.due_date >= ?
        AND t.due_date <= ?
      ORDER BY c.currency ASC, t.due_date ASC
    ''', [from, to]);
    return result.map((json) => TaskItem.fromMap(json)).toList();
  }


  Future<Map<String, dynamic>> exportDatabaseData() async {
    final db = await instance.database;
    final clients = await db.query('clients');
    final tasks = await db.query('tasks');
    return {
      'clients': clients,
      'tasks': tasks,
    };
  }

  Future<void> importDatabaseData(Map<String, dynamic> data) async {
    final db = await instance.database;
    await db.transaction((txn) async {
      await txn.delete('tasks');
      await txn.delete('clients');

      final clientsList = data['clients'] as List<dynamic>? ?? [];
      for (final client in clientsList) {
        if (client is Map<String, dynamic>) {
          await txn.insert('clients', client);
        }
      }

      final tasksList = data['tasks'] as List<dynamic>? ?? [];
      for (final task in tasksList) {
        if (task is Map<String, dynamic>) {
          await txn.insert('tasks', task);
        }
      }
    });
  }
}
