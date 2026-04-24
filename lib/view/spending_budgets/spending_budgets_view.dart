import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trackizer/common/color_extension.dart';
import 'package:trackizer/common/expense_provider.dart';
import 'package:trackizer/common_widget/budgets_row.dart';
import 'package:trackizer/common_widget/custom_arc_180_painter.dart';
import '../settings/settings_view.dart';

class SpendingBudgetsView extends StatefulWidget {
  const SpendingBudgetsView({super.key});

  @override
  State<SpendingBudgetsView> createState() => _SpendingBudgetsViewState();
}

class _SpendingBudgetsViewState extends State<SpendingBudgetsView> {
  final List<Color> categoryColors = [
    const Color(0xff00FAD9),
    const Color(0xffFF7966),
    const Color(0xffFFA699),
    const Color(0xffAD7BFF),
    const Color(0xff924EFF),
    const Color(0xffC9A7FF),
  ];

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _budgetController = TextEditingController();
  final TextEditingController _expenseController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  int _selectedColorIndex = 0;

  List<ArcValueModel> _getArcValues(ExpenseProvider provider, double spendableAfterGoal) {
    if (spendableAfterGoal == 0) return [];
    List<ArcValueModel> arcs = [];
    for (var item in provider.budgets) {
      double spent = item["spend_amount"] as double;
      double ratio = (spent / spendableAfterGoal) * 160;
      if (ratio > 0) {
        arcs.add(ArcValueModel(
          color: item["color"] as Color,
          value: ratio.clamp(5.0, 160.0),
        ));
      }
    }
    return arcs;
  }

  String _getStatusMessage(ExpenseProvider provider, double spendableAfterGoal) {
    if (spendableAfterGoal == 0) return "Set up your income 👆";
    final ratio = provider.totalSpent / spendableAfterGoal;
    if (ratio > 1.0) return "⚠️ You are over budget!";
    if (ratio >= 0.9) return "🚨 Almost out of budget!";
    if (ratio >= 0.75) return "⚠️ 75% of budget used";
    if (ratio >= 0.5) return "👀 Half of budget spent";
    return "Your budgets are on track 👍";
  }

  Color _getStatusColor(ExpenseProvider provider, double spendableAfterGoal) {
    if (spendableAfterGoal == 0) return TColor.white;
    final ratio = provider.totalSpent / spendableAfterGoal;
    if (ratio > 1.0) return TColor.secondary;
    if (ratio >= 0.9) return TColor.secondary;
    if (ratio >= 0.75) return TColor.secondary50;
    return TColor.white;
  }

  void _showAddExpenseSheet(BuildContext context, int index) {
    _expenseController.clear();
    _noteController.clear();
    final provider = Provider.of<ExpenseProvider>(context, listen: false);
    final item = provider.budgets[index];

    showModalBottomSheet(
      context: context,
      backgroundColor: TColor.gray80,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
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
                child: Text(
                  "Add Expense — ${item["name"]}",
                  style: TextStyle(
                      color: TColor.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  "₹${((item["total_budget"] as double) - (item["spend_amount"] as double)).toStringAsFixed(2)} left of ₹${(item["total_budget"] as double).toStringAsFixed(2)}",
                  style: TextStyle(color: TColor.gray30, fontSize: 12),
                ),
              ),
              const SizedBox(height: 20),
              Text("Amount (₹)",
                  style: TextStyle(color: TColor.gray30, fontSize: 12)),
              const SizedBox(height: 6),
              TextField(
                controller: _expenseController,
                keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
                autofocus: true,
                style: TextStyle(
                    color: TColor.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700),
                decoration: InputDecoration(
                  hintText: "0.00",
                  hintStyle:
                  TextStyle(color: TColor.gray50, fontSize: 24),
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
                    BorderSide(color: TColor.border.withOpacity(0.1)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                    BorderSide(color: TColor.border.withOpacity(0.1)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: TColor.primary),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text("Note (optional)",
                  style: TextStyle(color: TColor.gray30, fontSize: 12)),
              const SizedBox(height: 6),
              TextField(
                controller: _noteController,
                style: TextStyle(color: TColor.white),
                decoration: InputDecoration(
                  hintText: "e.g. Lunch, Petrol...",
                  hintStyle: TextStyle(color: TColor.gray50),
                  filled: true,
                  fillColor: TColor.gray70.withOpacity(0.3),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                    BorderSide(color: TColor.border.withOpacity(0.1)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                    BorderSide(color: TColor.border.withOpacity(0.1)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: TColor.primary),
                  ),
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
                    final amount =
                    double.tryParse(_expenseController.text.trim());
                    if (amount == null || amount <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: const Text("Enter a valid amount"),
                        backgroundColor: TColor.secondary,
                      ));
                      return;
                    }
                    provider.addExpense(
                        index, amount, _noteController.text.trim());
                    Navigator.pop(context);
                    final newSpent =
                    provider.budgets[index]["spend_amount"] as double;
                    final budget =
                    provider.budgets[index]["total_budget"] as double;
                    if (newSpent > budget) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(
                            "⚠️ ${provider.budgets[index]["name"]} is over budget!"),
                        backgroundColor: TColor.secondary,
                        duration: const Duration(seconds: 3),
                      ));
                    }
                  },
                  child: Text("Add Expense",
                      style: TextStyle(
                          color: TColor.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEditSheet(BuildContext context, int index) {
    final provider = Provider.of<ExpenseProvider>(context, listen: false);
    final item = provider.budgets[index];
    _nameController.text = item["name"];
    _budgetController.text = item["total_budget"].toString();

    showModalBottomSheet(
      context: context,
      backgroundColor: TColor.gray80,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
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
                child: Text("Edit Category",
                    style: TextStyle(
                        color: TColor.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: 20),
              Text("Category Name",
                  style: TextStyle(color: TColor.gray30, fontSize: 12)),
              const SizedBox(height: 6),
              TextField(
                controller: _nameController,
                style: TextStyle(color: TColor.white),
                decoration: InputDecoration(
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
              const SizedBox(height: 16),
              Text("Monthly Budget (₹)",
                  style: TextStyle(color: TColor.gray30, fontSize: 12)),
              const SizedBox(height: 6),
              TextField(
                controller: _budgetController,
                keyboardType: TextInputType.number,
                style: TextStyle(color: TColor.white),
                decoration: InputDecoration(
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
                    final newBudget =
                    double.tryParse(_budgetController.text);
                    if (_nameController.text.trim().isEmpty ||
                        newBudget == null) return;
                    provider.editCategory(
                        index, _nameController.text.trim(), newBudget);
                    Navigator.pop(context);
                  },
                  child: Text("Save Changes",
                      style: TextStyle(
                          color: TColor.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddCategorySheet(BuildContext context) {
    _nameController.clear();
    _budgetController.clear();
    _selectedColorIndex = 0;

    showModalBottomSheet(
      context: context,
      backgroundColor: TColor.gray80,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(builder: (context, setSheetState) {
          return Padding(
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
                  child: Text("Add New Category",
                      style: TextStyle(
                          color: TColor.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700)),
                ),
                const SizedBox(height: 20),
                Text("Category Name",
                    style:
                    TextStyle(color: TColor.gray30, fontSize: 12)),
                const SizedBox(height: 6),
                TextField(
                  controller: _nameController,
                  style: TextStyle(color: TColor.white),
                  decoration: InputDecoration(
                    hintText: "e.g. Groceries",
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
                const SizedBox(height: 16),
                Text("Monthly Budget (₹)",
                    style:
                    TextStyle(color: TColor.gray30, fontSize: 12)),
                const SizedBox(height: 6),
                TextField(
                  controller: _budgetController,
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: TColor.white),
                  decoration: InputDecoration(
                    hintText: "e.g. 5000",
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
                const SizedBox(height: 16),
                Text("Color",
                    style:
                    TextStyle(color: TColor.gray30, fontSize: 12)),
                const SizedBox(height: 8),
                Row(
                  children: List.generate(categoryColors.length, (i) {
                    return GestureDetector(
                      onTap: () =>
                          setSheetState(() => _selectedColorIndex = i),
                      child: Container(
                        margin: const EdgeInsets.only(right: 10),
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: categoryColors[i],
                          shape: BoxShape.circle,
                          border: _selectedColorIndex == i
                              ? Border.all(
                              color: TColor.white, width: 2)
                              : null,
                        ),
                        child: _selectedColorIndex == i
                            ? Icon(Icons.check,
                            color: TColor.white, size: 16)
                            : null,
                      ),
                    );
                  }),
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
                      if (_nameController.text.trim().isEmpty ||
                          _budgetController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content:
                              const Text("Please fill in all fields"),
                              backgroundColor: TColor.secondary,
                            ));
                        return;
                      }
                      final budget =
                      double.tryParse(_budgetController.text);
                      if (budget == null || budget <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content:
                              const Text("Enter a valid budget"),
                              backgroundColor: TColor.secondary,
                            ));
                        return;
                      }
                      Provider.of<ExpenseProvider>(context,
                          listen: false)
                          .addCategory({
                        "name": _nameController.text.trim(),
                        "icon": "assets/img/money.png",
                        "iconData": Icons.category,
                        "spend_amount": 0.0,
                        "total_budget": budget,
                        "color": categoryColors[_selectedColorIndex],
                        "isCustom": true,
                      });
                      Navigator.pop(context);
                    },
                    child: Text("Add Category",
                        style: TextStyle(
                            color: TColor.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          );
        });
      },
    );
  }

  // Confirm reset dialog
  void _confirmReset(BuildContext context, int index) {
    final provider = Provider.of<ExpenseProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: TColor.gray80,
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Reset Budget",
            style: TextStyle(
                color: TColor.white, fontWeight: FontWeight.w700)),
        content: Text(
          "Reset spent amount for \"${provider.budgets[index]["name"]}\" to ₹0?\nThis cannot be undone.",
          style: TextStyle(color: TColor.gray30, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
            Text("Cancel", style: TextStyle(color: TColor.gray30)),
          ),
          TextButton(
            onPressed: () {
              provider.resetCategory(index);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(
                    "✅ ${provider.budgets[index]["name"]} reset to ₹0"),
                backgroundColor: Colors.green.shade700,
              ));
            },
            child: Text("Reset",
                style: TextStyle(
                    color: TColor.secondary,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ExpenseProvider>(context);
    var media = MediaQuery.sizeOf(context);

    // ── New salary-based spendable logic ──────────
    final double spendableAfterGoal = (provider.getNetUsableBalance() -
        provider.savingsGoal)
        .clamp(0.0, double.infinity);
    final arcVals = _getArcValues(provider, spendableAfterGoal);

    return Scaffold(
      backgroundColor: TColor.gray,
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 35, right: 10),
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
                      icon: Image.asset("assets/img/settings.png",
                          width: 25,
                          height: 25,
                          color: TColor.gray30))
                ],
              ),
            ),

            // Arc chart
            Stack(
              alignment: Alignment.bottomCenter,
              children: [
                SizedBox(
                  width: media.width * 0.5,
                  height: media.width * 0.30,
                  child: CustomPaint(
                    painter: CustomArc180Painter(
                      drwArcs: arcVals,
                      end: 50,
                      width: 12,
                      bgWidth: 8,
                    ),
                  ),
                ),
                Column(
                  children: [
                    Text(
                      "₹${provider.totalSpent.toStringAsFixed(2)}",
                      style: TextStyle(
                          color: TColor.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w700),
                    ),
                    Text(
                      "of ₹${spendableAfterGoal.toStringAsFixed(0)} usable money",
                      style: TextStyle(
                          color: TColor.gray30,
                          fontSize: 12,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                )
              ],
            ),
            const SizedBox(height: 16),

            // ── Budget Limit Summary Bar ──
            Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: TColor.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: TColor.primary.withOpacity(0.25)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _summaryItem("Usable",
                        "₹${spendableAfterGoal.toStringAsFixed(0)}",
                        TColor.primary10),
                    _divider(),
                    _summaryItem("Spent",
                        "₹${provider.totalSpent.toStringAsFixed(0)}",
                        TColor.secondary),
                    _divider(),
                    _summaryItem(
                        "Remaining",
                        "₹${(spendableAfterGoal - provider.totalSpent).toStringAsFixed(0)}",
                        (spendableAfterGoal - provider.totalSpent) < 0
                            ? TColor.secondary
                            : TColor.secondaryG),
                    _divider(),
                    _summaryItem(
                        "Used",
                        spendableAfterGoal > 0
                            ? "${((provider.totalSpent / spendableAfterGoal) * 100).clamp(0, 999).toStringAsFixed(0)}%"
                            : "0%",
                        TColor.primary20),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ── Top Spending Categories ──────────
            Builder(
              builder: (context) {
                final topCats = _getTopCategories(provider);
                if (topCats.isEmpty) return const SizedBox.shrink();
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Top Spending",
                              style: TextStyle(
                                  color: TColor.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700)),
                          Text("This month",
                              style: TextStyle(
                                  color: TColor.gray40, fontSize: 11)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: topCats.map((b) {
                          final spent = b["spend_amount"] as double;
                          final budget = b["total_budget"] as double;
                          final ratio = budget > 0
                              ? (spent / budget).clamp(0.0, 1.0)
                              : 0.0;
                          final color = b["color"] as Color;
                          return Expanded(
                            child: Container(
                              margin: EdgeInsets.only(
                                  right: b == topCats.last ? 0 : 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                    color: color.withOpacity(0.2)),
                              ),
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.category_outlined,
                                      color: color, size: 18),
                                  const SizedBox(height: 8),
                                  Text(
                                    b["name"].toString().length > 9
                                        ? "${b["name"].toString().substring(0, 9)}.."
                                        : b["name"].toString(),
                                    style: TextStyle(
                                        color: TColor.gray30,
                                        fontSize: 10),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "₹${spent.toStringAsFixed(0)}",
                                    style: TextStyle(
                                        color: TColor.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: 6),
                                  LinearProgressIndicator(
                                    value: ratio,
                                    backgroundColor: TColor.gray60,
                                    valueColor:
                                    AlwaysStoppedAnimation(color),
                                    minHeight: 2,
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                );
              },
            ),

            // Status banner
            Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Container(
                height: 56,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  border: Border.all(
                      color: TColor.border.withOpacity(0.1)),
                  borderRadius: BorderRadius.circular(16),
                  color: provider.totalSpent > spendableAfterGoal
                      ? TColor.secondary.withOpacity(0.1)
                      : Colors.transparent,
                ),
                alignment: Alignment.center,
                child: Text(
                  _getStatusMessage(provider, spendableAfterGoal),
                  style: TextStyle(
                      color: _getStatusColor(provider, spendableAfterGoal),
                      fontSize: 14,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Budget list
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
                  final left = budget - spent;
                  final isOverBudget = spent > budget;
                  final percent = budget > 0
                      ? ((spent / budget) * 100).toStringAsFixed(0)
                      : "0";

                  final displayItem = Map<String, dynamic>.from(item);
                  displayItem["left_amount"] =
                      left.toStringAsFixed(2);
                  displayItem["spend_amount"] =
                      spent.toStringAsFixed(2);
                  displayItem["total_budget"] =
                      budget.toStringAsFixed(2);

                  return Stack(
                    children: [
                      // Red overlay for over budget
                      if (isOverBudget)
                        Positioned.fill(
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: TColor.secondary.withOpacity(0.5),
                                  width: 1.5),
                            ),
                          ),
                        ),
                      Column(
                        children: [
                          BudgetsRow(
                            bObj: displayItem,
                            onPressed: () {},
                            onAddExpense: () =>
                                _showAddExpenseSheet(context, index),
                            onEdit: () =>
                                _showEditSheet(context, index),
                            onDelete: () =>
                                provider.deleteCategory(index),
                            onReset: () =>
                                _confirmReset(context, index),
                          ),
                          // % used tag
                          Padding(
                            padding: const EdgeInsets.only(
                                left: 20, bottom: 4, top: 0),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isOverBudget
                                        ? TColor.secondary
                                        .withOpacity(0.15)
                                        : (item["color"] as Color)
                                        .withOpacity(0.15),
                                    borderRadius:
                                    BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    isOverBudget
                                        ? "Over budget by ₹${(spent - budget).toStringAsFixed(0)}"
                                        : "$percent% used",
                                    style: TextStyle(
                                      color: isOverBudget
                                          ? TColor.secondary
                                          : item["color"] as Color,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                }),

            // Add new category
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 0),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => _showAddCategorySheet(context),
                child: DottedBorder(
                  dashPattern: const [5, 4],
                  strokeWidth: 1,
                  borderType: BorderType.RRect,
                  radius: const Radius.circular(16),
                  color: TColor.border.withOpacity(0.1),
                  child: Container(
                    height: 64,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Add new category ",
                          style: TextStyle(
                              color: TColor.gray30,
                              fontSize: 14,
                              fontWeight: FontWeight.w600),
                        ),
                        Image.asset("assets/img/add.png",
                            width: 12,
                            height: 12,
                            color: TColor.gray30)
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 110),
          ],
        ),
      ),
    );
  }

  // ── Top Spending Categories ───────────────────
  List<Map<String, dynamic>> _getTopCategories(
      ExpenseProvider provider) {
    final sorted = List<Map<String, dynamic>>.from(provider.budgets)
      ..sort((a, b) => (b["spend_amount"] as double)
          .compareTo(a["spend_amount"] as double));
    return sorted
        .where((b) => (b["spend_amount"] as double) > 0)
        .take(3)
        .toList();
  }

  // Summary item widget
  Widget _summaryItem(String title, String value, Color color) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(title,
            style: TextStyle(color: TColor.gray30, fontSize: 10)),
      ],
    );
  }

  Widget _divider() {
    return Container(
        width: 1, height: 28, color: TColor.border.withOpacity(0.1));
  }
}