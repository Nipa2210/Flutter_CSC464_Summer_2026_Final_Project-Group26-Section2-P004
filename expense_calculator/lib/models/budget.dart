//import 'package:cloud_firestore/cloud_firestore.dart';

class Budget {
  final String id;
  final String name;
  final double amount;
  final DateTime createdAt;
  final DateTime updatedAt;

  Budget({
    required this.id,
    required this.name,
    required this.amount,
    required this.createdAt,
    required this.updatedAt,
  })

  // factory Budget.fromFirestore(DocumentSnapshot doc) {
  //   final data = doc.data() as Map<String, dynamic>;
  //   return Budget(
  //     id: doc.id,
  //     month: data['month'] ?? '',
  //     year: data['year'] ?? '',
  //     amount: (data['amount'] ?? 0.0).toDouble(),
  //     createdAt: (data['createdAt'] as Timestamp).toDate(),
  //     updatedAt: (data['updatedAt'] as Timestamp).toDate(),
  //   );
  //}
Map<String, dynamic> toFirestore() {
    return {
      'month': month,
      'year': year,
      'amount': amount,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}