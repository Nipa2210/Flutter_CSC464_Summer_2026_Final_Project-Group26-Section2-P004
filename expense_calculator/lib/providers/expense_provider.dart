import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/expense.dart';

class ExpenseProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Expense> _expenses = [];

  List<Expense> get expenses => _expenses;

  Stream<List<Expense>> getExpenses() {
    return _firestore.collection('expenses').snapshots().map((snapshot) {
      final expenses = snapshot.docs
          .map((doc) => Expense.fromFirestore(doc))
          .toList();

      _expenses = expenses;
      notifyListeners();

      return expenses;
    });
  }

  // Calculate total expenses for a specific month and year
  double totalForMonth(String month, int year) {
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

    final monthNumber = months.indexOf(month) + 1;

    return _expenses
        .where(
          (expense) =>
              expense.date.year == year &&
              expense.date.month == monthNumber,
        )
        .fold(
          0.0,
          (total, expense) => total + expense.amount,
        );
  }
}