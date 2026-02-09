import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/user_model.dart';
import '../models/book.dart';
import '../models/transaction.dart' as models;

class LocalDatabaseService {
  static final LocalDatabaseService instance = LocalDatabaseService._init();
  static Database? _database;

  LocalDatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('money_manager.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    const idType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT NOT NULL';
    const textTypeNullable = 'TEXT';
    const realType = 'REAL NOT NULL';

    // Users table
    await db.execute('''
      CREATE TABLE users (
        id $idType,
        email $textType UNIQUE,
        password $textType,
        displayName $textTypeNullable,
        createdAt $textType
      )
    ''');

    // Books table
    await db.execute('''
      CREATE TABLE books (
        id $idType,
        userId $textType,
        name $textType,
        description $textTypeNullable,
        icon $textType,
        color $textType,
        createdAt $textType,
        updatedAt $textTypeNullable,
        FOREIGN KEY (userId) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // Transactions table
    await db.execute('''
      CREATE TABLE transactions (
        id $idType,
        bookId $textType,
        userId $textType,
        date $textType,
        category $textType,
        description $textType,
        amount $realType,
        type $textType,
        createdAt $textType,
        updatedAt $textTypeNullable,
        FOREIGN KEY (bookId) REFERENCES books (id) ON DELETE CASCADE,
        FOREIGN KEY (userId) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');
  }

  // ========== USER OPERATIONS ==========

  Future<UserModel> createUser({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final db = await database;

    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final user = UserModel(
      id: id,
      email: email,
      displayName: displayName,
      createdAt: DateTime.now(),
    );

    await db.insert(
      'users',
      {
        'id': user.id,
        'email': user.email,
        'password': password, // In production, this should be hashed
        'displayName': user.displayName,
        'createdAt': user.createdAt.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.abort,
    );

    return user;
  }

  Future<UserModel?> getUserByEmail(String email) async {
    final db = await database;

    final maps = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );

    if (maps.isEmpty) return null;

    return UserModel(
      id: maps.first['id'] as String,
      email: maps.first['email'] as String,
      displayName: maps.first['displayName'] as String?,
      createdAt: DateTime.parse(maps.first['createdAt'] as String),
    );
  }

  Future<bool> validateUserCredentials(String email, String password) async {
    final db = await database;

    final maps = await db.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [email, password],
    );

    return maps.isNotEmpty;
  }

  Future<bool> emailExists(String email) async {
    final db = await database;

    final result = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );

    return result.isNotEmpty;
  }

  // ========== BOOK OPERATIONS ==========

  Future<Book> createBook({
    required String userId,
    required String name,
    String? description,
    required String icon,
    required String color,
  }) async {
    final db = await database;

    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final book = Book(
      id: id,
      userId: userId,
      name: name,
      description: description,
      icon: icon,
      color: color,
      createdAt: DateTime.now(),
    );

    await db.insert('books', {
      'id': book.id,
      'userId': book.userId,
      'name': book.name,
      'description': book.description,
      'icon': book.icon,
      'color': book.color,
      'createdAt': book.createdAt.toIso8601String(),
      'updatedAt': book.updatedAt?.toIso8601String(),
    });

    return book;
  }

  Future<List<Book>> getUserBooks(String userId) async {
    final db = await database;

    final maps = await db.query(
      'books',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'createdAt DESC',
    );

    return maps.map((map) => Book.fromJson(map)).toList();
  }

  Future<void> updateBook(Book book) async {
    final db = await database;

    await db.update(
      'books',
      book.copyWith(updatedAt: DateTime.now()).toJson(),
      where: 'id = ?',
      whereArgs: [book.id],
    );
  }

  Future<void> deleteBook(String bookId) async {
    final db = await database;

    // Transactions will be deleted automatically due to CASCADE
    await db.delete(
      'books',
      where: 'id = ?',
      whereArgs: [bookId],
    );
  }

  // ========== TRANSACTION OPERATIONS ==========

  Future<models.Transaction> createTransaction({
    required String bookId,
    required String userId,
    required DateTime date,
    required String category,
    required String description,
    required double amount,
    required models.TransactionType type,
  }) async {
    final db = await database;

    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final transaction = models.Transaction(
      id: id,
      bookId: bookId,
      userId: userId,
      date: date,
      category: category,
      description: description,
      amount: amount,
      type: type,
      createdAt: DateTime.now(),
    );

    await db.insert('transactions', {
      'id': transaction.id,
      'bookId': transaction.bookId,
      'userId': transaction.userId,
      'date': transaction.date.toIso8601String(),
      'category': transaction.category,
      'description': transaction.description,
      'amount': transaction.amount,
      'type': transaction.type.toString().split('.').last,
      'createdAt': transaction.createdAt.toIso8601String(),
      'updatedAt': transaction.updatedAt?.toIso8601String(),
    });

    return transaction;
  }

  Future<List<models.Transaction>> getBookTransactions(String bookId) async {
    final db = await database;

    final maps = await db.query(
      'transactions',
      where: 'bookId = ?',
      whereArgs: [bookId],
      orderBy: 'date DESC',
    );

    return maps.map((map) => models.Transaction.fromJson(map)).toList();
  }

  Future<void> updateTransaction(models.Transaction transaction) async {
    final db = await database;

    await db.update(
      'transactions',
      transaction.copyWith(updatedAt: DateTime.now()).toJson(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  Future<void> deleteTransaction(String transactionId) async {
    final db = await database;

    await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [transactionId],
    );
  }

  Future<double> getBookBalance(String bookId) async {
    final transactions = await getBookTransactions(bookId);

    double balance = 0;
    for (var transaction in transactions) {
      if (transaction.type == models.TransactionType.income) {
        balance += transaction.amount;
      } else {
        balance -= transaction.amount;
      }
    }

    return balance;
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}

class DatabaseException implements Exception {
  final String message;
  DatabaseException(this.message);

  @override
  String toString() => message;
}
