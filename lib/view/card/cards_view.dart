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

  // ── Add Fixed Expense Sheet (Enhanced) ────────
  void _showAddFixedExpenseSheet(ExpenseProvider provider, {String presetType = 'other'}) {
    _fixedNameController.clear();
    _fixedAmountController.clear();
    _fixedDayController.text = '1';
    String selectedType = presetType;

    showModalBottomSheet(
      context: context,
      backgroundColor: TColor.gray80,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => SingleChildScrollView(
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

              // ── Type selector ──────────────────
              Text("Type", style: TextStyle(color: TColor.gray30, fontSize: 12)),
              const SizedBox(height: 8),
              Row(
                children: [
                  for (final t in [
                    {'key': 'subscription', 'label': 'Subscription', 'icon': Icons.subscriptions_outlined},
                    {'key': 'bill',         'label': 'Bill',         'icon': Icons.bolt_outlined},
                    {'key': 'rent',         'label': 'Rent/EMI',     'icon': Icons.home_outlined},
                    {'key': 'other',        'label': 'Other',        'icon': Icons.more_horiz},
                  ])
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setSheetState(() => selectedType = t['key'] as String),
                        child: Container(
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: selectedType == t['key']
                                ? TColor.primary.withOpacity(0.2)
                                : TColor.gray70.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: selectedType == t['key']
                                  ? TColor.primary.withOpacity(0.5)
                                  : TColor.border.withOpacity(0.05),
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(t['icon'] as IconData,
                                  color: selectedType == t['key']
                                      ? TColor.primary
                                      : TColor.gray40,
                                  size: 16),
                              const SizedBox(height: 3),
                              Text(t['label'] as String,
                                  style: TextStyle(
                                      color: selectedType == t['key']
                                          ? TColor.primary
                                          : TColor.gray40,
                                      fontSize: 8,
                                      fontWeight: FontWeight.w600),
                                  textAlign: TextAlign.center),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Subscription quick-pick ────────
              if (selectedType == 'subscription') ...[
                Text("Quick Pick",
                    style: TextStyle(color: TColor.gray30, fontSize: 12)),
                const SizedBox(height: 8),
                SizedBox(
                  height: 70,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: kPredefinedSubscriptions.length,
                    itemBuilder: (context, idx) {
                      final sub = kPredefinedSubscriptions[idx];
                      return GestureDetector(
                        onTap: () {
                          setSheetState(() {
                            _fixedNameController.text = sub['name'] as String;
                            _fixedAmountController.text =
                                (sub['price'] as double).toStringAsFixed(0);
                          });
                        },
                        child: Container(
                          width: 72,
                          margin: const EdgeInsets.only(right: 10),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: TColor.primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: TColor.primary.withOpacity(0.15)),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(sub['icon'] as String,
                                  width: 24, height: 24,
                                  errorBuilder: (_, __, ___) => Icon(
                                      Icons.subscriptions,
                                      color: TColor.primary, size: 20)),
                              const SizedBox(height: 4),
                              Text(sub['name'] as String,
                                  style: TextStyle(
                                      color: TColor.white,
                                      fontSize: 8,
                                      fontWeight: FontWeight.w600),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // ── Bill quick-pick ────────────────
              if (selectedType == 'bill') ...[
                Text("Quick Pick",
                    style: TextStyle(color: TColor.gray30, fontSize: 12)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final b in [
                      {'name': 'Electricity', 'icon': Icons.bolt},
                      {'name': 'Water',        'icon': Icons.water_drop_outlined},
                      {'name': 'Gas',          'icon': Icons.local_fire_department_outlined},
                      {'name': 'Maintenance',  'icon': Icons.build_outlined},
                      {'name': 'Internet',     'icon': Icons.wifi},
                      {'name': 'Phone',        'icon': Icons.phone_android},
                    ])
                      GestureDetector(
                        onTap: () => setSheetState(() =>
                        _fixedNameController.text = b['name'] as String),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: TColor.secondary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: TColor.secondary.withOpacity(0.2)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(b['icon'] as IconData,
                                  color: TColor.secondary, size: 12),
                              const SizedBox(width: 4),
                              Text(b['name'] as String,
                                  style: TextStyle(
                                      color: TColor.white, fontSize: 11)),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
              ],

              // ── Name field ─────────────────────
              Text("Name", style: TextStyle(color: TColor.gray30, fontSize: 12)),
              const SizedBox(height: 8),
              TextField(
                controller: _fixedNameController,
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
                                borderSide:
                                BorderSide(color: TColor.primary)),
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
                                borderSide:
                                BorderSide(color: TColor.primary)),
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
                      provider.addFixedExpense(name, amount, day,
                          type: selectedType);
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
      ),
    );
  }

  // ── Deduction Row Helper ───────────────────────
  Widget _buildDeductionRow({
    required IconData icon,
    required String label,
    required String sublabel,
    required double amount,
    required Color color,
    required VoidCallback? onRemove,
  }) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 13),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(color: TColor.white, fontSize: 12)),
              Text(sublabel,
                  style: TextStyle(color: TColor.gray50, fontSize: 9)),
            ],
          ),
        ),
        Text("−₹${amount.toStringAsFixed(0)}",
            style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600)),
        if (onRemove != null) ...[
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onRemove,
            child: Icon(Icons.close, color: TColor.gray50, size: 14),
          ),
        ] else
          const SizedBox(width: 22),
      ],
    );
  }

  // ── Money Flow Timeline ────────────────────────
  Widget _buildMoneyFlowTimeline(ExpenseProvider provider) {
    final tax = provider.calculateTax(provider.monthlyIncome);
    final steps = <Map<String, dynamic>>[
      {
        'label': 'Salary',
        'value': provider.monthlyIncome,
        'color': TColor.primary,
        'icon': Icons.account_balance_wallet,
        'subtract': false,
      },
      if (tax > 0)
        {
          'label': 'Est. Tax',
          'value': tax,
          'color': TColor.secondary50,
          'icon': Icons.account_balance_outlined,
          'subtract': true,
        },
      ...provider.fixedExpenses.map((f) => <String, dynamic>{
        'label': f.name,
        'value': f.amount,
        'color': f.type == 'subscription'
            ? TColor.primary10
            : f.type == 'bill'
            ? TColor.secondary
            : TColor.secondary50,
        'icon': f.type == 'subscription'
            ? Icons.subscriptions_outlined
            : f.type == 'bill'
            ? Icons.bolt_outlined
            : Icons.home_outlined,
        'subtract': true,
      }),
      {
        'label': 'Net Usable Balance',
        'value': provider.getNetUsableBalance(),
        'color': TColor.primary10,
        'icon': Icons.account_balance_outlined,
        'subtract': false,
      },
      if (provider.savingsGoal > 0)
        {
          'label': 'Savings Goal',
          'value': provider.savingsGoal,
          'color': TColor.secondary50,
          'icon': Icons.savings_outlined,
          'subtract': true,
        },
      {
        'label': 'Spendable After Savings',
        'value': (provider.getNetUsableBalance() - provider.savingsGoal)
            .clamp(0.0, double.infinity),
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

  void _showSetGoalSheet(ExpenseProvider provider) {
    _goalController.text = provider.savingsGoal > 0
        ? provider.savingsGoal.toStringAsFixed(0)
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
                    provider.setSavingsGoal(goal);
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
    final double spendableAfterGoal = (provider.getNetUsableBalance() -
        provider.savingsGoal)
        .clamp(0.0, double.infinity);
    final savedAmount = provider.totalSaved;
    final double savingsGoal = provider.savingsGoal;
    final goalProgress =
    savingsGoal > 0 ? (savedAmount / savingsGoal).clamp(0.0, 1.0) : 0.0;

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
                        Text("Money Flow",
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
                          onTap: () => _showSetGoalSheet(provider),
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
                              "₹${savingsGoal.toStringAsFixed(0)}",
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
                            provider.monthlyIncome > 0
                                ? "₹${(spendableAfterGoal / max(1, DateTime(DateTime.now().year, DateTime.now().month + 1, 0).day - DateTime.now().day + 1)).toStringAsFixed(0)} / day"
                                : "Set income first",
                            style: TextStyle(
                                color: spendableAfterGoal > 0
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
                            Text("Auto Deductions",
                                style: TextStyle(
                                    color: TColor.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600)),
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: () => _showAddFixedExpenseSheet(
                                      provider, presetType: 'subscription'),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    margin: const EdgeInsets.only(right: 6),
                                    decoration: BoxDecoration(
                                      color: TColor.primary.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                          color: TColor.primary.withOpacity(0.2)),
                                    ),
                                    child: Text("+ Sub",
                                        style: TextStyle(
                                            color: TColor.primary,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600)),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => _showAddFixedExpenseSheet(
                                      provider, presetType: 'bill'),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    margin: const EdgeInsets.only(right: 6),
                                    decoration: BoxDecoration(
                                      color: TColor.secondary.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                          color: TColor.secondary.withOpacity(0.2)),
                                    ),
                                    child: Text("+ Bill",
                                        style: TextStyle(
                                            color: TColor.secondary,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600)),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => _showAddFixedExpenseSheet(provider),
                                  child: Icon(Icons.add_circle_outline,
                                      color: TColor.gray40, size: 18),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Tax row
                        if (provider.monthlyIncome > 0) ...[
                          _buildDeductionRow(
                            icon: Icons.account_balance_outlined,
                            label: "Est. Tax (India)",
                            sublabel: "Auto-calculated",
                            amount: provider.calculateTax(provider.monthlyIncome),
                            color: TColor.secondary50,
                            onRemove: null,
                          ),
                          const SizedBox(height: 6),
                        ],

                        if (provider.fixedExpenses.isEmpty &&
                            provider.monthlyIncome <= 0)
                          Text(
                            "Set income above, then add subscriptions, bills, or rent.",
                            style: TextStyle(
                                color: TColor.gray50,
                                fontSize: 11,
                                height: 1.5),
                          ),

                        // Subscriptions
                        if (provider.subscriptions.isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Text("Subscriptions",
                                style: TextStyle(
                                    color: TColor.primary10,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600)),
                          ),
                          ...provider.subscriptions.asMap().entries.map((e) {
                            final globalIdx = provider.fixedExpenses.indexOf(e.value);
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: _buildDeductionRow(
                                icon: Icons.subscriptions_outlined,
                                label: e.value.name,
                                sublabel: "Day ${e.value.dayOfMonth}",
                                amount: e.value.amount,
                                color: TColor.primary10,
                                onRemove: () => provider.removeFixedExpense(globalIdx),
                              ),
                            );
                          }),
                          const SizedBox(height: 4),
                        ],

                        // Bills
                        if (provider.bills.isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Text("Bills",
                                style: TextStyle(
                                    color: TColor.secondary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600)),
                          ),
                          ...provider.bills.asMap().entries.map((e) {
                            final globalIdx = provider.fixedExpenses.indexOf(e.value);
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: _buildDeductionRow(
                                icon: Icons.bolt_outlined,
                                label: e.value.name,
                                sublabel: "Day ${e.value.dayOfMonth}",
                                amount: e.value.amount,
                                color: TColor.secondary,
                                onRemove: () => provider.removeFixedExpense(globalIdx),
                              ),
                            );
                          }),
                          const SizedBox(height: 4),
                        ],

                        // Rent / Other
                        if (provider.rentExpenses.isNotEmpty ||
                            provider.fixedExpenses
                                .where((f) => f.type == 'other')
                                .isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Text("Rent & Other",
                                style: TextStyle(
                                    color: TColor.gray30,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600)),
                          ),
                          ...provider.fixedExpenses
                              .where((f) =>
                          f.type == 'rent' || f.type == 'other')
                              .toList()
                              .asMap()
                              .entries
                              .map((e) {
                            final globalIdx =
                            provider.fixedExpenses.indexOf(e.value);
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: _buildDeductionRow(
                                icon: e.value.type == 'rent'
                                    ? Icons.home_outlined
                                    : Icons.more_horiz,
                                label: e.value.name,
                                sublabel: "Day ${e.value.dayOfMonth}",
                                amount: e.value.amount,
                                color: TColor.gray30,
                                onRemove: () =>
                                    provider.removeFixedExpense(globalIdx),
                              ),
                            );
                          }),
                        ],

                        if (provider.fixedExpenses.isNotEmpty ||
                            provider.monthlyIncome > 0) ...[
                          const Divider(height: 16, thickness: 0.3),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("Total Deductions",
                                  style: TextStyle(
                                      color: TColor.gray40, fontSize: 11)),
                              Text(
                                "₹${provider.getTotalDeductions().toStringAsFixed(0)}",
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

                  // Spendable After Savings + Daily safe spend
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
                                  Text("Spendable After Savings",
                                      style: TextStyle(
                                          color: TColor.gray40, fontSize: 11)),
                                  const SizedBox(height: 2),
                                  Text(
                                    "₹${spendableAfterGoal.toStringAsFixed(0)}",
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
                                    "₹${(spendableAfterGoal / max(1, DateTime(DateTime.now().year, DateTime.now().month + 1, 0).day - DateTime.now().day + 1)).toStringAsFixed(0)}/day",
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