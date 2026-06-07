import 'dart:convert';

class Expense {
  final String id;
  final double amount;
  final String category;
  final String comment;
  final String photoPath;
  final DateTime date;
  final String currency;

  Expense({
    required this.id,
    required this.amount,
    required this.category,
    required this.comment,
    required this.photoPath,
    required this.date,
    required this.currency,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'category': category,
      'comment': comment,
      'photoPath': photoPath,
      'date': date.toIso8601String(),
      'currency': currency,
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'],
      amount: map['amount'],
      category: map['category'],
      comment: map['comment'],
      photoPath: map['photoPath'],
      date: DateTime.parse(map['date']),
      currency: map['currency'] ?? 'USD', // Fallback for old records
    );
  }

  String toJson() => json.encode(toMap());

  factory Expense.fromJson(String source) => Expense.fromMap(json.decode(source));
}
