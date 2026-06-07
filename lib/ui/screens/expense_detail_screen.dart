import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../../core/theme/app_colors.dart';
import '../../core/utils/currency_helper.dart';
import '../../data/models/expense.dart';
import '../../viewmodels/expenses_list_viewmodel.dart';
import 'edit_expense_screen.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/utils/image_helper.dart';

class ExpenseDetailScreen extends StatelessWidget {
  final Expense expense;

  const ExpenseDetailScreen({super.key, required this.expense});

  void _editExpense(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => EditExpenseScreen(expense: expense),
      ),
    );
  }

  void _retakePhoto(BuildContext context) async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      final savedPath = await ImageHelper.saveImageLocally(pickedFile.path);
      final updated = Expense(
        id: expense.id,
        amount: expense.amount,
        category: expense.category,
        comment: expense.comment,
        photoPath: savedPath ?? expense.photoPath,
        date: expense.date,
        currency: expense.currency,
      );
      if (!context.mounted) return;
      final vm = Provider.of<ExpensesListViewModel>(context, listen: false);
      await vm.updateExpense(updated);
      if (!context.mounted) return;
      Navigator.of(context).pop();
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => ExpenseDetailScreen(expense: updated)));
    }
  }

  void _deleteExpense(BuildContext context) async {
    final vm = Provider.of<ExpensesListViewModel>(context, listen: false);
    await vm.deleteExpense(expense.id);
    if (!context.mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Details'),
        actions: [
          IconButton(icon: const Icon(Icons.camera_alt), onPressed: () => _retakePhoto(context)),
          IconButton(icon: const Icon(Icons.edit), onPressed: () => _editExpense(context)),
          IconButton(icon: const Icon(Icons.delete, color: AppColors.error), onPressed: () => _deleteExpense(context)),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (expense.photoPath.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(
                  File(expense.photoPath),
                  height: 300,
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              ),
            if (expense.photoPath.isEmpty)
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.receipt_long, size: 64, color: AppColors.primaryAccent),
                      const SizedBox(height: 16),
                      Text('No photo available', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 32),
            Card(
              color: Theme.of(context).cardColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppColors.border)),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Category: ${expense.category}', style: Theme.of(context).textTheme.displayMedium),
                    const SizedBox(height: 16),
                    Text('Amount: ${CurrencyHelper.getSymbol(expense.currency)}${expense.amount.toStringAsFixed(2)}', style: Theme.of(context).textTheme.displayMedium?.copyWith(color: AppColors.error)),
                    const SizedBox(height: 16),
                    Text('Date: ${DateFormat('MMM dd, yyyy - hh:mm a').format(expense.date)}', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 16)),
                    const SizedBox(height: 24),
                    const Text('Comment:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    Text(expense.comment.isNotEmpty ? expense.comment : 'No comment provided.', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 16)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
