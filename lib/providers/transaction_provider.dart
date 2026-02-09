import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/transaction.dart';
import 'book_provider.dart';

final bookTransactionsProvider =
    FutureProvider.family<List<Transaction>, String>((ref, bookId) async {
  final db = ref.watch(localDatabaseServiceProvider);
  return await db.getBookTransactions(bookId);
});

final bookBalanceProvider =
    FutureProvider.family<double, String>((ref, bookId) async {
  final db = ref.watch(localDatabaseServiceProvider);
  return await db.getBookBalance(bookId);
});
