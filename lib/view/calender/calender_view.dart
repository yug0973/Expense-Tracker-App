import 'package:calendar_agenda/calendar_agenda.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trackizer/common/color_extension.dart';
import 'package:trackizer/common/expense_provider.dart';
import 'package:trackizer/view/settings/settings_view.dart';

class CalenderView extends StatefulWidget {
  const CalenderView({super.key});

  @override
  State<CalenderView> createState() => _CalenderViewState();
}

class _CalenderViewState extends State<CalenderView> {
  CalendarAgendaController _calController = CalendarAgendaController();
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
  }

  // Get expenses for a specific date
  List<ExpenseModel> _expensesForDate(
      ExpenseProvider provider, DateTime date) {
    return provider.expenses.where((e) =>
    e.date.year == date.year &&
        e.date.month == date.month &&
        e.date.day == date.day).toList();
  }

  // Get all dates that have expenses (for calendar dots)
  List<DateTime> _datesWithExpenses(ExpenseProvider provider) {
    return provider.expenses
        .map((e) =>
        DateTime(e.date.year, e.date.month, e.date.day))
        .toSet()
        .toList();
  }

  // Total for selected date
  double _totalForDate(
      ExpenseProvider provider, DateTime date) {
    return _expensesForDate(provider, date)
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  // Month name helper
  String _monthName(int month) {
    const months = [
      "January", "February", "March", "April",
      "May", "June", "July", "August",
      "September", "October", "November", "December"
    ];
    return months[month - 1];
  }

  // Total spent this month
  double _monthTotal(ExpenseProvider provider) {
    final now = DateTime.now();
    return provider.expenses
        .where((e) =>
    e.date.year == now.year &&
        e.date.month == now.month)
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ExpenseProvider>(context);
    final selectedExpenses =
    _expensesForDate(provider, _selectedDate);
    final selectedTotal =
    _totalForDate(provider, _selectedDate);
    final datesWithExpenses =
    _datesWithExpenses(provider);

    return Scaffold(
      backgroundColor: TColor.gray,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Top Header ───────────────────────
            Container(
              decoration: BoxDecoration(
                  color: TColor.gray70.withOpacity(0.5),
                  borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(25),
                      bottomRight: Radius.circular(25))),
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20),
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          // Title bar
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              Row(
                                mainAxisAlignment:
                                MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "Calendar",
                                    style: TextStyle(
                                        color: TColor.gray30,
                                        fontSize: 16),
                                  ),
                                ],
                              ),
                              Row(
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
                              )
                            ],
                          ),
                          const SizedBox(height: 20),

                          Text(
                            "Expense\nCalendar",
                            style: TextStyle(
                                color: TColor.white,
                                fontSize: 40,
                                fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 15),

                          // Month summary row
                          Row(
                            mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "${selectedExpenses.length} expense${selectedExpenses.length == 1 ? "" : "s"} on this day",
                                    style: TextStyle(
                                        color: TColor.gray30,
                                        fontSize: 13,
                                        fontWeight:
                                        FontWeight.w600),
                                  ),
                                  Text(
                                    "₹${_monthTotal(provider).toStringAsFixed(2)} this month",
                                    style: TextStyle(
                                        color: TColor.gray40,
                                        fontSize: 11),
                                  ),
                                ],
                              ),
                              InkWell(
                                borderRadius:
                                BorderRadius.circular(12),
                                onTap: () {
                                  _calController.openCalender();
                                },
                                child: Container(
                                  padding:
                                  const EdgeInsets.symmetric(
                                      vertical: 4,
                                      horizontal: 8),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: TColor.border
                                          .withOpacity(0.1),
                                    ),
                                    color: TColor.gray60
                                        .withOpacity(0.2),
                                    borderRadius:
                                    BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      Text(
                                        _monthName(
                                            _selectedDate.month),
                                        style: TextStyle(
                                            color: TColor.white,
                                            fontSize: 12,
                                            fontWeight:
                                            FontWeight.w600),
                                      ),
                                      Icon(Icons.expand_more,
                                          color: TColor.white,
                                          size: 16),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // ── Calendar Widget ──────────
                    CalendarAgenda(
                      controller: _calController,
                      backgroundColor: Colors.transparent,
                      fullCalendarBackgroundColor: TColor.gray80,
                      locale: 'en',
                      weekDay: WeekDay.short,
                      fullCalendarDay: WeekDay.short,
                      selectedDateColor: TColor.white,
                      initialDate: DateTime.now(),
                      calendarEventColor: TColor.primary,
                      firstDate: DateTime.now()
                          .subtract(const Duration(days: 365)),
                      lastDate: DateTime.now()
                          .add(const Duration(days: 30)),
                      events: datesWithExpenses,
                      onDateSelected: (date) {
                        setState(() {
                          _selectedDate = date;
                        });
                      },
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: TColor.border.withOpacity(0.15),
                        ),
                        color: TColor.gray60.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      selectDecoration: BoxDecoration(
                        border: Border.all(
                          color: TColor.primary.withOpacity(0.5),
                        ),
                        color: TColor.primary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      selectedEventLogo: Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: TColor.primary,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      eventLogo: Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: TColor.secondary,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Selected Date Summary ────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: TColor.gray60.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: TColor.border.withOpacity(0.08)),
                ),
                child: Row(
                  mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${_selectedDate.day} ${_monthName(_selectedDate.month)} ${_selectedDate.year}",
                          style: TextStyle(
                              color: TColor.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "${selectedExpenses.length} transaction${selectedExpenses.length == 1 ? "" : "s"}",
                          style: TextStyle(
                              color: TColor.gray30,
                              fontSize: 12),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.end,
                      children: [
                        Text(
                          "₹${selectedTotal.toStringAsFixed(2)}",
                          style: TextStyle(
                              color: selectedTotal > 0
                                  ? TColor.secondary
                                  : TColor.gray40,
                              fontSize: 20,
                              fontWeight: FontWeight.w700),
                        ),
                        Text(
                          "total spent",
                          style: TextStyle(
                              color: TColor.gray40,
                              fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ── Expenses List for Selected Date ──
            if (selectedExpenses.isEmpty)
              Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  children: [
                    Icon(Icons.event_available,
                        color: TColor.gray50, size: 44),
                    const SizedBox(height: 12),
                    Text(
                      "No expenses on this day",
                      style: TextStyle(
                          color: TColor.gray30, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Tap + to add an expense",
                      style: TextStyle(
                          color: TColor.gray50, fontSize: 12),
                    ),
                  ],
                ),
              )
            else
              ListView.builder(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 0),
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: selectedExpenses.length,
                itemBuilder: (context, index) {
                  final exp = selectedExpenses[index];
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
                        // Category color dot + icon
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: exp.color.withOpacity(0.15),
                            borderRadius:
                            BorderRadius.circular(13),
                          ),
                          child: Icon(Icons.receipt_outlined,
                              color: exp.color, size: 22),
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
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Container(
                                    padding:
                                    const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2),
                                    decoration: BoxDecoration(
                                      color: exp.color
                                          .withOpacity(0.15),
                                      borderRadius:
                                      BorderRadius.circular(
                                          6),
                                    ),
                                    child: Text(
                                      exp.category,
                                      style: TextStyle(
                                          color: exp.color,
                                          fontSize: 10,
                                          fontWeight:
                                          FontWeight.w600),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    "${exp.date.hour.toString().padLeft(2, '0')}:${exp.date.minute.toString().padLeft(2, '0')}",
                                    style: TextStyle(
                                        color: TColor.gray50,
                                        fontSize: 10),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Text(
                          "₹${exp.amount.toStringAsFixed(2)}",
                          style: TextStyle(
                              color: TColor.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  );
                },
              ),

            // ── Monthly Breakdown ────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "${_monthName(_selectedDate.month)} Summary",
                    style: TextStyle(
                        color: TColor.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700),
                  ),
                  Text(
                    "₹${_monthTotal(provider).toStringAsFixed(2)}",
                    style: TextStyle(
                        color: TColor.secondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),

            // Category breakdown for the month
            ...() {
              final now = DateTime.now();
              final monthExpenses = provider.expenses
                  .where((e) =>
              e.date.year == _selectedDate.year &&
                  e.date.month == _selectedDate.month)
                  .toList();

              // Group by category
              final Map<String, double> categoryTotals = {};
              final Map<String, Color> categoryColors = {};
              for (var e in monthExpenses) {
                categoryTotals[e.category] =
                    (categoryTotals[e.category] ?? 0) +
                        e.amount;
                categoryColors[e.category] = e.color;
              }

              if (categoryTotals.isEmpty) {
                return [
                  Padding(
                    padding: const EdgeInsets.only(
                        bottom: 20, top: 8),
                    child: Center(
                      child: Text(
                        "No expenses this month yet",
                        style: TextStyle(
                            color: TColor.gray50,
                            fontSize: 13),
                      ),
                    ),
                  )
                ];
              }

              final sorted = categoryTotals.entries.toList()
                ..sort((a, b) => b.value.compareTo(a.value));

              return sorted.map((entry) {
                final color =
                    categoryColors[entry.key] ?? TColor.primary;
                final monthTotal = _monthTotal(provider);
                final ratio = monthTotal > 0
                    ? entry.value / monthTotal
                    : 0.0;
                return Padding(
                  padding: const EdgeInsets.fromLTRB(
                      20, 0, 20, 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: TColor.gray60.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color:
                          TColor.border.withOpacity(0.06)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                entry.key,
                                style: TextStyle(
                                    color: TColor.white,
                                    fontSize: 13,
                                    fontWeight:
                                    FontWeight.w600),
                              ),
                            ),
                            Text(
                              "₹${entry.value.toStringAsFixed(2)}",
                              style: TextStyle(
                                  color: TColor.white,
                                  fontSize: 13,
                                  fontWeight:
                                  FontWeight.w700),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "${(ratio * 100).toStringAsFixed(0)}%",
                              style: TextStyle(
                                  color: TColor.gray40,
                                  fontSize: 11),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        LinearProgressIndicator(
                          value: ratio,
                          backgroundColor:
                          TColor.gray60.withOpacity(0.3),
                          valueColor:
                          AlwaysStoppedAnimation(color),
                          minHeight: 2,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList();
            }(),

            const SizedBox(height: 110),
          ],
        ),
      ),
    );
  }
}