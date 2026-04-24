📘Expense Tracker – Smart Expense & Financial Flow Management App
📱 Overview

Expense Tracker is a modern Flutter-based personal finance application designed to help users manage their money efficiently.
Unlike traditional expense trackers, Trackizer focuses on financial planning by calculating how much users can safely spend after deductions and savings.

🚀 Features
💰 Money Flow System (Core)
Input monthly income
Automatic deduction of:
taxes
subscriptions
bills / rent
Savings goal deduction
Shows:
Final spendable amount
Daily safe spending
📊 Expense Tracking
Add and manage expenses
Category-based tracking
Stores notes, date, and amount
🎯 Savings Goals
Create multiple savings goals
Track progress (saved vs target)
Visual completion tracking
🔄 Fixed Expenses & Subscriptions
Manage recurring expenses
Types:
Bills
Subscriptions
Rent
🧮 Tax Calculation
Implements simplified Indian tax slab logic
Automatically deducted from income
📆 Daily Safe Spending
Calculates:
Remaining Money / Remaining Days
Helps prevent overspending
🎨 Custom UI & Theme
Dark / Light mode support
Clean, modern UI
Based on Figma design
🧠 Core Concept
Income
→ Tax
→ Fixed Expenses
→ Savings Goal
→ Final Spendable Money
→ Daily Safe Spending

“Trackizer doesn’t just track expenses — it helps you make smarter financial decisions.”

⚙️ Tech Stack
Flutter (Dart) – UI Development
Provider – State Management
SQLite (sqflite) – Local Database
SharedPreferences – Local Storage
Figma – UI Design Reference
🗄️ Database Tables
budgets – Category budgets
expenses – Expense records
savings_goals – Savings tracking
income – Monthly income
fixed_expenses – Recurring expenses
settings – App preferences
🧩 Architecture
UI (Views & Widgets)
        ↓
Provider (Business Logic)
        ↓
DatabaseHelper (SQLite)

👤 Yug Brahmbhatt
Business logic implementation
Provider state management
Database integration (SQLite)
Financial calculations
App flow & integration
UI implementation (Figma-based)
Reusable widgets
Design consistency
UI integration & testing
🤝 Collaboration

Both contributors worked together on:

Integration
Debugging
Feature development
📦 Installation
git clone https://github.com/your-username/trackizer.git
cd trackizer
flutter pub get
flutter run
🔥 Unique Value

“Other apps tell you what you spent.
Trackizer tells you what you can safely spend.”

📌 Future Scope
Cloud sync (Firebase)
AI-based spending prediction
Notifications & alerts
Multi-device support
📄 License

This project is for academic and learning purposes.
