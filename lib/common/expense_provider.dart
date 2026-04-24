import 'package:flutter/material.dart';
import 'database_helper.dart';

class ExpenseModel {
  final int? id;
  final String category;
  final double amount;
  final String note;
  final DateTime date;
  final Color color;

  ExpenseModel({
    this.id,
    required this.category,
    required this.amount,
    required this.note,
    required this.date,
    required this.color,
  });
}

class SavingsGoalModel {
  final int? id;
  final String name;
  final double targetAmount;
  final double savedAmount;
  final Color color;
  final String icon;
  final int sortOrder;
  final DateTime createdAt;

  SavingsGoalModel({
    this.id,
    required this.name,
    required this.targetAmount,
    required this.savedAmount,
    required this.color,
    required this.icon,
    required this.sortOrder,
    required this.createdAt,
  });

  double get percentage =>
      targetAmount > 0 ? (savedAmount / targetAmount).clamp(0.0, 1.0) : 0.0;

  bool get isCompleted => savedAmount >= targetAmount;

  double get remaining =>
      (targetAmount - savedAmount).clamp(0.0, double.infinity);
}

class FixedExpenseModel {
  final int? id;
  final String name;
  final double amount;
  final int dayOfMonth;
  final String type; // 'bill' | 'subscription' | 'rent' | 'other'

  FixedExpenseModel({
    this.id,
    required this.name,
    required this.amount,
    required this.dayOfMonth,
    this.type = 'other',
  });
}

// ── Predefined Subscriptions ───────────────────
const List<Map<String, dynamic>> kPredefinedSubscriptions = [
  {'name': 'Netflix',         'price': 649.0,  'icon': 'assets/img/netflix_logo.png'},
  {'name': 'Spotify',         'price': 119.0,  'icon': 'assets/img/spotify_logo.png'},
  {'name': 'YouTube Premium', 'price': 129.0,  'icon': 'assets/img/youtube_logo.png'},
  {'name': 'Amazon Prime',    'price': 299.0,  'icon': 'assets/img/onedrive_logo.png'},
  {'name': 'HBO Max',         'price': 499.0,  'icon': 'assets/img/hbo_logo.png'},
];

class ExpenseProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;

  List<Map<String, dynamic>> _budgets = [];
  List<ExpenseModel> _expenses = [];
  List<SavingsGoalModel> _savingsGoals = [];
  List<FixedExpenseModel> _fixedExpenses = [];
  double _monthlyIncome = 0.0;
  double _savingsGoal = 0.0;
  bool _isLoading = true;

  List<Map<String, dynamic>> get budgets => _budgets;
  List<ExpenseModel> get expenses => _expenses;
  List<SavingsGoalModel> get savingsGoals => _savingsGoals;
  List<FixedExpenseModel> get fixedExpenses => _fixedExpenses;
  double get monthlyIncome => _monthlyIncome;
  double get savingsGoal => _savingsGoal;
  bool get isLoading => _isLoading;

  ExpenseProvider() {
    loadData();
  }

  // ── Load all data from DB ──────────────────────
  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();

    // Load budgets
    final rawBudgets = await _db.getBudgets();
    _budgets = rawBudgets.map((b) {
      return {
        'id': b['id'],
        'name': b['name'],
        'icon': b['icon'],
        'spend_amount': b['spend_amount'] as double,
        'total_budget': b['total_budget'] as double,
        'color': Color(b['color'] as int),
        'isCustom': b['is_custom'] == 1,
      };
    }).toList();

    // Load expenses
    final rawExpenses = await _db.getExpenses();
    _expenses = rawExpenses.map((e) {
      return ExpenseModel(
        id: e['id'] as int?,
        category: e['category'] as String,
        amount: e['amount'] as double,
        note: e['note'] as String,
        date: DateTime.parse(e['date'] as String),
        color: Color(e['color'] as int),
      );
    }).toList();

    // Load savings goals
    final rawGoals = await _db.getSavingsGoals();
    _savingsGoals = rawGoals.map((g) {
      return SavingsGoalModel(
        id: g['id'] as int?,
        name: g['name'] as String,
        targetAmount: g['target_amount'] as double,
        savedAmount: g['saved_amount'] as double,
        color: Color(g['color'] as int),
        icon: g['icon'] as String,
        sortOrder: g['sort_order'] as int,
        createdAt: DateTime.parse(g['created_at'] as String),
      );
    }).toList();

    // Load income + savings goal + fixed expenses
    _monthlyIncome = await _db.getMonthlyIncome();
    final savedGoalStr = await _db.getSetting('savings_goal');
    _savingsGoal = savedGoalStr != null ? double.tryParse(savedGoalStr) ?? 0.0 : 0.0;
    final rawFixed = await _db.getFixedExpenses();
    _fixedExpenses = rawFixed.map((f) => FixedExpenseModel(
      id: f['id'] as int?,
      name: f['name'] as String,
      amount: f['amount'] as double,
      dayOfMonth: f['day_of_month'] as int,
      type: (f['type'] as String?) ?? 'other',
    )).toList();

    _isLoading = false;
    notifyListeners();
  }

  // ── Computed Values ────────────────────────────
  double get totalSpent =>
      _budgets.fold(0, (sum, b) => sum + (b["spend_amount"] as double));

  double get totalBudget =>
      _budgets.fold(0, (sum, b) => sum + (b["total_budget"] as double));

  double get totalLeft => totalBudget - totalSpent;

  String get highestCategory {
    if (_budgets.isEmpty) return "N/A";
    final sorted = List<Map<String, dynamic>>.from(_budgets)
      ..sort((a, b) => (b["spend_amount"] as double)
          .compareTo(a["spend_amount"] as double));
    return sorted.first["name"];
  }

  List<ExpenseModel> get recentExpenses {
    final sorted = List<ExpenseModel>.from(_expenses)
      ..sort((a, b) => b.date.compareTo(a.date));
    return sorted.take(5).toList();
  }

  // ── Savings Goals Computed ─────────────────────
  double get totalSaved =>
      _savingsGoals.fold(0, (sum, g) => sum + g.savedAmount);

  double get totalGoalTarget =>
      _savingsGoals.fold(0, (sum, g) => sum + g.targetAmount);

  int get completedGoals =>
      _savingsGoals.where((g) => g.isCompleted).length;

  // ── Add Expense ────────────────────────────────
  Future<void> addExpense(int index, double amount, String note) async {
    final budget = _budgets[index];
    final newSpend = (budget["spend_amount"] as double) + amount;

    await _db.updateBudgetSpend(budget["id"] as int, newSpend);
    await _db.insertExpense({
      'category': budget["name"],
      'amount': amount,
      'note': note,
      'date': DateTime.now(),
      'color': budget["color"],
    });

    _budgets[index]["spend_amount"] = newSpend;
    _expenses.insert(
      0,
      ExpenseModel(
        category: budget["name"],
        amount: amount,
        note: note,
        date: DateTime.now(),
        color: budget["color"] as Color,
      ),
    );

    notifyListeners();
  }

  // ── Add Category ───────────────────────────────
  Future<void> addCategory(Map<String, dynamic> category) async {
    final id = await _db.insertBudget(category);
    _budgets.add({...category, 'id': id});
    notifyListeners();
  }

  // ── Edit Category ──────────────────────────────
  Future<void> editCategory(int index, String name, double budget) async {
    final id = _budgets[index]["id"] as int;
    await _db.updateBudget(id, name, budget);
    _budgets[index]["name"] = name;
    _budgets[index]["total_budget"] = budget;
    notifyListeners();
  }

  // ── Delete Category ────────────────────────────
  Future<void> deleteCategory(int index) async {
    final id = _budgets[index]["id"] as int;
    final name = _budgets[index]["name"] as String;
    await _db.deleteBudget(id);
    await _db.deleteExpensesByCategory(name);
    _budgets.removeAt(index);
    _expenses.removeWhere((e) => e.category == name);
    notifyListeners();
  }

  // ── Reset Category ─────────────────────────────
  Future<void> resetCategory(int index) async {
    final id = _budgets[index]["id"] as int;
    final name = _budgets[index]["name"] as String;
    await _db.resetBudgetSpend(id);
    await _db.deleteExpensesByBudgetReset(name);
    _budgets[index]["spend_amount"] = 0.0;
    _expenses.removeWhere((e) => e.category == name);
    notifyListeners();
  }

  // ── Add Savings Goal ───────────────────────────
  Future<void> addSavingsGoal(Map<String, dynamic> goal) async {
    final id = await _db.insertSavingsGoal(goal);
    _savingsGoals.add(SavingsGoalModel(
      id: id,
      name: goal['name'],
      targetAmount: goal['target_amount'],
      savedAmount: 0.0,
      color: goal['color'] as Color,
      icon: goal['icon'] ?? 'savings',
      sortOrder: _savingsGoals.length,
      createdAt: DateTime.now(),
    ));
    notifyListeners();
  }

  // ── Add Money to Goal ──────────────────────────
  Future<void> addMoneyToGoal(int index, double amount) async {
    final goal = _savingsGoals[index];
    final newSaved = (goal.savedAmount + amount).clamp(0.0, goal.targetAmount);
    await _db.updateSavingsGoalAmount(goal.id!, newSaved);
    _savingsGoals[index] = SavingsGoalModel(
      id: goal.id,
      name: goal.name,
      targetAmount: goal.targetAmount,
      savedAmount: newSaved,
      color: goal.color,
      icon: goal.icon,
      sortOrder: goal.sortOrder,
      createdAt: goal.createdAt,
    );
    notifyListeners();
  }

  // ── Edit Savings Goal ──────────────────────────
  Future<void> editSavingsGoal(
      int index, String name, double targetAmount) async {
    final goal = _savingsGoals[index];
    await _db.updateSavingsGoal(goal.id!, name, targetAmount);
    _savingsGoals[index] = SavingsGoalModel(
      id: goal.id,
      name: name,
      targetAmount: targetAmount,
      savedAmount: goal.savedAmount,
      color: goal.color,
      icon: goal.icon,
      sortOrder: goal.sortOrder,
      createdAt: goal.createdAt,
    );
    notifyListeners();
  }

  // ── Delete Savings Goal ────────────────────────
  Future<void> deleteSavingsGoal(int index) async {
    final goal = _savingsGoals[index];
    await _db.deleteSavingsGoal(goal.id!);
    _savingsGoals.removeAt(index);
    notifyListeners();
  }

  // ── Reorder Savings Goals ──────────────────────
  Future<void> reorderSavingsGoals(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex -= 1;
    final goal = _savingsGoals.removeAt(oldIndex);
    _savingsGoals.insert(newIndex, goal);

    // Update sort order
    for (int i = 0; i < _savingsGoals.length; i++) {
      _savingsGoals[i] = SavingsGoalModel(
        id: _savingsGoals[i].id,
        name: _savingsGoals[i].name,
        targetAmount: _savingsGoals[i].targetAmount,
        savedAmount: _savingsGoals[i].savedAmount,
        color: _savingsGoals[i].color,
        icon: _savingsGoals[i].icon,
        sortOrder: i,
        createdAt: _savingsGoals[i].createdAt,
      );
    }

    await _db.updateSavingsGoalOrder(
      _savingsGoals
          .map((g) => {'id': g.id, 'sort_order': g.sortOrder})
          .toList(),
    );

    notifyListeners();
  }

  // ── Money Flow — Income ────────────────────────
  Future<void> setIncome(double income) async {
    await _db.setMonthlyIncome(income);
    _monthlyIncome = income;
    notifyListeners();
  }

  // ── Money Flow — Savings Goal ──────────────────
  Future<void> setSavingsGoal(double value) async {
    _savingsGoal = value;
    await _db.setSetting('savings_goal', value.toString());
    notifyListeners();
  }

  // ── Money Flow — Fixed Expenses ────────────────
  Future<void> addFixedExpense(String name, double amount, int dayOfMonth, {String type = 'other'}) async {
    final id = await _db.insertFixedExpense({
      'name': name,
      'amount': amount,
      'day_of_month': dayOfMonth,
      'type': type,
    });
    _fixedExpenses.add(FixedExpenseModel(
      id: id,
      name: name,
      amount: amount,
      dayOfMonth: dayOfMonth,
      type: type,
    ));
    notifyListeners();
  }

  Future<void> removeFixedExpense(int index) async {
    final id = _fixedExpenses[index].id!;
    await _db.deleteFixedExpense(id);
    _fixedExpenses.removeAt(index);
    notifyListeners();
  }

  // ── Money Flow — Computed ──────────────────────
  double get totalFixedExpenses =>
      _fixedExpenses.fold(0.0, (sum, f) => sum + f.amount);

  double getRemainingAfterFixed() {
    if (_monthlyIncome <= 0) return 0.0;
    return (_monthlyIncome - totalFixedExpenses).clamp(0.0, double.infinity);
  }

  double getDailySafeSpend() {
    final remaining = getRemainingAfterFixed();
    if (remaining <= 0) return 0.0;
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final daysLeft = daysInMonth - now.day + 1;
    return remaining / daysLeft;
  }

  // ── Smart Auto-Deduction — Tax ─────────────────
  // Simplified Indian tax slab (new regime approximation)
  // Converts monthly → yearly → applies slabs → returns monthly tax
  double calculateTax(double monthlyIncome) {
    if (monthlyIncome <= 0) return 0.0;
    final yearly = monthlyIncome * 12;
    double yearlyTax = 0.0;

    if (yearly <= 250000) {
      yearlyTax = 0.0;
    } else if (yearly <= 500000) {
      yearlyTax = (yearly - 250000) * 0.05;
    } else if (yearly <= 1000000) {
      yearlyTax = (250000 * 0.05) + ((yearly - 500000) * 0.20);
    } else {
      yearlyTax = (250000 * 0.05) + (500000 * 0.20) + ((yearly - 1000000) * 0.30);
    }

    return yearlyTax / 12;
  }

  // ── Smart Auto-Deduction — Filtered Getters ────
  List<FixedExpenseModel> get subscriptions =>
      _fixedExpenses.where((f) => f.type == 'subscription').toList();

  List<FixedExpenseModel> get bills =>
      _fixedExpenses.where((f) => f.type == 'bill').toList();

  List<FixedExpenseModel> get rentExpenses =>
      _fixedExpenses.where((f) => f.type == 'rent').toList();

  // ── Smart Auto-Deduction — Engine ─────────────
  double getTotalDeductions() {
    if (_monthlyIncome <= 0) return 0.0;
    return calculateTax(_monthlyIncome) + totalFixedExpenses;
  }

  double getNetUsableBalance() {
    if (_monthlyIncome <= 0) return 0.0;
    return (_monthlyIncome - getTotalDeductions()).clamp(0.0, double.infinity);
  }
}