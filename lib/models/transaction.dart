class Transaction {
  final String id;
  final String bookId;
  final String userId;
  final DateTime date;
  final String category;
  final String description;
  final double amount;
  final TransactionType type; // income or expense
  final DateTime createdAt;
  final DateTime? updatedAt;

  Transaction({
    required this.id,
    required this.bookId,
    required this.userId,
    required this.date,
    required this.category,
    required this.description,
    required this.amount,
    required this.type,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bookId': bookId,
      'userId': userId,
      'date': date.toIso8601String(),
      'category': category,
      'description': description,
      'amount': amount,
      'type': type.toString().split('.').last,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as String,
      bookId: json['bookId'] as String,
      userId: json['userId'] as String,
      date: DateTime.parse(json['date'] as String),
      category: json['category'] as String,
      description: json['description'] as String,
      amount: (json['amount'] as num).toDouble(),
      type: TransactionType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => TransactionType.expense,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  Transaction copyWith({
    String? id,
    String? bookId,
    String? userId,
    DateTime? date,
    String? category,
    String? description,
    double? amount,
    TransactionType? type,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Transaction(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      category: category ?? this.category,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

enum TransactionType {
  income,
  expense,
}
