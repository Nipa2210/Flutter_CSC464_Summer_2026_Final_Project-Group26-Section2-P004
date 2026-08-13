// // import 'package:cloud_firestore/cloud_firestore.dart';

class Expense {
  final String id;
  final String name;
  final double amount;
  final String category;
  final String description;
  final DateTime date;
  final DateTime createdAt;

  Expense({
    required this.id,
    required this.name,
    required this.amount,
    required this.category,
    this.description = '',
    required this.date,
    required this.createdAt,
  });

  ///factory Expense.fromFirestore(DocumentSnapshot doc) {
  //   final data = doc.data() as Map<String, dynamic>;
  //   return Expense(
  //     id: doc.id,
  //     name: data['name'] ?? '',
  //     amount: (data['amount'] ?? 0.0).toDouble(),
  //     category: data['category'] ?? 'Other',
  //     description: data['description'] ?? '',
  //     date: (data['date'] as Timestamp).toDate(),
  //     createdAt: (data['createdAt'] as Timestamp).toDate(),
  //   );
  // }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'amount': amount,
      'category': category,
      'description': description,
      ///'date': Timestamp.fromDate(date),
      ///'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}