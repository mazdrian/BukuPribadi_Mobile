import 'transaction.dart';

class Category {
  final String id;
  final String name;
  final String icon;
  final String color;
  final TransactionType type;

  const Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.type,
  });

  static List<Category> get defaultCategories => [
        // Expense categories
        const Category(
          id: 'food',
          name: 'Food & Dining',
          icon: '🍔',
          color: 'FF6B6B',
          type: TransactionType.expense,
        ),
        const Category(
          id: 'transport',
          name: 'Transportation',
          icon: '🚗',
          color: '4ECDC4',
          type: TransactionType.expense,
        ),
        const Category(
          id: 'shopping',
          name: 'Shopping',
          icon: '🛍️',
          color: 'FFD93D',
          type: TransactionType.expense,
        ),
        const Category(
          id: 'entertainment',
          name: 'Entertainment',
          icon: '🎬',
          color: '95E1D3',
          type: TransactionType.expense,
        ),
        const Category(
          id: 'bills',
          name: 'Bills & Utilities',
          icon: '💡',
          color: 'F38181',
          type: TransactionType.expense,
        ),
        const Category(
          id: 'health',
          name: 'Health',
          icon: '⚕️',
          color: 'AA96DA',
          type: TransactionType.expense,
        ),
        const Category(
          id: 'education',
          name: 'Education',
          icon: '📚',
          color: '6C5CE7',
          type: TransactionType.expense,
        ),
        const Category(
          id: 'other_expense',
          name: 'Other',
          icon: '💸',
          color: 'A8E6CF',
          type: TransactionType.expense,
        ),

        // Income categories
        const Category(
          id: 'salary',
          name: 'Salary',
          icon: '💰',
          color: '00B894',
          type: TransactionType.income,
        ),
        const Category(
          id: 'business',
          name: 'Business',
          icon: '💼',
          color: '0984E3',
          type: TransactionType.income,
        ),
        const Category(
          id: 'gift',
          name: 'Gift',
          icon: '🎁',
          color: 'FD79A8',
          type: TransactionType.income,
        ),
        const Category(
          id: 'other_income',
          name: 'Other Income',
          icon: '💵',
          color: '6C5CE7',
          type: TransactionType.income,
        ),
      ];
}
