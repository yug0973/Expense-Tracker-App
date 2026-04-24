import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../common/color_extension.dart';
import '../../common/theme_provider.dart';
import '../../common/user_provider.dart';
import '../../common/currency_provider.dart';
import '../../common_widget/icon_item_row.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  String sorting = "Date";
  String summary = "Average";

  // ──────────────────────────────────────────────
  // Generic bottom-sheet option picker (unchanged)
  // ──────────────────────────────────────────────
  void _showOptions(
      String title,
      List<String> options,
      String current,
      Function(String) onSelect,
      ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: TColor.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
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
                title,
                style: TextStyle(
                    color: TColor.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              ...options.map((option) {
                final isSelected = option == current;
                return InkWell(
                  onTap: () {
                    onSelect(option);
                    Navigator.pop(context);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                        vertical: 14, horizontal: 16),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? TColor.primary.withOpacity(0.2)
                          : TColor.gray.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? TColor.primary
                            : TColor.border.withOpacity(0.1),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          option,
                          style: TextStyle(
                            color: isSelected ? TColor.primary : TColor.white,
                            fontSize: 14,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                        if (isSelected)
                          Icon(Icons.check_circle,
                              color: TColor.primary, size: 20),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  // ──────────────────────────────────────────────
  // Edit profile bottom sheet
  // ──────────────────────────────────────────────
  void _showEditProfileSheet(UserProvider userProvider) {
    final nameCtrl = TextEditingController(text: userProvider.name);
    final emailCtrl = TextEditingController(text: userProvider.email);
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: TColor.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          // Push sheet above keyboard
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: TColor.gray30,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  "Edit Profile",
                  style: TextStyle(
                      color: TColor.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 20),

                // Name field
                Text("Name",
                    style:
                    TextStyle(color: TColor.gray30, fontSize: 12)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: nameCtrl,
                  style: TextStyle(color: TColor.white, fontSize: 14),
                  validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Name cannot be empty' : null,
                  decoration: InputDecoration(
                    hintText: "Your name",
                    hintStyle:
                    TextStyle(color: TColor.gray30, fontSize: 14),
                    filled: true,
                    fillColor: TColor.gray.withOpacity(0.4),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                      BorderSide(color: TColor.primary, width: 1.5),
                    ),
                    prefixIcon:
                    Icon(Icons.person_outline, color: TColor.gray30, size: 20),
                  ),
                ),
                const SizedBox(height: 16),

                // Email field
                Text("Email",
                    style:
                    TextStyle(color: TColor.gray30, fontSize: 12)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  style: TextStyle(color: TColor.white, fontSize: 14),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Email cannot be empty';
                    if (!v.contains('@')) return 'Enter a valid email';
                    return null;
                  },
                  decoration: InputDecoration(
                    hintText: "Your email",
                    hintStyle:
                    TextStyle(color: TColor.gray30, fontSize: 14),
                    filled: true,
                    fillColor: TColor.gray.withOpacity(0.4),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                      BorderSide(color: TColor.primary, width: 1.5),
                    ),
                    prefixIcon:
                    Icon(Icons.email_outlined, color: TColor.gray30, size: 20),
                  ),
                ),
                const SizedBox(height: 24),

                // Save button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (formKey.currentState!.validate()) {
                        await userProvider.updateProfile(
                          name: nameCtrl.text.trim(),
                          email: emailCtrl.text.trim(),
                        );
                        if (ctx.mounted) Navigator.pop(ctx);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TColor.primary,
                      foregroundColor: TColor.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      "Save Changes",
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ──────────────────────────────────────────────
  // Logout confirmation dialog
  // ──────────────────────────────────────────────
  void _confirmLogout(UserProvider userProvider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: TColor.cardBg,
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Logout",
            style: TextStyle(
                color: TColor.white, fontWeight: FontWeight.w700)),
        content: Text(
          "Are you sure you want to log out?",
          style: TextStyle(color: TColor.gray30, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Cancel",
                style: TextStyle(color: TColor.gray30)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx); // close dialog
              await userProvider.clear();
              if (mounted) {
                // Navigate to welcome screen and clear the entire back-stack
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/welcome', // ← adjust if your route name differs
                      (route) => false,
                );
              }
            },
            child: Text("Logout",
                style: TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────
  // Build
  // ──────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);
    final currencyProvider = Provider.of<CurrencyProvider>(context);

    // Sync local theme string with provider
    final theme = themeProvider.currentLabel;
    final currency = currencyProvider.currency;

    return Scaffold(
      backgroundColor: TColor.background,
      body: SingleChildScrollView(
        child: SafeArea(
          child: Column(
            children: [
              // ── Top bar ──────────────────────────────
              Stack(
                alignment: Alignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Image.asset(
                          "assets/img/back.png",
                          width: 25,
                          height: 25,
                          color: TColor.gray30,
                        ),
                      )
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Settings",
                        style:
                        TextStyle(color: TColor.gray30, fontSize: 16),
                      )
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ── Profile avatar ────────────────────────
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    width: 74,
                    height: 74,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: TColor.primary.withOpacity(0.6), width: 2),
                    ),
                    child:
                    ClipOval(child: Image.asset("assets/img/u1.png")),
                  ),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: TColor.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.edit,
                        color: Colors.white, size: 12),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // ── Name (from UserProvider) ──────────────
              Text(
                userProvider.name.isNotEmpty
                    ? userProvider.name
                    : "Your Name",
                style: TextStyle(
                    color: TColor.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700),
              ),

              const SizedBox(height: 4),

              // ── Email (from UserProvider) ─────────────
              Text(
                userProvider.email.isNotEmpty
                    ? userProvider.email
                    : "your@email.com",
                style: TextStyle(
                    color: TColor.gray30,
                    fontSize: 12,
                    fontWeight: FontWeight.w500),
              ),

              const SizedBox(height: 15),

              // ── Edit profile button ───────────────────
              InkWell(
                borderRadius: BorderRadius.circular(15),
                onTap: () => _showEditProfileSheet(userProvider),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: TColor.border.withOpacity(0.15)),
                    color: TColor.cardBg.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.edit_outlined,
                          color: TColor.white, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        "Edit profile",
                        style: TextStyle(
                            color: TColor.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Settings sections ─────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(
                    vertical: 20, horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── My Subscription ─────────────────
                    Padding(
                      padding: const EdgeInsets.only(top: 15, bottom: 8),
                      child: Text(
                        "My subscription",
                        style: TextStyle(
                            color: TColor.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: TColor.border.withOpacity(0.1)),
                        color: TColor.cardBg.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: () => _showOptions(
                              "Sorting",
                              ["Date", "Name", "Amount"],
                              sorting,
                                  (val) => setState(() => sorting = val),
                            ),
                            child: IconItemRow(
                              title: "Sorting",
                              icon: "assets/img/sorting.png",
                              value: sorting,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _showOptions(
                              "Summary",
                              ["Average", "Monthly", "Weekly"],
                              summary,
                                  (val) => setState(() => summary = val),
                            ),
                            child: IconItemRow(
                              title: "Summary",
                              icon: "assets/img/chart.png",
                              value: summary,
                            ),
                          ),
                          // Currency – now wired to CurrencyProvider
                          GestureDetector(
                            onTap: () => _showOptions(
                              "Default Currency",
                              ["INR (₹)", r"USD ($)", "EUR (€)", "GBP (£)"],
                              currency,
                                  (val) => currencyProvider.setCurrency(val),
                            ),
                            child: IconItemRow(
                              title: "Default currency",
                              icon: "assets/img/money.png",
                              value: currency,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── Appearance ──────────────────────
                    Padding(
                      padding: const EdgeInsets.only(top: 20, bottom: 8),
                      child: Text(
                        "Appearance",
                        style: TextStyle(
                            color: TColor.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: TColor.border.withOpacity(0.1)),
                        color: TColor.cardBg.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: GestureDetector(
                        onTap: () => _showOptions(
                          "Theme",
                          ["Dark", "Light"],
                          theme,
                              (val) => themeProvider.toggleTheme(val),
                        ),
                        child: IconItemRow(
                          title: "Theme",
                          icon: "assets/img/light_theme.png",
                          value: theme,
                        ),
                      ),
                    ),

                    // ── Account ─────────────────────────
                    Padding(
                      padding: const EdgeInsets.only(top: 20, bottom: 8),
                      child: Text(
                        "Account",
                        style: TextStyle(
                            color: TColor.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: TColor.border.withOpacity(0.1)),
                        color: TColor.cardBg.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: InkWell(
                        onTap: () => _confirmLogout(userProvider),
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color:
                                  Colors.redAccent.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.logout_rounded,
                                  color: Colors.redAccent,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Text(
                                "Logout",
                                style: TextStyle(
                                  color: Colors.redAccent,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const Spacer(),
                              Icon(Icons.chevron_right,
                                  color: TColor.gray30, size: 20),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}