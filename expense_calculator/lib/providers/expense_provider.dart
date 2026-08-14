import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/expense.dart';

class ExpenseProvider {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Expense> _expenses = [];

  List<Expense> get expenses => _expenses;

  Stream<List<Expense>> getExpenses() {
    return _firestore.collection('expenses').snapshots().map((snapshot) {
      final expenses = snapshot.docs
          .map((doc) => Expense.fromFirestore(doc))
          .toList();

      _expenses = expenses;
      return expenses;
    });
  }
}