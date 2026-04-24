import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trackizer/common/color_extension.dart';
import 'package:trackizer/common/expense_provider.dart';
import 'package:trackizer/common_widget/custom_arc_painter.dart';
import 'package:trackizer/common_widget/segment_button.dart';
import 'package:trackizer/common_widget/status_button.dart';
import 'package:trackizer/view/add_subscription/add_subscription_view.dart';
import '../settings/settings_view.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  bool isExpenses = true;

  // ── Smart Insight ──────────────────────────────
  Map<String, dynamic> _getSmartInsight(ExpenseProvider provider) {
    if (provider.budgets.isEmpty) {
      return {
        "icon": Icons.lightbulb_outline,
        "color": TColor.primary10,
        "text": "Add categories in Budgets to start tracking your spending.",
      };
    }

    final ratio = provider.totalBudget > 0
        ? provider.totalSpent / provider.totalBudget
        : 0.0;

    // Over budget
    if (ratio > 1.0) {
      return {
        "icon": Icons.warning_amber_rounded,
        "color": TColor.secondary,
        "text":
        "You've exceeded your total budget by ₹${(provider.totalSpent - provider.totalBudget).toStringAsFixed(0)}. Consider cutting back immediately.",
      };
    }

    // Any category over budget
    final overBudget = provider.budgets.where((b) =>
    (b["spend_amount"] as double) > (b["total_budget"] as double));
    if (overBudget.isNotEmpty) {
      final name = overBudget.first["name"];
      return {
        "icon": Icons.error_outline,
        "color": TColor.secondary,
        "text":
        "\"$name\" has exceeded its budget. Review your spending there.",
      };
    }

    // Near limit (>=75%)
    final nearLimit = provider.budgets.where((b) {
      final budget = b["total_budget"] as double;
      final spent = b["spend_amount"] as double;
      return budget > 0 && (spent / budget) >= 0.75;
    });
    if (nearLimit.isNotEmpty) {
      final name = nearLimit.first["name"];
      return {
        "icon": Icons.trending_up,
        "color": TColor.secondary50,
        "text":
        "\"$name\" is at 75%+ of its budget. You're running low — slow down spending here.",
      };
    }

    // Predict end of month spend
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final daysPassed = now.day;
    if (daysPassed > 0 && provider.totalSpent > 0) {
      final predicted =
          (provider.totalSpent / daysPassed) * daysInMonth;
      if (predicted > provider.totalBudget) {
        return {
          "icon": Icons.insights,
          "color": TColor.primary10,
          "text":
          "At this pace you'll spend ₹${predicted.toStringAsFixed(0)} by month end — ₹${(predicted - provider.totalBudget).toStringAsFixed(0)} over budget.",
        };
      }
    }

    // All good
    return {
      "icon": Icons.check_circle_outline,
      "color": TColor.secondaryG,
      "text": ratio < 0.3
          ? "Great start! You've used ${(ratio * 100).toStringAsFixed(0)}% of your budget. Keep it up."
          : "You're on track. ${(100 - ratio * 100).toStringAsFixed(0)}% of your budget remains this month.",
    };
  }

  // ── Spending Prediction ────────────────────────
  String _getPrediction(ExpenseProvider provider) {
    if (provider.totalSpent == 0) return "Not enough data yet";
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final daysPassed = now.day;
    final predicted =
        (provider.totalSpent / daysPassed) * daysInMonth;
    return "₹${predicted.toStringAsFixed(0)}";
  }

  // ── Today vs Yesterday ────────────────────────
  Map<String, double> _getTodayYesterday(ExpenseProvider provider) {
    final now = DateTime.now();
    final today = provider.expenses.where((e) =>
    e.date.year == now.year &&
        e.date.month == now.month &&
        e.date.day == now.day);
    final yesterday = provider.expenses.where((e) =>
    e.date.year == now.year &&
        e.date.month == now.month &&
        e.date.day == now.day - 1);
    return {
      "today": today.fold(0.0, (sum, e) => sum + e.amount),
      "yesterday": yesterday.fold(0.0, (sum, e) => sum + e.amount),
    };
  }

  // ── Danger Categories (>=75% or over) ─────────
  List<Map<String, dynamic>> _getDangerCategories(
      ExpenseProvider provider) {
    return provider.budgets.where((b) {
      final budget = b["total_budget"] as double;
      final spent = b["spend_amount"] as double;
      return budget > 0 && (spent / budget) >= 0.75;
    }).take(3).toList();
  }

  // ── Money Flow Chip ────────────────────────────
  Widget _homeFlowChip(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    color: TColor.gray40,
                    fontSize: 9,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(value,
                style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w700),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ExpenseProvider>(context);
    var media = MediaQuery.sizeOf(context);

    // ── New salary-based arc logic ────────────────
    // spendable = netUsableBalance − savingsGoal (floored at 0)
    final double spendableAfterGoal = (provider.getNetUsableBalance() -
        provider.savingsGoal)
        .clamp(0.0, double.infinity);
    double arcEnd = spendableAfterGoal > 0
        ? ((provider.totalSpent / spendableAfterGoal) * 270)
        .clamp(0.0, 270.0)
        : 0.0;

    String topCategory = "None";
    double topSpent = 0;
    for (var b in provider.budgets) {
      if ((b["spend_amount"] as double) > topSpent) {
        topSpent = b["spend_amount"] as double;
        topCategory = b["name"];
      }
    }

    final insight = _getSmartInsight(provider);
    final todayYesterday = _getTodayYesterday(provider);
    final dangerCats = _getDangerCategories(provider);
    final prediction = _getPrediction(provider);
    final last3 = provider.recentExpenses.take(3).toList();

    return Scaffold(
      backgroundColor: TColor.gray,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Top Arc Section ──────────────────
            Container(
              height: media.width * 1.1,
              decoration: BoxDecoration(
                  color: TColor.gray70.withOpacity(0.5),
                  borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(25),
                      bottomRight: Radius.circular(25))),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Image.asset("assets/img/home_bg.png"),
                  Stack(
                    alignment: Alignment.topCenter,
                    children: [
                      Container(
                        padding: EdgeInsets.only(
                            bottom: media.width * 0.05),
                        width: media.width * 0.72,
                        height: media.width * 0.72,
                        child: CustomPaint(
                          painter: CustomArcPainter(end: arcEnd),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: Row(
                          children: [
                            const Spacer(),
                            IconButton(
                                onPressed: () {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                          const SettingsView()));
                                },
                                icon: Image.asset(
                                    "assets/img/settings.png",
                                    width: 25,
                                    height: 25,
                                    color: TColor.gray30))
                          ],
                        ),
                      ),
                    ],
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(height: media.width * 0.05),
                      Image.asset("assets/img/app_logo.png",
                          width: media.width * 0.25,
                          fit: BoxFit.contain),
                      SizedBox(height: media.width * 0.07),
                      Text(
                        "₹${provider.totalSpent.toStringAsFixed(2)}",
                        style: TextStyle(
                            color: TColor.white,
                            fontSize: 40,
                            fontWeight: FontWeight.w700),
                      ),
                      SizedBox(height: media.width * 0.02),
                      Text(
                        "spent of ₹${spendableAfterGoal.toStringAsFixed(0)} usable money",
                        style: TextStyle(
                            color: TColor.gray40,
                            fontSize: 12,
                            fontWeight: FontWeight.w600),
                      ),
                      SizedBox(height: media.width * 0.05),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: TColor.border.withOpacity(0.15)),
                          color: TColor.gray60.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          "₹${(spendableAfterGoal - provider.totalSpent).toStringAsFixed(2)} remaining",
                          style: TextStyle(
                              color: (spendableAfterGoal - provider.totalSpent) < 0
                                  ? TColor.secondary
                                  : TColor.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        const Spacer(),
                        Row(
                          children: [
                            Expanded(
                              child: StatusButton(
                                title: "Categories",
                                value:
                                "${provider.budgets.length}",
                                statusColor: TColor.secondary,
                                onPressed: () {},
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: StatusButton(
                                title: "Top spend",
                                value: topCategory.length > 8
                                    ? "${topCategory.substring(0, 8)}.."
                                    : topCategory,
                                statusColor: TColor.primary10,
                                onPressed: () {},
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: StatusButton(
                                title: "Remaining",
                                value:
                                "₹${provider.totalLeft.toStringAsFixed(0)}",
                                statusColor: TColor.secondaryG,
                                onPressed: () {},
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Smart Insight Card ───────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: (insight["color"] as Color).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color:
                      (insight["color"] as Color).withOpacity(0.25)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(insight["icon"] as IconData,
                        color: insight["color"] as Color, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Smart Insight",
                              style: TextStyle(
                                  color: insight["color"] as Color,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5)),
                          const SizedBox(height: 4),
                          Text(insight["text"] as String,
                              style: TextStyle(
                                  color: TColor.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  height: 1.4)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Money Flow Summary ───────────────
            if (provider.monthlyIncome > 0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        TColor.secondaryG.withOpacity(0.12),
                        TColor.primary.withOpacity(0.06),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: TColor.secondaryG.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.account_balance_wallet_outlined,
                              color: TColor.secondaryG, size: 14),
                          const SizedBox(width: 6),
                          Text("Money Flow",
                              style: TextStyle(
                                  color: TColor.secondaryG,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Text("Spendable After Savings",
                                    style: TextStyle(
                                        color: TColor.gray40,
                                        fontSize: 11)),
                                const SizedBox(height: 4),
                                Text(
                                  "₹${spendableAfterGoal.toStringAsFixed(0)}",
                                  style: TextStyle(
                                      color: TColor.secondaryG,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 40,
                            color: TColor.gray60.withOpacity(0.4),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Text("Daily Safe Spend",
                                    style: TextStyle(
                                        color: TColor.gray40,
                                        fontSize: 11)),
                                const SizedBox(height: 4),
                                Text(
                                  "₹${(spendableAfterGoal > 0 ? spendableAfterGoal / (DateTime(DateTime.now().year, DateTime.now().month + 1, 0).day - DateTime.now().day + 1).clamp(1, 31) : 0).toStringAsFixed(0)}/day",
                                  style: TextStyle(
                                      color: TColor.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _homeFlowChip(
                            "Income",
                            "₹${provider.monthlyIncome.toStringAsFixed(0)}",
                            TColor.primary,
                          ),
                          const SizedBox(width: 8),
                          _homeFlowChip(
                            "Deductions",
                            "−₹${provider.getTotalDeductions().toStringAsFixed(0)}",
                            TColor.secondary,
                          ),
                          const SizedBox(width: 8),
                          _homeFlowChip(
                            "Tax",
                            "−₹${provider.calculateTax(provider.monthlyIncome).toStringAsFixed(0)}",
                            TColor.secondary50,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

            // ── Today vs Yesterday ───────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: TColor.gray60.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: TColor.border.withOpacity(0.07)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Today",
                              style: TextStyle(
                                  color: TColor.gray40, fontSize: 11)),
                          const SizedBox(height: 4),
                          Text(
                            "₹${todayYesterday["today"]!.toStringAsFixed(2)}",
                            style: TextStyle(
                                color: TColor.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                    Container(
                        width: 1,
                        height: 36,
                        color: TColor.border.withOpacity(0.1)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text("Yesterday",
                              style: TextStyle(
                                  color: TColor.gray40, fontSize: 11)),
                          const SizedBox(height: 4),
                          Text(
                            "₹${todayYesterday["yesterday"]!.toStringAsFixed(2)}",
                            style: TextStyle(
                                color: TColor.gray30,
                                fontSize: 20,
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Trend arrow
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: todayYesterday["today"]! >
                            todayYesterday["yesterday"]!
                            ? TColor.secondary.withOpacity(0.15)
                            : TColor.secondaryG.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        todayYesterday["today"]! >
                            todayYesterday["yesterday"]!
                            ? Icons.trending_up
                            : Icons.trending_down,
                        color: todayYesterday["today"]! >
                            todayYesterday["yesterday"]!
                            ? TColor.secondary
                            : TColor.secondaryG,
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Danger Categories ────────────────
            if (dangerCats.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        color: TColor.secondary, size: 16),
                    const SizedBox(width: 6),
                    Text("Danger Categories",
                        style: TextStyle(
                            color: TColor.secondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              ...dangerCats.map((b) {
                final spent = b["spend_amount"] as double;
                final budget = b["total_budget"] as double;
                final ratio =
                budget > 0 ? (spent / budget).clamp(0.0, 1.0) : 0.0;
                final isOver = spent > budget;
                final color = b["color"] as Color;
                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: TColor.secondary.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: TColor.secondary.withOpacity(0.2)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(Icons.category_outlined,
                                  color: color, size: 18),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(b["name"],
                                  style: TextStyle(
                                      color: TColor.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600)),
                            ),
                            Text(
                              isOver
                                  ? "OVER"
                                  : "${(ratio * 100).toStringAsFixed(0)}%",
                              style: TextStyle(
                                  color: TColor.secondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: ratio,
                          backgroundColor: TColor.gray60,
                          valueColor: AlwaysStoppedAnimation(
                              isOver ? TColor.secondary : color),
                          minHeight: 3,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                                "₹${spent.toStringAsFixed(0)} spent",
                                style: TextStyle(
                                    color: TColor.gray30,
                                    fontSize: 10)),
                            Text("of ₹${budget.toStringAsFixed(0)}",
                                style: TextStyle(
                                    color: TColor.gray40,
                                    fontSize: 10)),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 8),
            ],

            // ── Quick Actions ────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                              const AddSubScriptionView())),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 14),
                        decoration: BoxDecoration(
                          color: TColor.primary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: TColor.primary.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_circle_outline,
                                color: TColor.primary, size: 18),
                            const SizedBox(width: 8),
                            Text("Add Expense",
                                style: TextStyle(
                                    color: TColor.primary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        if (provider.expenses.isEmpty) {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(SnackBar(
                            content: const Text("No recent expense to repeat"),
                            backgroundColor: TColor.secondary,
                          ));
                          return;
                        }
                        final last = provider.expenses.last;
                        final idx = provider.budgets.indexWhere(
                                (b) => b["name"] == last.category);
                        if (idx >= 0) {
                          provider.addExpense(
                              idx, last.amount, last.note);
                          ScaffoldMessenger.of(context)
                              .showSnackBar(SnackBar(
                            content: Text(
                                "✅ Repeated ₹${last.amount.toStringAsFixed(2)} in ${last.category}"),
                            backgroundColor: Colors.green.shade700,
                          ));
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 14),
                        decoration: BoxDecoration(
                          color: TColor.gray60.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: TColor.border.withOpacity(0.1)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.replay,
                                color: TColor.gray30, size: 18),
                            const SizedBox(width: 8),
                            Text("Repeat Last",
                                style: TextStyle(
                                    color: TColor.gray30,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Spending Prediction ──────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: TColor.primary.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: TColor.primary.withOpacity(0.15)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.auto_graph,
                        color: TColor.primary10, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Month-end Prediction",
                              style: TextStyle(
                                  color: TColor.gray30,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(height: 2),
                          Text(
                            "At current pace: $prediction",
                            style: TextStyle(
                                color: TColor.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      "of ₹${provider.totalBudget.toStringAsFixed(0)}",
                      style: TextStyle(
                          color: TColor.gray40, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Segment Tabs ─────────────────────
            Container(
              margin: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 4),
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 8),
              height: 50,
              decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(15)),
              child: Row(
                children: [
                  Expanded(
                    child: SegmentButton(
                      title: "Recent Expenses",
                      isActive: isExpenses,
                      onPressed: () =>
                          setState(() => isExpenses = true),
                    ),
                  ),
                  Expanded(
                    child: SegmentButton(
                      title: "By Category",
                      isActive: !isExpenses,
                      onPressed: () =>
                          setState(() => isExpenses = false),
                    ),
                  ),
                ],
              ),
            ),

            // ── Recent Expenses (last 3) ─────────
            if (isExpenses)
              last3.isEmpty
                  ? Padding(
                padding: const EdgeInsets.all(30),
                child: Column(
                  children: [
                    Icon(Icons.receipt_long,
                        color: TColor.gray50, size: 40),
                    const SizedBox(height: 10),
                    Text("No expenses yet",
                        style: TextStyle(
                            color: TColor.gray30,
                            fontSize: 14)),
                    const SizedBox(height: 4),
                    Text(
                      "Tap + to add your first expense",
                      style: TextStyle(
                          color: TColor.gray50, fontSize: 12),
                    ),
                  ],
                ),
              )
                  : ListView.builder(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 8),
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: last3.length,
                  itemBuilder: (context, index) {
                    final exp = last3[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        border: Border.all(
                            color:
                            TColor.border.withOpacity(0.05)),
                        color: TColor.gray60.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: exp.color.withOpacity(0.15),
                              borderRadius:
                              BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.receipt_outlined,
                                color: exp.color, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Text(
                                  exp.note.isEmpty
                                      ? exp.category
                                      : exp.note,
                                  style: TextStyle(
                                      color: TColor.white,
                                      fontSize: 14,
                                      fontWeight:
                                      FontWeight.w600),
                                ),
                                Text(exp.category,
                                    style: TextStyle(
                                        color: TColor.gray30,
                                        fontSize: 12)),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.end,
                            children: [
                              Text(
                                "₹${exp.amount.toStringAsFixed(2)}",
                                style: TextStyle(
                                    color: TColor.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700),
                              ),
                              Text(
                                "${exp.date.day}/${exp.date.month}",
                                style: TextStyle(
                                    color: TColor.gray40,
                                    fontSize: 11),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),

            // ── By Category Tab ──────────────────
            if (!isExpenses)
              ListView.builder(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 8),
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: provider.budgets.length,
                  itemBuilder: (context, index) {
                    final item = provider.budgets[index];
                    final spent = item["spend_amount"] as double;
                    final budget = item["total_budget"] as double;
                    final progress = budget > 0
                        ? (spent / budget).clamp(0.0, 1.0)
                        : 0.0;
                    final color = item["color"] as Color;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: TColor.border.withOpacity(0.05)),
                        color: TColor.gray60.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.15),
                                  borderRadius:
                                  BorderRadius.circular(12),
                                ),
                                child: Icon(Icons.category_outlined,
                                    color: color, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    Text(item["name"],
                                        style: TextStyle(
                                            color: TColor.white,
                                            fontSize: 14,
                                            fontWeight:
                                            FontWeight.w600)),
                                    Text(
                                        "₹${(budget - spent).toStringAsFixed(2)} left",
                                        style: TextStyle(
                                            color: TColor.gray30,
                                            fontSize: 12)),
                                  ],
                                ),
                              ),
                              Text("₹${spent.toStringAsFixed(2)}",
                                  style: TextStyle(
                                      color: TColor.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          LinearProgressIndicator(
                            backgroundColor: TColor.gray60,
                            valueColor:
                            AlwaysStoppedAnimation(color),
                            minHeight: 3,
                            value: progress,
                          ),
                        ],
                      ),
                    );
                  }),

            const SizedBox(height: 110),
          ],
        ),
      ),
    );
  }
}