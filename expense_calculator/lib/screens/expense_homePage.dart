import 'package:flutter/material.dart';

class ExpenseHomePage extends StatelessWidget {
  const ExpenseHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Calculator'),
      ),
      body: const Center(
        child: Text('Expense Calculator'),
      ),
    );
  }
}