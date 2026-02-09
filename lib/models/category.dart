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
          icon: 'restaurant',
          color: 'FF6B6B',
          type: TransactionType.expense,
        ),
        const Category(
          id: 'transport',
          name: 'Transportation',
          icon: 'directions_car',
          color: '4ECDC4',
          type: TransactionType.expense,
        ),
        const Category(
          id: 'shopping',
          name: 'Shopping',
          icon: 'shopping_bag',
          color: 'FFD93D',
          type: TransactionType.expense,
        ),
        const Category(
          id: 'entertainment',
          name: 'Entertainment',
          icon: 'movie',
          color: '95E1D3',
          type: TransactionType.expense,
        ),
        const Category(
          id: 'bills',
          name: 'Bills & Utilities',
          icon: 'receipt_long',
          color: 'F38181',
          type: TransactionType.expense,
        ),
        const Category(
          id: 'health',
          name: 'Health',
          icon: 'local_hospital',
          color: 'AA96DA',
          type: TransactionType.expense,
        ),
        const Category(
          id: 'education',
          name: 'Education',
          icon: 'school',
          color: '6C5CE7',
          type: TransactionType.expense,
        ),
        const Category(
          id: 'other_expense',
          name: 'Other',
          icon: 'more_horiz',
          color: 'A8E6CF',
          type: TransactionType.expense,
        ),

        // Income categories
        const Category(
          id: 'salary',
          name: 'Salary',
          icon: 'account_balance_wallet',
          color: '00B894',
          type: TransactionType.income,
        ),
        const Category(
          id: 'business',
          name: 'Business',
          icon: 'business_center',
          color: '0984E3',
          type: TransactionType.income,
        ),
        const Category(
          id: 'gift',
          name: 'Gift',
          icon: 'card_giftcard',
          color: 'FD79A8',
          type: TransactionType.income,
        ),
        const Category(
          id: 'other_income',
          name: 'Other Income',
          icon: 'payments',
          color: '6C5CE7',
          type: TransactionType.income,
        ),
      ];
}
