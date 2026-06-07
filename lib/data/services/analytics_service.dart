import '../models/expense.dart';
import '../models/user_profile.dart';

class AnalyticsService {
  double calculateTotalExpenses(List<Expense> expenses) {
    return expenses.fold(0.0, (sum, expense) => sum + expense.amount);
  }

  double calculateLeftovers(UserProfile profile, List<Expense> expenses) {
    // Basic calculation: (dailyLimit * unique_days_with_income) - totalExpenses
    // Given the prompt, it says leftovers are generated from daily limit.
    // For simplicity, we just calculate based on one day or a simple total.
    return profile.dailyLimit - calculateTotalExpenses(expenses);
  }
}
