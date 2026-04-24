import 'package:flutter/material.dart';
import '../common/color_extension.dart';

class BudgetsRow extends StatelessWidget {
  final Map bObj;
  final VoidCallback onPressed;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onAddExpense;
  final VoidCallback? onReset;

  const BudgetsRow({
    super.key,
    required this.bObj,
    required this.onPressed,
    this.onEdit,
    this.onDelete,
    this.onAddExpense,
    this.onReset,
  });

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: TColor.gray80,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: TColor.gray30,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                bObj["name"],
                style: TextStyle(
                    color: TColor.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),

              // Add Expense
              _OptionTile(
                icon: Icons.add_circle_outline,
                label: "Add Expense",
                color: TColor.secondaryG,
                onTap: () {
                  Navigator.pop(context);
                  if (onAddExpense != null) onAddExpense!();
                },
              ),

              // Edit
              _OptionTile(
                icon: Icons.edit_outlined,
                label: "Edit Category",
                color: TColor.primary20,
                onTap: () {
                  Navigator.pop(context);
                  if (onEdit != null) onEdit!();
                },
              ),

              // Reset
              _OptionTile(
                icon: Icons.refresh,
                label: "Reset Month",
                color: TColor.primary20,
                onTap: () {
                  Navigator.pop(context);
                  if (onReset != null) onReset!();
                },
              ),

              // Delete — only for custom categories
              if (bObj["isCustom"] == true)
                _OptionTile(
                  icon: Icons.delete_outline,
                  label: "Delete Category",
                  color: TColor.secondary,
                  onTap: () {
                    Navigator.pop(context);
                    if (onDelete != null) onDelete!();
                  },
                ),

              const SizedBox(height: 8),

              // Cancel
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    "Cancel",
                    style: TextStyle(color: TColor.gray30, fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    var proVal = (double.tryParse(bObj["spend_amount"].toString()) ?? 0) /
        (double.tryParse(bObj["total_budget"].toString()) ?? 1);

    // Support both asset icons and Material icons
    Widget iconWidget;
    if (bObj["iconData"] != null) {
      iconWidget = Icon(
        bObj["iconData"] as IconData,
        color: TColor.gray40,
        size: 30,
      );
    } else {
      iconWidget = Image.asset(
        bObj["icon"] ?? "assets/img/money.png",
        width: 30,
        height: 30,
        color: TColor.gray40,
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showOptions(context),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            border: Border.all(color: TColor.border.withOpacity(0.05)),
            color: TColor.gray60.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          alignment: Alignment.center,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: iconWidget,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          bObj["name"],
                          style: TextStyle(
                              color: TColor.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600),
                        ),
                        Text(
                          "₹${bObj["left_amount"]} left to spend",
                          style: TextStyle(
                              color: TColor.gray30,
                              fontSize: 12,
                              fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "₹${bObj["spend_amount"]}",
                        style: TextStyle(
                            color: TColor.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600),
                      ),
                      Text(
                        "of ₹${bObj["total_budget"]}",
                        style: TextStyle(
                            color: TColor.gray30,
                            fontSize: 12,
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                backgroundColor: TColor.gray60,
                valueColor: AlwaysStoppedAnimation(bObj["color"]),
                minHeight: 3,
                value: proVal.clamp(0.0, 1.0),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _OptionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                  color: color, fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}