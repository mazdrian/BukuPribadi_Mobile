import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/local_database_service.dart';
import '../models/book.dart';

final localDatabaseServiceProvider = Provider<LocalDatabaseService>((ref) {
  return LocalDatabaseService.instance;
});

final userBooksProvider =
    FutureProvider.family<List<Book>, String>((ref, userId) async {
  final db = ref.watch(localDatabaseServiceProvider);
  return await db.getUserBooks(userId);
});

// Note: For selected book state management, use local widget state
// or pass Book object through navigation parameters
