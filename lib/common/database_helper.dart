import 'package:sqflite/sqflite.dart';
import 'package:sqflite/sqlite_api.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('trackizer.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(
        path, version: 5, onCreate: _createDB, onUpgrade: _upgradeDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE budgets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        icon TEXT NOT NULL,
        spend_amount REAL NOT NULL,
        total_budget REAL NOT NULL,
        color INTEGER NOT NULL,
        is_custom INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category TEXT NOT NULL,
        amount REAL NOT NULL,
        note TEXT NOT NULL,
        date TEXT NOT NULL,
        color INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE savings_goals (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        target_amount REAL NOT NULL,
        saved_amount REAL NOT NULL DEFAULT 0.0,
        color INTEGER NOT NULL,
        icon TEXT NOT NULL DEFAULT 'savings',
        sort_order INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE income (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        monthly_income REAL NOT NULL DEFAULT 0.0,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE fixed_expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        amount REAL NOT NULL,
        day_of_month INTEGER NOT NULL DEFAULT 1,
        type TEXT NOT NULL DEFAULT 'other'
      )
    ''');

    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    await db.insert('budgets', {
      'name': 'Auto & Transport',
      'icon': 'assets/img/auto_&_transport.png',
      'spend_amount': 0.0,
      'total_budget': 400.0,
      'color': 0xff00FAD9,
      'is_custom': 0,
    });
    await db.insert('budgets', {
      'name': 'Entertainment',
      'icon': 'assets/img/entertainment.png',
      'spend_amount': 0.0,
      'total_budget': 600.0,
      'color': 0xffFFA699,
      'is_custom': 0,
    });
    await db.insert('budgets', {
      'name': 'Food & Dining',
      'icon': 'assets/img/money.png',
      'spend_amount': 0.0,
      'total_budget': 500.0,
      'color': 0xffFF7966,
      'is_custom': 0,
    });
    await db.insert('budgets', {
      'name': 'Shopping',
      'icon': 'assets/img/chart.png',
      'spend_amount': 0.0,
      'total_budget': 300.0,
      'color': 0xff924EFF,
      'is_custom': 0,
    });
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS savings_goals (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          target_amount REAL NOT NULL,
          saved_amount REAL NOT NULL DEFAULT 0.0,
          color INTEGER NOT NULL,
          icon TEXT NOT NULL DEFAULT 'savings',
          sort_order INTEGER NOT NULL DEFAULT 0,
          created_at TEXT NOT NULL
        )
      ''');
    }
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS income (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          monthly_income REAL NOT NULL DEFAULT 0.0,
          updated_at TEXT NOT NULL
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS fixed_expenses (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          amount REAL NOT NULL,
          due_date INTEGER NOT NULL DEFAULT 1
        )
      ''');
    }
    if (oldVersion < 4) {
      // Recreate fixed_expenses with correct column names + type column
      await db.execute('DROP TABLE IF EXISTS fixed_expenses');
      await db.execute('''
        CREATE TABLE fixed_expenses (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          amount REAL NOT NULL,
          day_of_month INTEGER NOT NULL DEFAULT 1,
          type TEXT NOT NULL DEFAULT 'other'
        )
      ''');
      // Add settings table for persistent key-value pairs
      await db.execute('''
        CREATE TABLE IF NOT EXISTS settings (
          key TEXT PRIMARY KEY,
          value TEXT NOT NULL
        )
      ''');
    }
    if (oldVersion < 5) {
      // v5: clear any stale savings/income/fixed_expenses from previous installs.
      // Budgets are intentional defaults and are kept.
      await db.execute('DELETE FROM savings_goals');
      await db.execute('DELETE FROM income');
      await db.execute('DELETE FROM fixed_expenses');
    }
  }

  // ── Budget Operations ──────────────────────────

  Future<List<Map<String, dynamic>>> getBudgets() async {
    final db = await database;
    return await db.query('budgets');
  }

  Future<int> insertBudget(Map<String, dynamic> budget) async {
    final db = await database;
    return await db.insert('budgets', {
      'name': budget['name'],
      'icon': budget['icon'] ?? 'assets/img/money.png',
      'spend_amount': budget['spend_amount'],
      'total_budget': budget['total_budget'],
      'color': (budget['color'] as dynamic).value,
      'is_custom': budget['isCustom'] == true ? 1 : 0,
    });
  }

  Future<void> updateBudgetSpend(int id, double spendAmount) async {
    final db = await database;
    await db.update(
      'budgets',
      {'spend_amount': spendAmount},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateBudget(int id, String name, double totalBudget) async {
    final db = await database;
    await db.update(
      'budgets',
      {'name': name, 'total_budget': totalBudget},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteBudget(int id) async {
    final db = await database;
    await db.delete('budgets', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> resetBudgetSpend(int id) async {
    final db = await database;
    await db.update(
      'budgets',
      {'spend_amount': 0.0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ── Expense Operations ─────────────────────────

  Future<List<Map<String, dynamic>>> getExpenses() async {
    final db = await database;
    return await db.query('expenses', orderBy: 'date DESC');
  }

  Future<int> insertExpense(Map<String, dynamic> expense) async {
    final db = await database;
    return await db.insert('expenses', {
      'category': expense['category'],
      'amount': expense['amount'],
      'note': expense['note'],
      'date': expense['date'].toIso8601String(),
      'color': (expense['color'] as dynamic).value,
    });
  }

  Future<void> deleteExpensesByCategory(String category) async {
    final db = await database;
    await db.delete('expenses',
        where: 'category = ?', whereArgs: [category]);
  }

  Future<void> deleteExpensesByBudgetReset(String category) async {
    final db = await database;
    await db.delete('expenses',
        where: 'category = ?', whereArgs: [category]);
  }

  // ── Savings Goals Operations ───────────────────

  Future<List<Map<String, dynamic>>> getSavingsGoals() async {
    final db = await database;
    return await db.query('savings_goals', orderBy: 'sort_order ASC');
  }

  Future<int> insertSavingsGoal(Map<String, dynamic> goal) async {
    final db = await database;
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM savings_goals'),
    ) ??
        0;
    return await db.insert('savings_goals', {
      'name': goal['name'],
      'target_amount': goal['target_amount'],
      'saved_amount': goal['saved_amount'] ?? 0.0,
      'color': (goal['color'] as dynamic).value,
      'icon': goal['icon'] ?? 'savings',
      'sort_order': count,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> updateSavingsGoalAmount(int id, double savedAmount) async {
    final db = await database;
    await db.update(
      'savings_goals',
      {'saved_amount': savedAmount},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateSavingsGoal(
      int id, String name, double targetAmount) async {
    final db = await database;
    await db.update(
      'savings_goals',
      {'name': name, 'target_amount': targetAmount},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteSavingsGoal(int id) async {
    final db = await database;
    await db.delete('savings_goals',
        where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateSavingsGoalOrder(
      List<Map<String, dynamic>> goals) async {
    final db = await database;
    final batch = db.batch();
    for (int i = 0; i < goals.length; i++) {
      batch.update(
        'savings_goals',
        {'sort_order': i},
        where: 'id = ?',
        whereArgs: [goals[i]['id']],
      );
    }
    await batch.commit(noResult: true);
  }

  // ── Income Operations ──────────────────────────

  Future<double> getMonthlyIncome() async {
    final db = await database;
    final result = await db.query('income',
        orderBy: 'id DESC', limit: 1);
    if (result.isEmpty) return 0.0;
    return result.first['monthly_income'] as double;
  }

  Future<void> setMonthlyIncome(double amount) async {
    final db = await database;
    final existing = await db.query('income', limit: 1);
    if (existing.isEmpty) {
      await db.insert('income', {
        'monthly_income': amount,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } else {
      await db.update(
        'income',
        {
          'monthly_income': amount,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [existing.first['id']],
      );
    }
  }

  // ── Fixed Expenses Operations ──────────────────

  Future<List<Map<String, dynamic>>> getFixedExpenses() async {
    final db = await database;
    return await db.query('fixed_expenses', orderBy: 'day_of_month ASC');
  }

  Future<int> insertFixedExpense(Map<String, dynamic> expense) async {
    final db = await database;
    return await db.insert('fixed_expenses', {
      'name': expense['name'],
      'amount': expense['amount'],
      'day_of_month': expense['day_of_month'] ?? 1,
      'type': expense['type'] ?? 'other',
    });
  }

  Future<void> deleteFixedExpense(int id) async {
    final db = await database;
    await db.delete('fixed_expenses',
        where: 'id = ?', whereArgs: [id]);
  }

  // ── Settings (key-value) ───────────────────────

  Future<String?> getSetting(String key) async {
    final db = await database;
    final result = await db.query('settings',
        where: 'key = ?', whereArgs: [key], limit: 1);
    if (result.isEmpty) return null;
    return result.first['value'] as String;
  }

  Future<void> setSetting(String key, String value) async {
    final db = await database;
    await db.insert(
      'settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> closeDB() async {
    final db = await database;
    db.close();
  }
}