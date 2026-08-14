import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/expense.dart';
import '../providers/budget_provider.dart';
import '../providers/expense_provider.dart';
import 'add_expense_screen.dart';
import 'budget_screen.dart';

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
      helpText: 'Select a month',
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
      backgroundColor: const Color(0xFFF7F7FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF6C4AB6),
        foregroundColor: Colors.white,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Expense Calculator',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 21,
              ),
            ),
            Text(
              'Manage your money wisely',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              setState(() {});
            },
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const BudgetScreen(),
                ),
              );
            },
            icon: const Icon(Icons.savings_outlined),
            tooltip: 'Budget',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AddExpenseScreen(),
            ),
          );
        },
        backgroundColor: const Color(0xFF6C4AB6),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Add Expense',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: StreamBuilder<List<Expense>>(
        stream: context.read<ExpenseProvider>().getExpenses(),
        builder: (context, expenseSnapshot) {
          if (expenseSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF6C4AB6),
              ),
            );
          }

          if (expenseSnapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.cloud_off_rounded,
                      size: 60,
                      color: Colors.redAccent,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Unable to load expenses',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${expenseSnapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
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
            color: const Color(0xFF6C4AB6),
            onRefresh: () async {
              setState(() {});
            },
            child: ListView(
              padding: const EdgeInsets.only(bottom: 30),
              children: [
                _buildHeaderSummary(
                  monthlyExpenses: monthlyExpenses,
                  budgetAmount: budgetAmount,
                  remaining: remaining,
                  overBudget: overBudget,
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                  child: Column(
                    children: [
                      _buildMonthSelector(),

                      const SizedBox(height: 18),

                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              title: 'Budget',
                              value:
                                  '\$${budgetAmount.toStringAsFixed(2)}',
                              icon: Icons.savings_rounded,
                              iconColor: const Color(0xFF4CAF50),
                              backgroundColor: const Color(0xFFEAF7EE),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              title: 'Expenses',
                              value:
                                  '${monthlyExpenseList.length}',
                              icon: Icons.receipt_long_rounded,
                              iconColor: const Color(0xFFFF8A65),
                              backgroundColor: const Color(0xFFFFF0EB),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              title: overBudget > 0
                                  ? 'Over Budget'
                                  : 'Remaining',
                              value: '\$${(overBudget > 0
                                      ? overBudget
                                      : remaining)
                                  .abs()
                                  .toStringAsFixed(2)}',
                              icon: overBudget > 0
                                  ? Icons.warning_rounded
                                  : Icons.account_balance_wallet_rounded,
                              iconColor: overBudget > 0
                                  ? const Color(0xFFE53935)
                                  : const Color(0xFF2196F3),
                              backgroundColor: overBudget > 0
                                  ? const Color(0xFFFFEBEE)
                                  : const Color(0xFFEAF4FF),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              title: 'Categories',
                              value: '${categoryTotals.length}',
                              icon: Icons.category_rounded,
                              iconColor: const Color(0xFF9C6ADE),
                              backgroundColor: const Color(0xFFF3ECFB),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      _buildBudgetCard(
                        budgetAmount: budgetAmount,
                        monthlyExpenses: monthlyExpenses,
                        remaining: remaining,
                        usage: usage,
                        overBudget: overBudget,
                      ),

                      const SizedBox(height: 20),

                      _buildAnalyticsCard(
                        highestCategory: highestCategory,
                        highestAmount: highestAmount,
                        categoryTotals: categoryTotals,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderSummary({
    required double monthlyExpenses,
    required double budgetAmount,
    required double remaining,
    required double overBudget,
  }) {
    final isOverBudget = overBudget > 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 26),
      decoration: const BoxDecoration(
        color: Color(0xFF6C4AB6),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'This Month',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$_monthName $_year',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.18),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total Spending',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '\$${monthlyExpenses.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                if (budgetAmount > 0)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        isOverBudget ? 'Over budget' : 'Remaining',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '\$${(isOverBudget ? overBudget : remaining).abs().toStringAsFixed(2)}',
                        style: TextStyle(
                          color: isOverBudget
                              ? const Color(0xFFFFCDD2)
                              : const Color(0xFFC8E6C9),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthSelector() {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: Colors.grey.shade200,
        ),
      ),
      child: InkWell(
        onTap: _selectMonth,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 16,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0EAF8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.calendar_month_rounded,
                  color: Color(0xFF6C4AB6),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Selected Month',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$_monthName $_year',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Color(0xFF6C4AB6),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
    required Color backgroundColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 23,
            ),
          ),
          const SizedBox(height: 13),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
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

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isOverBudget
                      ? const Color(0xFFFFEBEE)
                      : const Color(0xFFEDE7F6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isOverBudget
                      ? Icons.warning_amber_rounded
                      : Icons.track_changes_rounded,
                  color: isOverBudget
                      ? const Color(0xFFE53935)
                      : const Color(0xFF6C4AB6),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Monthly Budget',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Track your spending progress',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _budgetAmountText(
                'Budget',
                budgetAmount,
                const Color(0xFF6C4AB6),
              ),
              _budgetAmountText(
                'Spent',
                monthlyExpenses,
                const Color(0xFFFF7043),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 12,
              backgroundColor: Colors.grey.shade200,
              color: isOverBudget
                  ? const Color(0xFFE53935)
                  : const Color(0xFF6C4AB6),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${usage.toStringAsFixed(1)}% used',
                style: TextStyle(
                  color: isOverBudget
                      ? const Color(0xFFE53935)
                      : const Color(0xFF6C4AB6),
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                isOverBudget
                    ? 'Over \$${overBudget.toStringAsFixed(2)}'
                    : '\$${remaining.toStringAsFixed(2)} left',
                style: TextStyle(
                  color: isOverBudget
                      ? const Color(0xFFE53935)
                      : const Color(0xFF43A047),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _budgetAmountText(
    String title,
    double amount,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          '\$${amount.toStringAsFixed(2)}',
          style: TextStyle(
            color: color,
            fontSize: 19,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildAnalyticsCard({
    required String highestCategory,
    required double highestAmount,
    required Map<String, double> categoryTotals,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.bar_chart_rounded,
                  color: Color(0xFFFF9800),
                ),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Expense Analytics',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'See where your money goes',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFF3ECFB),
                  Color(0xFFEDE7F6),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 23,
                  backgroundColor: Color(0xFF6C4AB6),
                  child: Icon(
                    Icons.trending_up_rounded,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Highest Spending',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        highestCategory,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                if (highestCategory != 'None')
                  Text(
                    '\$${highestAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Color(0xFF6C4AB6),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Category-wise Spending',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 10),
          if (categoryTotals.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F8FA),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 35,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'No expenses recorded for this month.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          else
            ...categoryTotals.entries.map(
              (entry) => _buildCategoryRow(
                entry.key,
                entry.value,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCategoryRow(
    String category,
    double amount,
  ) {
    final icons = <String, IconData>{
      'Food': Icons.restaurant_rounded,
      'Transport': Icons.directions_car_rounded,
      'Shopping': Icons.shopping_bag_rounded,
      'Bills': Icons.receipt_rounded,
      'Entertainment': Icons.movie_rounded,
      'Health': Icons.favorite_rounded,
      'Education': Icons.school_rounded,
    };

    final icon = icons[category] ?? Icons.category_rounded;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 11,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8FA),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFEDE7F6),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 19,
              color: const Color(0xFF6C4AB6),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              category,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            '\$${amount.toStringAsFixed(2)}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}