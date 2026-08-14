import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/budget_provider.dart';
import '../providers/expense_provider.dart';

class BudgetStatusCard extends StatelessWidget {
  final String currentMonth;
  final int currentYear;

  const BudgetStatusCard({
    Key? key,
    required this.currentMonth,
    required this.currentYear,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final budgetProv = Provider.of<BudgetProvider>(context);
    final expenseProv = Provider.of<ExpenseProvider>(context);

    final budget = budgetProv.currentBudget;
    final double spent = expenseProv.totalForMonth(currentMonth, currentYear);

    if (budget == null) {
      return Card(
        child: ListTile(
          title: Text("No budget set for $currentMonth $currentYear"),
          trailing: ElevatedButton(
            onPressed: () => _showBudgetDialog(context, budgetProv),
            child: const Text("Set Budget"),
          ),
        ),
      );
    }

    final double remaining = budgetProv.calculateRemaining(spent);
    final double usage = budgetProv.calculateUsagePercentage(spent);
    final bool isOverBudget = spent > budget.amount;

    return Card(
      color: isOverBudget ? Colors.red.shade50 : Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("$currentMonth Budget", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  onPressed: () => _showBudgetDialog(context, budgetProv, existingAmount: budget.amount),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text("Budget: \$${budget.amount.toStringAsFixed(2)}"),
            Text("Spent: \$${spent.toStringAsFixed(2)}"),
            if (isOverBudget)
              Text("Over Budget: \$${(spent - budget.amount).toStringAsFixed(2)}",
                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold))
            else
              Text("Remaining: \$${remaining.toStringAsFixed(2)}",
                  style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text("Usage: ${usage.toStringAsFixed(1)}%",
                style: TextStyle(color: isOverBudget ? Colors.red : Colors.black)),
          ],
        ),
      ),
    );
  }

  void _showBudgetDialog(BuildContext context, BudgetProvider provider, {double? existingAmount}) {
    final controller = TextEditingController(text: existingAmount?.toString() ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existingAmount == null ? "Set Budget" : "Edit Budget"),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: "Amount (\$)"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              final val = double.tryParse(controller.text);
              if (val != null) {
                provider.setOrUpdateBudget(currentMonth, currentYear, val);
                Navigator.pop(ctx);
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }
}