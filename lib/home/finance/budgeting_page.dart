import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Custom formatter that adds commas while typing
class ThousandsFormatter extends TextInputFormatter {
  final NumberFormat _formatter = NumberFormat.decimalPattern();

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    String digitsOnly = newValue.text.replaceAll(RegExp('[^0-9]'), '');
    if (digitsOnly.isEmpty) {
      return newValue.copyWith(text: '');
    }
    final formatted = _formatter.format(int.parse(digitsOnly));
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class BudgetingPage extends StatefulWidget {
  const BudgetingPage({Key? key}) : super(key: key);

  @override
  State<BudgetingPage> createState() => _BudgetingPageState();
}

class _BudgetingPageState extends State<BudgetingPage> {
  List<Map<String, dynamic>> _budgets = [];

  final List<IconData> _icons = [
    Icons.fastfood,
    Icons.directions_car,
    Icons.shopping_bag,
    Icons.home,
    Icons.wifi,
    Icons.card_giftcard,
    Icons.sports_esports,
    Icons.wallet,
  ];

  final List<Color> _colors = [
    Colors.purple,
    Colors.deepOrange,
    Colors.blue,
    Colors.green,
    Colors.teal,
    Colors.red,
    Colors.brown,
    Colors.indigo,
  ];

  @override
  void initState() {
    super.initState();
    _loadBudgets();
  }

  Future<void> _loadBudgets() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('budgets');
    if (data != null) {
      setState(() {
        _budgets = List<Map<String, dynamic>>.from(jsonDecode(data));
      });
    }
  }

  Future<void> _saveBudgets() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('budgets', jsonEncode(_budgets));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final totalLimit = _budgets.fold<double>(
        0, (sum, e) => sum + (e['limit'] as num).toDouble());
    final totalSpent = _budgets.fold<double>(
        0, (sum, e) => sum + (e['spent'] as num).toDouble());

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("Budgeting"),
        backgroundColor: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
        centerTitle: true,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddBudgetSheet(context),
        icon: const Icon(Icons.add),
        label: const Text("Add Budget"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Summary
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [Colors.purple.shade400, Colors.deepOrange.shade300],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("This Month",
                    style: TextStyle(color: Colors.white.withOpacity(.9))),
                const SizedBox(height: 4),
                Text(
                  "Budget ₦${NumberFormat.decimalPattern().format(totalLimit)}",
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  "Spent ₦${NumberFormat.decimalPattern().format(totalSpent)} | Remaining ₦${NumberFormat.decimalPattern().format(totalLimit - totalSpent)}",
                  style: TextStyle(color: Colors.white.withOpacity(.9)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Budgets
          if (_budgets.isEmpty)
            Center(
                child: Text("No budgets yet",
                    style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black54))),
          ..._budgets.map((b) {
            final spent = (b['spent'] as num).toDouble();
            final limit = (b['limit'] as num).toDouble();
            final percent = (spent / limit).clamp(0.0, 1.0);

            return GestureDetector(
              onTap: () => _showAddExpenseSheet(context, b),
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? Colors.black12
                          : Colors.grey.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Color(b['color']),
                          child: Icon(
                              IconData(b['icon'], fontFamily: 'MaterialIcons'),
                              color: Colors.white),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                            child: Text(b['category'],
                                style: TextStyle(
                                    color: isDark
                                        ? Colors.white
                                        : Colors.black87,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600))),
                        Text(
                          "₦${NumberFormat.decimalPattern().format(spent)}/₦${NumberFormat.decimalPattern().format(limit)}",
                          style: TextStyle(
                              color: isDark
                                  ? Colors.white70
                                  : Colors.grey.shade700),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.redAccent),
                          onPressed: () => _confirmDeleteBudget(b),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: percent,
                        minHeight: 10,
                        backgroundColor: isDark
                            ? Colors.grey.shade800
                            : Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(
                            percent > 0.8
                                ? Colors.redAccent
                                : Color(b['color'])),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  void _confirmDeleteBudget(Map<String, dynamic> budget) {
    showDialog(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            title: const Text("Delete Budget"),
            content: Text(
                "Are you sure you want to delete '${budget['category']}' budget?"),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("Cancel")),
              TextButton(
                  onPressed: () {
                    setState(() {
                      _budgets.remove(budget);
                    });
                    _saveBudgets();
                    Navigator.pop(ctx);
                  },
                  child: const Text("Delete",
                      style: TextStyle(color: Colors.red))),
            ],
          );
        });
  }

  void _showAddBudgetSheet(BuildContext context) {
    final nameController = TextEditingController();
    final amountController = TextEditingController();

    IconData? selectedIcon = _icons.first;
    Color? selectedColor = _colors.first;

    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) {
          return StatefulBuilder(builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom),
              child: SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                            labelText: "Category name"),
                      ),
                      TextField(
                        controller: amountController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [ThousandsFormatter()],
                        decoration: const InputDecoration(
                            labelText: "Budget limit (₦)"),
                      ),
                      const SizedBox(height: 12),
                      Text("Choose Icon"),
                      Wrap(
                        spacing: 8,
                        children: _icons.map((icon) {
                          final isSelected = selectedIcon == icon;
                          return GestureDetector(
                            onTap: () {
                              setModalState(() {
                                selectedIcon = icon;
                              });
                            },
                            child: CircleAvatar(
                              backgroundColor: isSelected
                                  ? Colors.purple.shade300
                                  : Colors.grey.shade200,
                              child: Icon(icon,
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.black),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),
                      Text("Choose Color"),
                      Wrap(
                        spacing: 8,
                        children: _colors.map((c) {
                          final isSelected = selectedColor == c;
                          return GestureDetector(
                            onTap: () {
                              setModalState(() {
                                selectedColor = c;
                              });
                            },
                            child: CircleAvatar(
                              backgroundColor: c,
                              child: isSelected
                                  ? const Icon(Icons.check,
                                  color: Colors.white)
                                  : null,
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                          onPressed: () {
                            if (nameController.text.isEmpty ||
                                amountController.text.isEmpty) return;

                            final limit = double.parse(
                                amountController.text.replaceAll(',', ''));

                            if (limit < 1000 || limit > 10000000) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'Budget must be between ₦1,000 and ₦10,000,000')));
                              return;
                            }

                            setState(() {
                              _budgets.add({
                                'category': nameController.text,
                                'limit': limit,
                                'spent': 0.0,
                                'icon': selectedIcon!.codePoint,
                                'color': selectedColor!.value,
                              });
                            });
                            _saveBudgets();
                            Navigator.pop(context);
                          },
                          child: const Text("Add Budget"))
                    ],
                  ),
                ),
              ),
            );
          });
        });
  }

  void _showAddExpenseSheet(BuildContext context, Map<String, dynamic> budget) {
    final amountController = TextEditingController();
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) {
          return Padding(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Add expense to ${budget['category']}",
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [ThousandsFormatter()],
                    decoration: const InputDecoration(
                        labelText: "Amount spent (₦)"),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                      onPressed: () {
                        if (amountController.text.isEmpty) return;
                        final amt = double.parse(
                            amountController.text.replaceAll(',', ''));
                        setState(() {
                          budget['spent'] =
                              (budget['spent'] as num).toDouble() + amt;
                        });
                        _saveBudgets();
                        Navigator.pop(context);
                      },
                      child: const Text("Add Expense"))
                ],
              ),
            ),
          );
        });
  }
}
