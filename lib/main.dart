import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trackizer/common/color_extension.dart';
import 'package:trackizer/common/expense_provider.dart';
import 'package:trackizer/common/theme_provider.dart';
import 'package:trackizer/common/user_provider.dart';
import 'package:trackizer/common/currency_provider.dart';

// ── New splash screen (add to your view folder and update the import path) ──
import 'package:trackizer/view/splash/splash_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => ExpenseProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => CurrencyProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    TColor.isDark = themeProvider.isDark;

    return MaterialApp(
      title: 'Expense Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: "Inter",
        brightness:
        themeProvider.isDark ? Brightness.dark : Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: TColor.primary,
          brightness:
          themeProvider.isDark ? Brightness.dark : Brightness.light,
          background: TColor.background,
          primary: TColor.primary,
          primaryContainer: TColor.cardBg,
          secondary: TColor.secondary,
        ),
        useMaterial3: false,
      ),
      // ── SplashView is now the entry point ────────────────────────────────
      // It handles all initialisation and smart navigation internally.
      home: const SplashView(),
    );
  }
}