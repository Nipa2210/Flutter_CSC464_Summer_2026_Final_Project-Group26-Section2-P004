import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/budget.dart';
import '../models/expense.dart';

class BudgetProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Budget> _budgets = [];

  List<Budget> get budgets => _budgets;

  // Current month's budget
  Budget? get currentBudget {
    final now = DateTime.now();

    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return getBudgetForMonth(
      months[now.month - 1],
      now.year.toString(),
    );
  }

  // Real-time budget stream
  Stream<List<Budget>> getBudgets() {
    return _firestore.collection('budgets').snapshots().map((snapshot) {
      final budgets = snapshot.docs
          .map((doc) => Budget.fromFirestore(doc))
          .toList();

      _budgets = budgets;
      notifyListeners();

      return budgets;
    });
  }

  // Get budget for a specific month and year
  Budget? getBudgetForMonth(String month, String year) {
    try {
      return _budgets.firstWhere(
        (budget) => budget.month == month && budget.year == year,
      );
    } catch (e) {
      return null;
    }
  }

  // Create a new monthly budget
  Future<void> addBudget({
    required String month,
    required String year,
    required double amount,
  }) async {
    final now = DateTime.now();

    await _firestore.collection('budgets').add({
      'month': month,
      'year': year,
      'amount': amount,
      'createdAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
    });
  }

  // Edit an existing budget
  Future<void> updateBudget({
    required String id,
    required String month,
    required String year,
    required double amount,
  }) async {
    await _firestore.collection('budgets').doc(id).update({
      'month': month,
      'year': year,
      'amount': amount,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  // Delete a budget
  Future<void> deleteBudget(String id) async {
    await _firestore.collection('budgets').doc(id).delete();
  }

  // Calculate total expenses for a selected month
  double calculateMonthlyExpense(
    List<Expense> expenses,
    String month,
    String year,
  ) {
    double total = 0;

    for (final expense in expenses) {
      final expenseMonth = _monthName(expense.date.month);
      final expenseYear = expense.date.year.toString();

      if (expenseMonth == month && expenseYear == year) {
        total += expense.amount;
      }
    }

    return total;
  }

  // Calculate remaining amount using the current budget
  double calculateRemaining(double spentAmount) {
    final budget = currentBudget;

    if (budget == null) {
      return 0;
    }

    return budget.amount - spentAmount;
  }

  // Calculate remaining amount using explicit budget and spent values
  double calculateRemainingBudget(
    double budgetAmount,
    double spentAmount,
  ) {
    return budgetAmount - spentAmount;
  }

  // Supports both:
  // calculateUsagePercentage(spent)
  // calculateUsagePercentage(budgetAmount, spent)
  double calculateUsagePercentage(
    double firstAmount, [
    double? secondAmount,
  ]) {
    double budgetAmount;
    double spentAmount;

    if (secondAmount == null) {
      final budget = currentBudget;

      if (budget == null || budget.amount <= 0) {
        return 0;
      }

      budgetAmount = budget.amount;
      spentAmount = firstAmount;
    } else {
      budgetAmount = firstAmount;
      spentAmount = secondAmount;
    }

    if (budgetAmount <= 0) {
      return 0;
    }

    return (spentAmount / budgetAmount) * 100;
  }

  // Calculate over-budget amount
  double calculateOverBudget(
    double budgetAmount,
    double spentAmount,
  ) {
    if (spentAmount <= budgetAmount) {
      return 0;
    }

    return spentAmount - budgetAmount;
  }

  // Create or update budget for a specific month and year
  Future<void> setOrUpdateBudget(
    String month,
    int year,
    double amount,
  ) async {
    final existingBudget = getBudgetForMonth(
      month,
      year.toString(),
    );

    if (existingBudget == null) {
      await addBudget(
        month: month,
        year: year.toString(),
        amount: amount,
      );
    } else {
      await updateBudget(
        id: existingBudget.id,
        month: month,
        year: year.toString(),
        amount: amount,
      );
    }
  }

  String _monthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return months[month - 1];
  }
}