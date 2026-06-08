import 'package:flutter/material.dart';
import '../data/models/expense.dart';
import '../data/services/local_storage_service.dart';

class ExpensesListViewModel extends ChangeNotifier {
  final LocalStorageService _storage = LocalStorageService();
  
  List<Expense> _expenses = [];
  bool _isLoading = true;
  String? _errorMessage;

  List<Expense> get expenses => _expenses;
  bool get isLoading => _isLoading;
  bool get hasError => _errorMessage != null;
  String? get errorMessage => _errorMessage;

  Future<void> loadExpenses() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _expenses = await _storage.getExpenses();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addExpense(Expense expense) async {
    _expenses.add(expense);
    await _storage.saveExpenses(_expenses);
    notifyListeners();
  }

  Future<void> deleteExpense(String id) async {
    _expenses.removeWhere((e) => e.id == id);
    await _storage.saveExpenses(_expenses);
    notifyListeners();
  }

  Future<void> updateExpense(Expense updated) async {
    final index = _expenses.indexWhere((e) => e.id == updated.id);
    if (index != -1) {
      _expenses[index] = updated;
      await _storage.saveExpenses(_expenses);
      notifyListeners();
    }
  }

  // Filtering
  String? _filterCategory;
  bool? _filterHasPhoto;
  DateTimeRange? _filterDateRange;

  String? get filterCategory => _filterCategory;
  bool? get filterHasPhoto => _filterHasPhoto;
  DateTimeRange? get filterDateRange => _filterDateRange;

  void setFilterCategory(String? category) {
    _filterCategory = category;
    notifyListeners();
  }

  void setFilterHasPhoto(bool? hasPhoto) {
    _filterHasPhoto = hasPhoto;
    notifyListeners();
  }

  void setFilterDateRange(DateTimeRange? range) {
    _filterDateRange = range;
    notifyListeners();
  }

  void clearFilters() {
    _filterCategory = null;
    _filterHasPhoto = null;
    _filterDateRange = null;
    notifyListeners();
  }

  List<Expense> get filteredExpenses {
    return _expenses.where((e) {
      if (_filterCategory != null && e.category != _filterCategory) return false;
      if (_filterHasPhoto != null) {
        if (_filterHasPhoto == true && e.photoPath.isEmpty) return false;
        if (_filterHasPhoto == false && e.photoPath.isNotEmpty) return false;
      }
      if (_filterDateRange != null) {
        if (e.date.isBefore(_filterDateRange!.start) || e.date.isAfter(_filterDateRange!.end.add(const Duration(days: 1)))) {
          return false;
        }
      }
      return true;
    }).toList();
  }
}
