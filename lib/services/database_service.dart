import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/book.dart';
import '../models/transaction.dart' as models;

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ---------- BOOKS ----------

  // Create a new book
  Future<Book> createBook({
    required String userId,
    required String name,
    String? description,
    required String icon,
    required String color,
  }) async {
    try {
      if (name.isEmpty) {
        throw DatabaseException('Book name is required');
      }

      final bookRef = _firestore.collection('books').doc();
      final book = Book(
        id: bookRef.id,
        userId: userId,
        name: name,
        description: description,
        icon: icon,
        color: color,
        createdAt: DateTime.now(),
      );

      await bookRef.set(book.toJson());
      return book;
    } catch (e) {
      throw DatabaseException('Failed to create book: ${e.toString()}');
    }
  }

  // Get all books for a user
  Stream<List<Book>> getUserBooks(String userId) {
    try {
      return _firestore
          .collection('books')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) =>
              snapshot.docs.map((doc) => Book.fromJson(doc.data())).toList());
    } catch (e) {
      throw DatabaseException('Failed to fetch books: ${e.toString()}');
    }
  }

  // Update a book
  Future<void> updateBook(Book book) async {
    try {
      await _firestore
          .collection('books')
          .doc(book.id)
          .update(book.copyWith(updatedAt: DateTime.now()).toJson());
    } catch (e) {
      throw DatabaseException('Failed to update book: ${e.toString()}');
    }
  }

  // Delete a book and all its transactions
  Future<void> deleteBook(String bookId) async {
    try {
      // Delete all transactions in this book
      final transactions = await _firestore
          .collection('transactions')
          .where('bookId', isEqualTo: bookId)
          .get();

      final batch = _firestore.batch();
      for (var doc in transactions.docs) {
        batch.delete(doc.reference);
      }

      // Delete the book
      batch.delete(_firestore.collection('books').doc(bookId));
      await batch.commit();
    } catch (e) {
      throw DatabaseException('Failed to delete book: ${e.toString()}');
    }
  }

  // ---------- TRANSACTIONS ----------

  // Create a new transaction
  Future<models.Transaction> createTransaction({
    required String bookId,
    required String userId,
    required DateTime date,
    required String category,
    required String description,
    required double amount,
    required models.TransactionType type,
  }) async {
    try {
      if (category.isEmpty) {
        throw DatabaseException('Category is required');
      }

      if (description.isEmpty) {
        throw DatabaseException('Description is required');
      }

      if (amount <= 0) {
        throw DatabaseException('Amount must be greater than zero');
      }

      final transactionRef = _firestore.collection('transactions').doc();
      final transaction = models.Transaction(
        id: transactionRef.id,
        bookId: bookId,
        userId: userId,
        date: date,
        category: category,
        description: description,
        amount: amount,
        type: type,
        createdAt: DateTime.now(),
      );

      await transactionRef.set(transaction.toJson());
      return transaction;
    } catch (e) {
      throw DatabaseException('Failed to create transaction: ${e.toString()}');
    }
  }

  // Get transactions for a book
  Stream<List<models.Transaction>> getBookTransactions(String bookId) {
    try {
      return _firestore
          .collection('transactions')
          .where('bookId', isEqualTo: bookId)
          .orderBy('date', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => models.Transaction.fromJson(doc.data()))
              .toList());
    } catch (e) {
      throw DatabaseException('Failed to fetch transactions: ${e.toString()}');
    }
  }

  // Get transactions for date range
  Stream<List<models.Transaction>> getTransactionsByDateRange({
    required String bookId,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    try {
      return _firestore
          .collection('transactions')
          .where('bookId', isEqualTo: bookId)
          .where('date', isGreaterThanOrEqualTo: startDate.toIso8601String())
          .where('date', isLessThanOrEqualTo: endDate.toIso8601String())
          .orderBy('date', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => models.Transaction.fromJson(doc.data()))
              .toList());
    } catch (e) {
      throw DatabaseException(
          'Failed to fetch transactions by date: ${e.toString()}');
    }
  }

  // Update a transaction
  Future<void> updateTransaction(models.Transaction transaction) async {
    try {
      if (transaction.amount <= 0) {
        throw DatabaseException('Amount must be greater than zero');
      }

      await _firestore
          .collection('transactions')
          .doc(transaction.id)
          .update(transaction.copyWith(updatedAt: DateTime.now()).toJson());
    } catch (e) {
      throw DatabaseException('Failed to update transaction: ${e.toString()}');
    }
  }

  // Delete a transaction
  Future<void> deleteTransaction(String transactionId) async {
    try {
      await _firestore.collection('transactions').doc(transactionId).delete();
    } catch (e) {
      throw DatabaseException('Failed to delete transaction: ${e.toString()}');
    }
  }

  // Get statistics for a book
  Future<Map<String, double>> getBookStatistics(String bookId) async {
    try {
      final snapshot = await _firestore
          .collection('transactions')
          .where('bookId', isEqualTo: bookId)
          .get();

      double totalIncome = 0;
      double totalExpense = 0;

      for (var doc in snapshot.docs) {
        final transaction = models.Transaction.fromJson(doc.data());
        if (transaction.type == models.TransactionType.income) {
          totalIncome += transaction.amount;
        } else {
          totalExpense += transaction.amount;
        }
      }

      return {
        'income': totalIncome,
        'expense': totalExpense,
        'balance': totalIncome - totalExpense,
      };
    } catch (e) {
      throw DatabaseException(
          'Failed to calculate statistics: ${e.toString()}');
    }
  }
}

class DatabaseException implements Exception {
  final String message;
  DatabaseException(this.message);

  @override
  String toString() => message;
}
