import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/budget_provider.dart';
import '../providers/expense_provider.dart';
import '../models/expense.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
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

  Future<void> _showBudgetDialog({
    required BudgetProvider provider,
    double? existingAmount,
    String? existingId,
  }) async {
    final controller = TextEditingController(
      text: existingAmount?.toString() ?? '',
    );

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            existingId == null ? 'Set Monthly Budget' : 'Edit Budget',
          ),
          content: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
            ),
            decoration: const InputDecoration(
              labelText: 'Budget Amount',
              prefixText: '\$ ',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final amount = double.tryParse(
                  controller.text.trim(),
                );

                if (amount == null || amount <= 0) {
                  return;
                }

                if (existingId == null) {
                  await provider.addBudget(
                    month: _monthName,
                    year: _year,
                    amount: amount,
                  );
                } else {
                  await provider.updateBudget(
                    id: existingId,
                    month: _monthName,
                    year: _year,
                    amount: amount,
                  );
                }

                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    controller.dispose();
  }

  Future<void> _deleteBudget(
    BudgetProvider provider,
    String id,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Budget'),
          content: const Text(
            'Are you sure you want to delete this monthly budget?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await provider.deleteBudget(id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF6C4AB6),
        foregroundColor: Colors.white,
        title: const Text(
          'Monthly Budget',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: StreamBuilder(
        stream: context.read<BudgetProvider>().getBudgets(),
        builder: (context, budgetSnapshot) {
          if (budgetSnapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF6C4AB6),
              ),
            );
          }

          if (budgetSnapshot.hasError) {
            return Center(
              child: Text(
                'Error loading budget:\n${budgetSnapshot.error}',
                textAlign: TextAlign.center,
              ),
            );
          }

          return StreamBuilder<List<Expense>>(
            stream: context.read<ExpenseProvider>().getExpenses(),
            builder: (context, expenseSnapshot) {
              if (expenseSnapshot.connectionState ==
                  ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF6C4AB6),
                  ),
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

              final budgetProvider =
                  context.read<BudgetProvider>();

              final expenses =
                  expenseSnapshot.data ?? <Expense>[];

              final budget =
                  budgetProvider.getBudgetForMonth(
                _monthName,
                _year,
              );

              final budgetAmount = budget?.amount ?? 0.0;

              final spent =
                  budgetProvider.calculateMonthlyExpense(
                expenses,
                _monthName,
                _year,
              );

              final remaining =
                  budgetProvider.calculateRemainingBudget(
                budgetAmount,
                spent,
              );

              final usage =
                  budgetProvider.calculateUsagePercentage(
                budgetAmount,
                spent,
              );

              final overBudget =
                  budgetProvider.calculateOverBudget(
                budgetAmount,
                spent,
              );

              final isOverBudget = overBudget > 0;

              return ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _buildMonthSelector(),

                  const SizedBox(height: 20),

                  if (budget == null)
                    _buildNoBudgetCard(
                      budgetProvider,
                    )
                  else
                    _buildBudgetCard(
                      budgetProvider,
                      budget.id,
                      budget.amount,
                      spent,
                      remaining,
                      usage,
                      overBudget,
                      isOverBudget,
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildMonthSelector() {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: InkWell(
        onTap: _selectMonth,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEDE7F6),
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
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Selected Month',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$_monthName $_year',
                      style: const TextStyle(
                        fontSize: 18,
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

  Widget _buildNoBudgetCard(
    BudgetProvider provider,
  ) {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFF3ECFB),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.savings_outlined,
              size: 45,
              color: Color(0xFF6C4AB6),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'No budget for $_monthName $_year',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Set a monthly budget to start tracking your spending.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () {
                _showBudgetDialog(
                  provider: provider,
                );
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'Set Budget',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C4AB6),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetCard(
    BudgetProvider provider,
    String id,
    double budgetAmount,
    double spent,
    double remaining,
    double usage,
    double overBudget,
    bool isOverBudget,
  ) {
    final progress = budgetAmount <= 0
        ? 0.0
        : (spent / budgetAmount).clamp(0.0, 1.0);

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: isOverBudget
                ? const Color(0xFFFFEBEE)
                : const Color(0xFFEDE7F6),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            children: [
              Icon(
                isOverBudget
                    ? Icons.warning_rounded
                    : Icons.savings_rounded,
                size: 45,
                color: isOverBudget
                    ? Colors.red
                    : const Color(0xFF6C4AB6),
              ),
              const SizedBox(height: 10),
              Text(
                '\$${budgetAmount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                'Monthly Budget',
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: _infoCard(
                'Spent',
                '\$${spent.toStringAsFixed(2)}',
                Icons.payments_rounded,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _infoCard(
                isOverBudget ? 'Over Budget' : 'Remaining',
                '\$${(isOverBudget ? overBudget : remaining).abs().toStringAsFixed(2)}',
                isOverBudget
                    ? Icons.warning_rounded
                    : Icons.account_balance_wallet_rounded,
                isOverBudget ? Colors.red : Colors.green,
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        Card(
          elevation: 0,
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Budget Progress',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 15),
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 12,
                    backgroundColor: Colors.grey.shade200,
                    color: isOverBudget
                        ? Colors.red
                        : const Color(0xFF6C4AB6),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '${usage.toStringAsFixed(1)}% used',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isOverBudget
                        ? Colors.red
                        : const Color(0xFF6C4AB6),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  _showBudgetDialog(
                    provider: provider,
                    existingAmount: budgetAmount,
                    existingId: id,
                  );
                },
                icon: const Icon(Icons.edit_rounded),
                label: const Text('Edit'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  _deleteBudget(provider, id);
                },
                icon: const Icon(Icons.delete_outline_rounded),
                label: const Text('Delete'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _infoCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: color,
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}