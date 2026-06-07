import 'package:flutter/foundation.dart';
import '../data/models/expense.dart';
import 'expenses_list_viewmodel.dart';
import 'home_viewmodel.dart';

class EditExpenseViewModel extends ChangeNotifier {
  final ExpensesListViewModel expensesVm;
  final HomeViewModel homeVm;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  EditExpenseViewModel({required this.expensesVm, required this.homeVm});

  Future<void> updateExpense(Expense expense, double originalAmount) async {
    _isLoading = true;
    notifyListeners();

    try {
      await expensesVm.updateExpense(expense);
      // Adjust leftovers: revert the old amount and apply the new amount
      // Wait, leftovers logic: when we added expense, we subtracted.
      // So to revert, we add originalAmount. Then subtract new amount.
      // difference = originalAmount - newAmount
      final difference = originalAmount - expense.amount;
      await homeVm.updateLeftovers(difference);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
