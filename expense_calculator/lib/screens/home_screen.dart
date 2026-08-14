import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/expense.dart';
import '../providers/budget_provider.dart';
import '../providers/expense_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime _selectedMonth = DateTime.now();

  String get _monthName => DateFormat('MMMM').format(_selectedMonth);

  String get _year => _selectedMonth.year.toString();

  Future<void> _selectMonth() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );

    if (selected != null) {
      setState(() {
        _selectedMonth = DateTime(selected.year, selected.month);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Calculator'),
        centerTitle: true,
      ),
      body: StreamBuilder<List<Expense>>(
        stream: context.read<ExpenseProvider>().getExpenses(),
        builder: (context, expenseSnapshot) {
          if (expenseSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (expenseSnapshot.hasError) {
            return Center(
              child: Text(
                'Error loading expenses:\n${expenseSnapshot.error}',
                textAlign: TextAlign.center,
              ),
            );
          }

          final expenses = expenseSnapshot.data ?? [];

          final budgetProvider = context.read<BudgetProvider>();

          final monthlyExpenses = budgetProvider.calculateMonthlyExpense(
            expenses,
            _monthName,
            _year,
          );

          final budget = budgetProvider.getBudgetForMonth(
            _monthName,
            _year,
          );

          final budgetAmount = budget?.amount ?? 0.0;

          final remaining = budgetProvider.calculateRemainingBudget(
            budgetAmount,
            monthlyExpenses,
          );

          final usage = budgetProvider.calculateUsagePercentage(
            budgetAmount,
            monthlyExpenses,
          );

          final overBudget = budgetProvider.calculateOverBudget(
            budgetAmount,
            monthlyExpenses,
          );

          final monthlyExpenseList = expenses.where((expense) {
            return expense.date.month == _selectedMonth.month &&
                expense.date.year == _selectedMonth.year;
          }).toList();

          final categoryTotals = <String, double>{};

          for (final expense in monthlyExpenseList) {
            categoryTotals[expense.category] =
                (categoryTotals[expense.category] ?? 0) + expense.amount;
          }

          String highestCategory = 'None';
          double highestAmount = 0;

          categoryTotals.forEach((category, amount) {
            if (amount > highestAmount) {
              highestAmount = amount;
              highestCategory = category;
            }
          });

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {});
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildMonthSelector(),
                const SizedBox(height: 16),

                _buildSummaryCard(
                  title: 'Total Expense',
                  value: '\$${monthlyExpenses.toStringAsFixed(2)}',
                  icon: Icons.account_balance_wallet,
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: _buildSmallCard(
                        title: 'Budget',
                        value: '\$${budgetAmount.toStringAsFixed(2)}',
                        icon: Icons.savings,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSmallCard(
                        title: 'Expenses',
                        value: '${monthlyExpenseList.length}',
                        icon: Icons.receipt_long,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                _buildBudgetCard(
                  budgetAmount: budgetAmount,
                  monthlyExpenses: monthlyExpenses,
                  remaining: remaining,
                  usage: usage,
                  overBudget: overBudget,
                ),

                const SizedBox(height: 16),

                _buildAnalyticsCard(
                  highestCategory: highestCategory,
                  highestAmount: highestAmount,
                  categoryTotals: categoryTotals,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMonthSelector() {
    return Card(
      child: InkWell(
        onTap: _selectMonth,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.calendar_month),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '$_monthName $_year',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Icon(Icons.arrow_drop_down),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(icon, size: 38),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 15),
                ),
                const SizedBox(height: 5),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 28),
            const SizedBox(height: 10),
            Text(title),
            const SizedBox(height: 5),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetCard({
    required double budgetAmount,
    required double monthlyExpenses,
    required double remaining,
    required double usage,
    required double overBudget,
  }) {
    final isOverBudget = overBudget > 0;

    final progress = budgetAmount <= 0
        ? 0.0
        : (monthlyExpenses / budgetAmount).clamp(0.0, 1.0);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Monthly Budget',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 14),

            Text(
              'Budget: \$${budgetAmount.toStringAsFixed(2)}',
            ),
            Text(
              'Spent: \$${monthlyExpenses.toStringAsFixed(2)}',
            ),

            const SizedBox(height: 8),

            Text(
              isOverBudget
                  ? 'Over Budget: \$${overBudget.toStringAsFixed(2)}'
                  : 'Remaining: \$${remaining.toStringAsFixed(2)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            LinearProgressIndicator(
              value: progress,
              minHeight: 10,
            ),

            const SizedBox(height: 8),

            Text(
              'Usage: ${usage.toStringAsFixed(0)}%',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsCard({
    required String highestCategory,
    required double highestAmount,
    required Map<String, double> categoryTotals,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Expense Analytics',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 14),

            Text(
              'Highest Spending Category: $highestCategory',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),

            if (highestCategory != 'None')
              Text(
                '\$${highestAmount.toStringAsFixed(2)}',
              ),

            const SizedBox(height: 16),

            const Text(
              'Category-wise Spending',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            if (categoryTotals.isEmpty)
              const Text('No expenses recorded for this month.')
            else
              ...categoryTotals.entries.map(
                (entry) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.category),
                  title: Text(entry.key),
                  trailing: Text(
                    '\$${entry.value.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}