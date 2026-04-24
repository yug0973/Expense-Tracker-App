import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trackizer/common/color_extension.dart';
import 'package:trackizer/common/expense_provider.dart';
import 'package:trackizer/view/settings/settings_view.dart';
import 'dart:math';

class CardsView extends StatefulWidget {
  const CardsView({super.key});

  @override
  State<CardsView> createState() => _CardsViewState();
}

class _CardsViewState extends State<CardsView>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scoreAnim;
  double _savingsGoal = 5000.0;
  final TextEditingController _goalController = TextEditingController();
  final TextEditingController _incomeController = TextEditingController();
  final TextEditingController _fixedNameController = TextEditingController();
  final TextEditingController _fixedAmountController = TextEditingController();
  final TextEditingController _fixedDayController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _scoreAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _goalController.dispose();
    _incomeController.dispose();
    _fixedNameController.dispose();
    _fixedAmountController.dispose();
    _fixedDayController.dispose();
    super.dispose();
  }

  // ── Budget Score (0-100) ───────────────────────
  int _getBudgetScore(ExpenseProvider p) {
    if (p.totalBudget == 0) return 0;
    final ratio = p.totalSpent / p.totalBudget;
    if (ratio <= 0.5) return 100;
    if (ratio <= 0.75) return 80;
    if (ratio <= 0.9) return 60;
    if (ratio <= 1.0) return 40;
    return max(0, (20 - ((ratio - 1.0) * 100)).toInt());
  }

  String _getGrade(int score) {
    if (score >= 90) return "A+";
    if (score >= 80) return "A";
    if (score >= 70) return "B+";
    if (score >= 60) return "B";
    if (score >= 50) return "C";
    return "D";
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return TColor.secondaryG;
    if (score >= 60) return TColor.primary10;
    if (score >= 40) return TColor.secondary50;
    return TColor.secondary;
  }

  String _getScoreMessage(int score) {
    if (score >= 90) return "Outstanding! You're a budgeting pro 🏆";
    if (score >= 80) return "Great job! Keep it up 💪";
    if (score >= 60) return "Doing okay, room to improve 📈";
    if (score >= 40) return "Watch your spending carefully ⚠️";
    return "Over budget — take action now 🚨";
  }

  // ── Weekly Bar Chart Data ──────────────────────
  List<Map<String, dynamic>> _getWeeklyData(ExpenseProvider p) {
    final now = DateTime.now();
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    List<Map<String, dynamic>> result = [];

    for (int i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final dayExpenses = p.expenses.where((e) =>
      e.date.year == day.year &&
          e.date.month == day.month &&
          e.date.day == day.day);
      final total =
      dayExpenses.fold(0.0, (sum, e) => sum + e.amount);
      result.add({
        'day': days[day.weekday - 1],
        'amount': total,
        'isToday': i == 0,
      });
    }
    return result;
  }

  // ── Spending Streak ────────────────────────────
  int _getStreak(ExpenseProvider p) {
    if (p.totalBudget == 0) return 0;
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final dailyLimit = p.totalBudget / daysInMonth;
    int streak = 0;

    for (int i = 0; i < 30; i++) {
      final day = now.subtract(Duration(days: i));
      final dayTotal = p.expenses
          .where((e) =>
      e.date.year == day.year &&
          e.date.month == day.month &&
          e.date.day == day.day)
          .fold(0.0, (sum, e) => sum + e.amount);
      if (dayTotal <= dailyLimit) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  // ── Smart Tips ─────────────────────────────────
  List<Map<String, dynamic>> _getSmartTips(ExpenseProvider p) {
    List<Map<String, dynamic>> tips = [];

    if (p.budgets.isEmpty) {
      tips.add({
        'icon': Icons.add_circle_outline,
        'color': TColor.primary,
        'tip': 'Add budget categories to start tracking your spending patterns.',
      });
      return tips;
    }

    // Highest category tip
    final sorted = List<Map<String, dynamic>>.from(p.budgets)
      ..sort((a, b) => (b["spend_amount"] as double)
          .compareTo(a["spend_amount"] as double));
    if ((sorted.first["spend_amount"] as double) > 0) {
      tips.add({
        'icon': Icons.trending_up,
        'color': TColor.secondary,
        'tip':
        '"${sorted.first["name"]}" is your biggest expense this month. Consider setting a stricter limit.',
      });
    }

    // Under-used budget
    // Under-used budget
    final underUsed = p.budgets.where((b) {
      final budget = b["total_budget"] as double;
      final spent = b["spend_amount"] as double;
      return budget > 0 && (spent / budget) < 0.1;
    }).toList();

    if (underUsed.isNotEmpty) {
      tips.add({
        'icon': Icons.savings_outlined,
        'color': TColor.secondaryG,
        'tip':
        '"${underUsed.first["name"]}" is barely used. You could reduce its budget and save more.',
      });
    }

    // Daily average tip
    final daysPassed = DateTime.now().day;
    if (daysPassed > 0 && p.totalSpent > 0) {
      final dailyAvg = p.totalSpent / daysPassed;
      tips.add({
        'icon': Icons.insights,
        'color': TColor.primary10,
        'tip':
        'Your daily average spend is ₹${dailyAvg.toStringAsFixed(0)}. Try keeping it under ₹${(p.totalBudget / 30).toStringAsFixed(0)} per day.',
      });
    }

    // Savings tip
    if (p.totalLeft > 0) {
      tips.add({
        'icon': Icons.lightbulb_outline,
        'color': TColor.secondaryG,
        'tip':
        'You have ₹${p.totalLeft.toStringAsFixed(0)} remaining. Transfer it to savings at month end!',
      });
    }

    return tips.take(3).toList();
  }

  // ── Achievements ───────────────────────────────
  List<Map<String, dynamic>> _getAchievements(
      ExpenseProvider p, int score, int streak) {
    return [
      {
        'icon': Icons.track_changes,
        'label': 'First Expense',
        'unlocked': p.expenses.isNotEmpty,
        'color': TColor.primary,
      },
      {
        'icon': Icons.category_outlined,
        'label': 'Categorized',
        'unlocked': p.budgets.length >= 3,
        'color': TColor.secondaryG,
      },
      {
        'icon': Icons.local_fire_department,
        'label': '3-Day Streak',
        'unlocked': streak >= 3,
        'color': TColor.secondary,
      },
      {
        'icon': Icons.workspace_premium,
        'label': 'Budget Pro',
        'unlocked': score >= 80,
        'color': TColor.primary10,
      },
      {
        'icon': Icons.savings,
        'label': 'Saver',
        'unlocked': p.totalLeft > 0 && p.totalBudget > 0,
        'color': TColor.secondaryG,
      },
      {
        'icon': Icons.emoji_events,
        'label': 'Week Streak',
        'unlocked': streak >= 7,
        'color': const Color(0xffFFD700),
      },
    ];
  }

  // ── Income Sheet ───────────────────────────────
  void _showIncomeSheet(ExpenseProvider provider) {
    _incomeController.text = provider.monthlyIncome > 0
        ? provider.monthlyIncome.toStringAsFixed(0)
        : '';
    showModalBottomSheet(
      context: context,
      backgroundColor: TColor.gray80,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: TColor.gray30,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Center(
              child: Text("Monthly Income",
                  style: TextStyle(
                      color: TColor.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: 20),
            Text("Net salary / income (₹)",
                style: TextStyle(color: TColor.gray30, fontSize: 12)),
            const SizedBox(height: 8),
            TextField(
              controller: _incomeController,
              keyboardType: TextInputType.number,
              autofocus: true,
              style: TextStyle(
                  color: TColor.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w700),
              decoration: InputDecoration(
                prefixText: "₹ ",
                prefixStyle: TextStyle(
                    color: TColor.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700),
                filled: true,
                fillColor: TColor.gray70.withOpacity(0.3),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                    BorderSide(color: TColor.border.withOpacity(0.1))),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                    BorderSide(color: TColor.border.withOpacity(0.1))),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: TColor.primary)),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: TColor.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () {
                  final income = double.tryParse(_incomeController.text);
                  if (income != null && income > 0) {
                    provider.setIncome(income);
                    Navigator.pop(context);
                  }
                },
                child: Text("Save Income",
                    style: TextStyle(
                        color: TColor.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Add Fixed Expense Sheet ────────────────────
  void _showAddFixedExpenseSheet(ExpenseProvider provider) {
    _fixedNameController.clear();
    _fixedAmountController.clear();
    _fixedDayController.clear();
    showModalBottomSheet(
      context: context,
      backgroundColor: TColor.gray80,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: TColor.gray30,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Center(
              child: Text("Add Fixed Expense",
                  style: TextStyle(
                      color: TColor.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: 20),
            Text("Name (e.g. Rent, EMI, Netflix)",
                style: TextStyle(color: TColor.gray30, fontSize: 12)),
            const SizedBox(height: 8),
            TextField(
              controller: _fixedNameController,
              autofocus: true,
              style: TextStyle(color: TColor.white, fontSize: 16),
              decoration: InputDecoration(
                hintText: "Expense name",
                hintStyle: TextStyle(color: TColor.gray50),
                filled: true,
                fillColor: TColor.gray70.withOpacity(0.3),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                    BorderSide(color: TColor.border.withOpacity(0.1))),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                    BorderSide(color: TColor.border.withOpacity(0.1))),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: TColor.primary)),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Amount (₹)",
                          style: TextStyle(color: TColor.gray30, fontSize: 12)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _fixedAmountController,
                        keyboardType: TextInputType.number,
                        style: TextStyle(color: TColor.white, fontSize: 16),
                        decoration: InputDecoration(
                          hintText: "0",
                          hintStyle: TextStyle(color: TColor.gray50),
                          filled: true,
                          fillColor: TColor.gray70.withOpacity(0.3),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                  color: TColor.border.withOpacity(0.1))),
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                  color: TColor.border.withOpacity(0.1))),
                          focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: TColor.primary)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Due Day (1–31)",
                          style: TextStyle(color: TColor.gray30, fontSize: 12)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _fixedDayController,
                        keyboardType: TextInputType.number,
                        style: TextStyle(color: TColor.white, fontSize: 16),
                        decoration: InputDecoration(
                          hintText: "1",
                          hintStyle: TextStyle(color: TColor.gray50),
                          filled: true,
                          fillColor: TColor.gray70.withOpacity(0.3),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                  color: TColor.border.withOpacity(0.1))),
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                  color: TColor.border.withOpacity(0.1))),
                          focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: TColor.primary)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: TColor.secondary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () {
                  final name = _fixedNameController.text.trim();
                  final amount = double.tryParse(_fixedAmountController.text);
                  final day = int.tryParse(_fixedDayController.text);
                  if (name.isNotEmpty &&
                      amount != null &&
                      amount > 0 &&
                      day != null &&
                      day >= 1 &&
                      day <= 31) {
                    provider.addFixedExpense(name, amount, day);
                    Navigator.pop(context);
                  }
                },
                child: Text("Add Fixed Expense",
                    style: TextStyle(
                        color: TColor.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Money Flow Timeline ────────────────────────
  Widget _buildMoneyFlowTimeline(ExpenseProvider provider) {
    final steps = <Map<String, dynamic>>[
      {
        'label': 'Salary',
        'value': provider.monthlyIncome,
        'color': TColor.primary,
        'icon': Icons.account_balance_wallet,
        'subtract': false,
      },
      ...provider.fixedExpenses.map((f) => <String, dynamic>{
        'label': f.name,
        'value': f.amount,
        'color': TColor.secondary,
        'icon': Icons.remove_circle_outline,
        'subtract': true,
      }),
      {
        'label': 'Usable Balance',
        'value': provider.getRemainingAfterFixed(),
        'color': TColor.secondaryG,
        'icon': Icons.check_circle_outline,
        'subtract': false,
      },
    ];

    return Column(
      children: steps.asMap().entries.map((entry) {
        final i = entry.key;
        final step = entry.value;
        final isLast = i == steps.length - 1;
        final color = step['color'] as Color;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.18),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(step['icon'] as IconData,
                      color: color, size: 14),
                ),
                if (!isLast)
                  Container(
                    width: 1.5,
                    height: 22,
                    color: TColor.gray60.withOpacity(0.4),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(step['label'] as String,
                        style: TextStyle(
                            color: isLast ? TColor.secondaryG : TColor.white,
                            fontSize: 12,
                            fontWeight: isLast
                                ? FontWeight.w700
                                : FontWeight.w400)),
                    Text(
                      "${step['subtract'] == true ? '−' : ''}₹${(step['value'] as double).toStringAsFixed(0)}",
                      style: TextStyle(
                          color: color,
                          fontSize: 12,
                          fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  void _showSetGoalSheet() {
    _goalController.text = _savingsGoal.toStringAsFixed(0);
    showModalBottomSheet(
      context: context,
      backgroundColor: TColor.gray80,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: TColor.gray30,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Center(
              child: Text("Set Savings Goal",
                  style: TextStyle(
                      color: TColor.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: 20),
            Text("Monthly Savings Goal (₹)",
                style: TextStyle(color: TColor.gray30, fontSize: 12)),
            const SizedBox(height: 8),
            TextField(
              controller: _goalController,
              keyboardType: TextInputType.number,
              autofocus: true,
              style: TextStyle(
                  color: TColor.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w700),
              decoration: InputDecoration(
                prefixText: "₹ ",
                prefixStyle: TextStyle(
                    color: TColor.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700),
                filled: true,
                fillColor: TColor.gray70.withOpacity(0.3),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                    BorderSide(color: TColor.border.withOpacity(0.1))),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                    BorderSide(color: TColor.border.withOpacity(0.1))),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: TColor.primary)),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: TColor.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () {
                  final goal = double.tryParse(_goalController.text);
                  if (goal != null && goal > 0) {
                    setState(() => _savingsGoal = goal);
                    Navigator.pop(context);
                  }
                },
                child: Text("Set Goal",
                    style: TextStyle(
                        color: TColor.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ExpenseProvider>(context);
    final score = _getBudgetScore(provider);
    final streak = _getStreak(provider);
    final weeklyData = _getWeeklyData(provider);
    final tips = _getSmartTips(provider);
    final achievements = _getAchievements(provider, score, streak);
    final scoreColor = _getScoreColor(score);
    final maxWeekly = weeklyData
        .map((d) => d['amount'] as double)
        .fold(0.0, max);
    final savedAmount = provider.totalLeft > 0 ? provider.totalLeft : 0.0;
    final goalProgress =
    _savingsGoal > 0 ? (savedAmount / _savingsGoal).clamp(0.0, 1.0) : 0.0;

    return Scaffold(
      backgroundColor: TColor.gray,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Header ───────────────────────────
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 8),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Intelligence",
                            style: TextStyle(
                                color: TColor.gray30, fontSize: 16)),
                      ],
                    ),
                    Row(
                      children: [
                        const Spacer(),
                        IconButton(
                            onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                    const SettingsView())),
                            icon: Image.asset("assets/img/settings.png",
                                width: 25,
                                height: 25,
                                color: TColor.gray30)),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ── Budget Score Card ─────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 8),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      scoreColor.withOpacity(0.2),
                      TColor.gray80.withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: scoreColor.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    // Animated score circle
                    AnimatedBuilder(
                      animation: _scoreAnim,
                      builder: (context, child) {
                        final animScore =
                        (score * _scoreAnim.value).toInt();
                        return SizedBox(
                          width: 90,
                          height: 90,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              CircularProgressIndicator(
                                value: score / 100 * _scoreAnim.value,
                                strokeWidth: 7,
                                backgroundColor:
                                TColor.gray60.withOpacity(0.3),
                                valueColor: AlwaysStoppedAnimation(
                                    scoreColor),
                              ),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    "$animScore",
                                    style: TextStyle(
                                        color: TColor.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.w800),
                                  ),
                                  Text(
                                    _getGrade(animScore),
                                    style: TextStyle(
                                        color: scoreColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Budget Score",
                              style: TextStyle(
                                  color: TColor.gray30,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          Text(
                            _getScoreMessage(score),
                            style: TextStyle(
                                color: TColor.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                height: 1.4),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Icon(Icons.local_fire_department,
                                  color: TColor.secondary, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                "$streak day streak",
                                style: TextStyle(
                                    color: TColor.secondary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Weekly Bar Chart ──────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 8),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: TColor.gray60.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: TColor.border.withOpacity(0.07)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                      children: [
                        Text("This Week",
                            style: TextStyle(
                                color: TColor.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w700)),
                        Text(
                          "₹${weeklyData.fold(0.0, (sum, d) => sum + (d['amount'] as double)).toStringAsFixed(0)} total",
                          style: TextStyle(
                              color: TColor.gray30, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 130,
                      child: Row(
                        crossAxisAlignment:
                        CrossAxisAlignment.end,
                        mainAxisAlignment:
                        MainAxisAlignment.spaceAround,
                        children: weeklyData.map((d) {
                          final amount = d['amount'] as double;
                          final isToday = d['isToday'] as bool;
                          // Max bar height is 72 so label (12) + spacing (4)
                          // + day label (14) + spacing (6) = 36px safely fits
                          // within the 130px SizedBox.
                          final barHeight = maxWeekly > 0
                              ? (amount / maxWeekly) * 72
                              : 0.0;
                          return AnimatedBuilder(
                            animation: _scoreAnim,
                            builder: (context, child) {
                              return Column(
                                mainAxisAlignment:
                                MainAxisAlignment.end,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (amount > 0)
                                    Text(
                                      "₹${amount.toStringAsFixed(0)}",
                                      style: TextStyle(
                                          color: isToday
                                              ? TColor.primary
                                              : TColor.gray40,
                                          fontSize: 8,
                                          fontWeight:
                                          FontWeight.w600),
                                    ),
                                  const SizedBox(height: 4),
                                  Container(
                                    width: 28,
                                    height: max(
                                        4,
                                        barHeight *
                                            _scoreAnim.value),
                                    decoration: BoxDecoration(
                                      color: isToday
                                          ? TColor.primary
                                          : amount > 0
                                          ? TColor.primary
                                          .withOpacity(0.4)
                                          : TColor.gray60
                                          .withOpacity(0.3),
                                      borderRadius:
                                      BorderRadius.circular(6),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    d['day'] as String,
                                    style: TextStyle(
                                        color: isToday
                                            ? TColor.white
                                            : TColor.gray40,
                                        fontSize: 10,
                                        fontWeight: isToday
                                            ? FontWeight.w700
                                            : FontWeight.w400),
                                  ),
                                ],
                              );
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Savings Goal ──────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 8),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: TColor.secondaryG.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: TColor.secondaryG.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.savings_outlined,
                                color: TColor.secondaryG,
                                size: 18),
                            const SizedBox(width: 8),
                            Text("Savings Goal",
                                style: TextStyle(
                                    color: TColor.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700)),
                          ],
                        ),
                        GestureDetector(
                          onTap: _showSetGoalSheet,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: TColor.secondaryG
                                  .withOpacity(0.15),
                              borderRadius:
                              BorderRadius.circular(8),
                              border: Border.all(
                                  color: TColor.secondaryG
                                      .withOpacity(0.3)),
                            ),
                            child: Text("Set Goal",
                                style: TextStyle(
                                    color: TColor.secondaryG,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Text("Saved so far",
                                style: TextStyle(
                                    color: TColor.gray40,
                                    fontSize: 11)),
                            Text(
                              "₹${savedAmount.toStringAsFixed(0)}",
                              style: TextStyle(
                                  color: TColor.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.end,
                          children: [
                            Text("Goal",
                                style: TextStyle(
                                    color: TColor.gray40,
                                    fontSize: 11)),
                            Text(
                              "₹${_savingsGoal.toStringAsFixed(0)}",
                              style: TextStyle(
                                  color: TColor.gray30,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Stack(
                      children: [
                        Container(
                          height: 8,
                          decoration: BoxDecoration(
                            color: TColor.gray60.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        AnimatedBuilder(
                          animation: _scoreAnim,
                          builder: (context, child) {
                            return FractionallySizedBox(
                              widthFactor:
                              goalProgress * _scoreAnim.value,
                              child: Container(
                                height: 8,
                                decoration: BoxDecoration(
                                  color: TColor.secondaryG,
                                  borderRadius:
                                  BorderRadius.circular(4),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "${(goalProgress * 100).toStringAsFixed(0)}% of goal reached",
                      style: TextStyle(
                          color: TColor.secondaryG, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),

            // ── Achievements ──────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Achievements",
                          style: TextStyle(
                              color: TColor.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700)),
                      Text(
                        "${achievements.where((a) => a['unlocked'] as bool).length}/${achievements.length} unlocked",
                        style: TextStyle(
                            color: TColor.gray40, fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 1,
                    ),
                    itemCount: achievements.length,
                    itemBuilder: (context, index) {
                      final a = achievements[index];
                      final unlocked = a['unlocked'] as bool;
                      final color = a['color'] as Color;
                      return Container(
                        decoration: BoxDecoration(
                          color: unlocked
                              ? color.withOpacity(0.12)
                              : TColor.gray60.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: unlocked
                                ? color.withOpacity(0.3)
                                : TColor.border.withOpacity(0.05),
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment:
                          MainAxisAlignment.center,
                          children: [
                            Icon(
                              a['icon'] as IconData,
                              color: unlocked
                                  ? color
                                  : TColor.gray60,
                              size: 28,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              a['label'] as String,
                              style: TextStyle(
                                  color: unlocked
                                      ? TColor.white
                                      : TColor.gray50,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600),
                              textAlign: TextAlign.center,
                            ),
                            if (!unlocked)
                              Icon(Icons.lock_outline,
                                  color: TColor.gray60, size: 12),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // ── Smart Tips ────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Smart Tips",
                      style: TextStyle(
                          color: TColor.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  ...tips.map((tip) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: (tip['color'] as Color)
                          .withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: (tip['color'] as Color)
                              .withOpacity(0.2)),
                    ),
                    child: Row(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Icon(tip['icon'] as IconData,
                            color: tip['color'] as Color,
                            size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            tip['tip'] as String,
                            style: TextStyle(
                                color: TColor.white,
                                fontSize: 12,
                                height: 1.5),
                          ),
                        ),
                      ],
                    ),
                  )),
                ],
              ),
            ),

            // ── Daily Budget Status ───────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 8),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: TColor.primary.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: TColor.primary.withOpacity(0.15)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: TColor.primary.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.today,
                          color: TColor.primary, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Text("Daily Safe-to-Spend",
                              style: TextStyle(
                                  color: TColor.gray30,
                                  fontSize: 11)),
                          const SizedBox(height: 4),
                          Text(
                            provider.totalBudget > 0
                                ? "₹${(provider.totalLeft / max(1, DateTime(DateTime.now().year, DateTime.now().month + 1, 0).day - DateTime.now().day + 1)).toStringAsFixed(0)} / day"
                                : "Set budgets first",
                            style: TextStyle(
                                color: provider.totalLeft > 0
                                    ? TColor.white
                                    : TColor.secondary,
                                fontSize: 22,
                                fontWeight: FontWeight.w800),
                          ),
                          Text(
                            "${DateTime(DateTime.now().year, DateTime.now().month + 1, 0).day - DateTime.now().day + 1} days remaining in month",
                            style: TextStyle(
                                color: TColor.gray40,
                                fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Money Flow System ─────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Money Flow",
                          style: TextStyle(
                              color: TColor.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700)),
                      GestureDetector(
                        onTap: () => _showIncomeSheet(provider),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: TColor.primary.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: TColor.primary.withOpacity(0.3)),
                          ),
                          child: Text(
                            provider.monthlyIncome > 0
                                ? "Edit Income"
                                : "Set Income",
                            style: TextStyle(
                                color: TColor.primary,
                                fontSize: 11,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Income card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: TColor.primary.withOpacity(0.09),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: TColor.primary.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: TColor.primary.withOpacity(0.18),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.account_balance_wallet,
                              color: TColor.primary, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Monthly Income",
                                  style: TextStyle(
                                      color: TColor.gray40, fontSize: 11)),
                              const SizedBox(height: 2),
                              Text(
                                provider.monthlyIncome > 0
                                    ? "₹${provider.monthlyIncome.toStringAsFixed(0)}"
                                    : "Not set — tap Edit Income",
                                style: TextStyle(
                                    color: provider.monthlyIncome > 0
                                        ? TColor.white
                                        : TColor.gray50,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Fixed expenses list
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: TColor.secondary.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: TColor.secondary.withOpacity(0.15)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Fixed Expenses",
                                style: TextStyle(
                                    color: TColor.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600)),
                            GestureDetector(
                              onTap: () => _showAddFixedExpenseSheet(provider),
                              child: Icon(Icons.add_circle_outline,
                                  color: TColor.secondary, size: 20),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        if (provider.fixedExpenses.isEmpty)
                          Text(
                            "No fixed expenses yet. Tap + to add rent, EMI, subscriptions.",
                            style: TextStyle(
                                color: TColor.gray50, fontSize: 11, height: 1.5),
                          )
                        else
                          ...provider.fixedExpenses.asMap().entries.map((entry) {
                            final i = entry.key;
                            final f = entry.value;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: TColor.secondary,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(f.name,
                                        style: TextStyle(
                                            color: TColor.white,
                                            fontSize: 12)),
                                  ),
                                  Text(
                                    "Day ${f.dayOfMonth}",
                                    style: TextStyle(
                                        color: TColor.gray50, fontSize: 10),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    "₹${f.amount.toStringAsFixed(0)}",
                                    style: TextStyle(
                                        color: TColor.secondary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: () =>
                                        provider.removeFixedExpense(i),
                                    child: Icon(Icons.close,
                                        color: TColor.gray50, size: 14),
                                  ),
                                ],
                              ),
                            );
                          }),
                        if (provider.fixedExpenses.isNotEmpty) ...[
                          const Divider(height: 16, thickness: 0.3),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("Total Fixed",
                                  style: TextStyle(
                                      color: TColor.gray40, fontSize: 11)),
                              Text(
                                "₹${provider.totalFixedExpenses.toStringAsFixed(0)}",
                                style: TextStyle(
                                    color: TColor.secondary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Remaining + Daily safe spend
                  if (provider.monthlyIncome > 0)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: TColor.secondaryG.withOpacity(0.07),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: TColor.secondaryG.withOpacity(0.2)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Usable Balance",
                                      style: TextStyle(
                                          color: TColor.gray40, fontSize: 11)),
                                  const SizedBox(height: 2),
                                  Text(
                                    "₹${provider.getRemainingAfterFixed().toStringAsFixed(0)}",
                                    style: TextStyle(
                                        color: TColor.secondaryG,
                                        fontSize: 22,
                                        fontWeight: FontWeight.w800),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text("Daily Safe Spend",
                                      style: TextStyle(
                                          color: TColor.gray40, fontSize: 11)),
                                  const SizedBox(height: 2),
                                  Text(
                                    "₹${provider.getDailySafeSpend().toStringAsFixed(0)}/day",
                                    style: TextStyle(
                                        color: TColor.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Timeline: Salary → Fixed → Usable
                          _buildMoneyFlowTimeline(provider),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 110),
          ],
        ),
      ),
    );
  }
}