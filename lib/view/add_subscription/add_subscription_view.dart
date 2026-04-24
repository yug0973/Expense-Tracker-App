import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trackizer/common/color_extension.dart';
import 'package:trackizer/common/expense_provider.dart';

class AddSubScriptionView extends StatefulWidget {
  const AddSubScriptionView({super.key});

  @override
  State<AddSubScriptionView> createState() => _AddSubScriptionViewState();
}

class _AddSubScriptionViewState extends State<AddSubScriptionView> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  int? _selectedCategoryIndex;

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ExpenseProvider>(context);

    return Scaffold(
      backgroundColor: TColor.gray,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top bar
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Image.asset("assets/img/back.png",
                              width: 25,
                              height: 25,
                              color: TColor.gray30),
                        )
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Add Expense",
                          style:
                          TextStyle(color: TColor.gray30, fontSize: 16),
                        )
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Title
                Text(
                  "Quick\nAdd Expense",
                  style: TextStyle(
                      color: TColor.white,
                      fontSize: 36,
                      fontWeight: FontWeight.w700),
                ),

                const SizedBox(height: 32),

                // Amount field
                Text("Amount (₹)",
                    style: TextStyle(
                        color: TColor.gray30,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextField(
                  controller: _amountController,
                  keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
                  autofocus: true,
                  style: TextStyle(
                      color: TColor.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w700),
                  decoration: InputDecoration(
                    hintText: "0.00",
                    hintStyle:
                    TextStyle(color: TColor.gray50, fontSize: 32),
                    prefixText: "₹ ",
                    prefixStyle: TextStyle(
                        color: TColor.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w700),
                    filled: true,
                    fillColor: TColor.gray70.withOpacity(0.3),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide:
                      BorderSide(color: TColor.border.withOpacity(0.1)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide:
                      BorderSide(color: TColor.border.withOpacity(0.1)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: TColor.primary),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Note field
                Text("Note (optional)",
                    style: TextStyle(
                        color: TColor.gray30,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextField(
                  controller: _noteController,
                  style: TextStyle(color: TColor.white),
                  decoration: InputDecoration(
                    hintText: "e.g. Lunch, Petrol, Movie...",
                    hintStyle: TextStyle(color: TColor.gray50),
                    filled: true,
                    fillColor: TColor.gray70.withOpacity(0.3),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide:
                      BorderSide(color: TColor.border.withOpacity(0.1)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide:
                      BorderSide(color: TColor.border.withOpacity(0.1)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: TColor.primary),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Category picker
                Text("Select Category",
                    style: TextStyle(
                        color: TColor.gray30,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),

                provider.budgets.isEmpty
                    ? Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: TColor.gray70.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: TColor.border.withOpacity(0.1)),
                  ),
                  child: Center(
                    child: Text(
                      "No categories yet.\nGo to Budgets to add one.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: TColor.gray40, fontSize: 13),
                    ),
                  ),
                )
                    : GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 2.8,
                  ),
                  itemCount: provider.budgets.length,
                  itemBuilder: (context, index) {
                    final item = provider.budgets[index];
                    final isSelected =
                        _selectedCategoryIndex == index;
                    final color = item["color"] as Color;

                    return GestureDetector(
                      onTap: () => setState(
                              () => _selectedCategoryIndex = index),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? color.withOpacity(0.2)
                              : TColor.gray70.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? color
                                : TColor.border.withOpacity(0.1),
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.category_outlined,
                              color: isSelected
                                  ? color
                                  : TColor.gray40,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                item["name"],
                                style: TextStyle(
                                  color: isSelected
                                      ? color
                                      : TColor.gray30,
                                  fontSize: 12,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 12),

                // Budget info for selected category
                if (_selectedCategoryIndex != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: (provider.budgets[_selectedCategoryIndex!]
                      ["color"] as Color)
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: (provider.budgets[_selectedCategoryIndex!]
                        ["color"] as Color)
                            .withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Spent so far",
                          style: TextStyle(
                              color: TColor.gray30, fontSize: 12),
                        ),
                        Text(
                          "₹${(provider.budgets[_selectedCategoryIndex!]["spend_amount"] as double).toStringAsFixed(2)} / ₹${(provider.budgets[_selectedCategoryIndex!]["total_budget"] as double).toStringAsFixed(2)}",
                          style: TextStyle(
                              color: TColor.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 32),

                // Add button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TColor.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () {
                      // Validate amount
                      final amount = double.tryParse(
                          _amountController.text.trim());
                      if (amount == null || amount <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text("Enter a valid amount"),
                            backgroundColor: TColor.secondary,
                          ),
                        );
                        return;
                      }

                      // Validate category
                      if (_selectedCategoryIndex == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content:
                            const Text("Please select a category"),
                            backgroundColor: TColor.secondary,
                          ),
                        );
                        return;
                      }

                      // Add expense
                      provider.addExpense(
                        _selectedCategoryIndex!,
                        amount,
                        _noteController.text.trim(),
                      );

                      // Check overspend
                      final spent = provider
                          .budgets[_selectedCategoryIndex!]
                      ["spend_amount"] as double;
                      final budget = provider
                          .budgets[_selectedCategoryIndex!]
                      ["total_budget"] as double;

                      if (spent > budget) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                "⚠️ ${provider.budgets[_selectedCategoryIndex!]["name"]} is over budget!"),
                            backgroundColor: TColor.secondary,
                            duration: const Duration(seconds: 3),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                "✅ ₹${amount.toStringAsFixed(2)} added to ${provider.budgets[_selectedCategoryIndex!]["name"]}"),
                            backgroundColor: Colors.green.shade700,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }

                      Navigator.pop(context);
                    },
                    child: Text(
                      "Add Expense",
                      style: TextStyle(
                          color: TColor.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}