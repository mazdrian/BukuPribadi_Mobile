import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/book.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../code/icon_helper.dart';
import '../code/app_theme.dart';
import '../providers/transaction_provider.dart';
import '../providers/book_provider.dart';
import 'add_transaction_screen.dart';
import 'scan_receipt_screen.dart';
import 'create_book_screen.dart';
import 'report_screen.dart';
import '../services/local_database_service.dart';
import 'package:intl/intl.dart';

class BookDetailScreen extends ConsumerStatefulWidget {
  final Book book;

  const BookDetailScreen({super.key, required this.book});

  @override
  ConsumerState<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends ConsumerState<BookDetailScreen> {
  late Book _currentBook;
  String? _selectedCategory;
  DateTimeRange? _selectedDateRange;
  TransactionType? _selectedType;

  // Selection mode
  bool _isSelectionMode = false;
  final Set<String> _selectedTransactionIds = {};

  @override
  void initState() {
    super.initState();
    _currentBook = widget.book;
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedTransactionIds.clear();
      }
    });
  }

  void _toggleTransactionSelection(String id) {
    setState(() {
      if (_selectedTransactionIds.contains(id)) {
        _selectedTransactionIds.remove(id);
      } else {
        _selectedTransactionIds.add(id);
      }
      if (_selectedTransactionIds.isEmpty) {
        _isSelectionMode = false;
      }
    });
  }

  void _selectAll(List<Transaction> transactions) {
    setState(() {
      _selectedTransactionIds.addAll(transactions.map((t) => t.id));
    });
  }

  void _deselectAll() {
    setState(() {
      _selectedTransactionIds.clear();
    });
  }

  Map<String, double> _calculateSelectedTotals(List<Transaction> transactions) {
    double income = 0;
    double expense = 0;
    for (var t in transactions) {
      if (_selectedTransactionIds.contains(t.id)) {
        if (t.type == TransactionType.income) {
          income += t.amount;
        } else {
          expense += t.amount;
        }
      }
    }
    return {
      'income': income,
      'expense': expense,
      'balance': income - expense,
      'count': _selectedTransactionIds.length.toDouble(),
    };
  }

  List<Transaction> _applyFilters(List<Transaction> transactions) {
    var filtered = transactions;

    // Filter by transaction type
    if (_selectedType != null) {
      filtered = filtered.where((t) => t.type == _selectedType).toList();
    }

    // Filter by category
    if (_selectedCategory != null) {
      filtered =
          filtered.where((t) => t.category == _selectedCategory).toList();
    }

    // Filter by date range
    if (_selectedDateRange != null) {
      final start = DateTime(
        _selectedDateRange!.start.year,
        _selectedDateRange!.start.month,
        _selectedDateRange!.start.day,
      );
      final end = DateTime(
        _selectedDateRange!.end.year,
        _selectedDateRange!.end.month,
        _selectedDateRange!.end.day,
        23,
        59,
        59,
      );
      filtered = filtered
          .where((t) =>
              t.date.isAfter(start.subtract(const Duration(seconds: 1))) &&
              t.date.isBefore(end.add(const Duration(seconds: 1))))
          .toList();
    }

    return filtered;
  }

  void _showFilterBottomSheet(List<Transaction> allTransactions) {
    // Get unique categories from existing transactions
    final categories = allTransactions.map((t) => t.category).toSet().toList()
      ..sort();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle bar
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    // Title
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Filter Transactions',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (_selectedCategory != null ||
                            _selectedDateRange != null ||
                            _selectedType != null)
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _selectedCategory = null;
                                _selectedDateRange = null;
                                _selectedType = null;
                              });
                              setModalState(() {});
                              Navigator.pop(context);
                            },
                            child: const Text(
                              'Clear All',
                              style: TextStyle(
                                color: AppColors.expense,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Type filter
                    const Text(
                      'Transaction Type',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _FilterChip(
                          label: 'All',
                          isSelected: _selectedType == null,
                          color: AppColors.primary,
                          onTap: () {
                            setState(() => _selectedType = null);
                            setModalState(() {});
                          },
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'Income',
                          isSelected: _selectedType == TransactionType.income,
                          color: AppColors.income,
                          onTap: () {
                            setState(
                                () => _selectedType = TransactionType.income);
                            setModalState(() {});
                          },
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'Expense',
                          isSelected: _selectedType == TransactionType.expense,
                          color: AppColors.expense,
                          onTap: () {
                            setState(
                                () => _selectedType = TransactionType.expense);
                            setModalState(() {});
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Category filter
                    const Text(
                      'Category',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _FilterChip(
                          label: 'All Categories',
                          isSelected: _selectedCategory == null,
                          color: AppColors.primary,
                          onTap: () {
                            setState(() => _selectedCategory = null);
                            setModalState(() {});
                          },
                        ),
                        ...categories.map((cat) => _FilterChip(
                              label: cat,
                              isSelected: _selectedCategory == cat,
                              color: AppColors.primary,
                              onTap: () {
                                setState(() => _selectedCategory = cat);
                                setModalState(() {});
                              },
                            )),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Date range filter
                    const Text(
                      'Date Range',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    InkWell(
                      onTap: () async {
                        final now = DateTime.now();
                        final picked = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime(2020),
                          lastDate: now.add(const Duration(days: 365)),
                          initialDateRange: _selectedDateRange,
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: const ColorScheme.light(
                                  primary: AppColors.primary,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null) {
                          setState(() => _selectedDateRange = picked);
                          setModalState(() {});
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _selectedDateRange != null
                              ? AppColors.primary.withOpacity(0.1)
                              : Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _selectedDateRange != null
                                ? AppColors.primary
                                : Colors.grey[300]!,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.date_range_rounded,
                              color: _selectedDateRange != null
                                  ? AppColors.primary
                                  : Colors.grey[600],
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _selectedDateRange != null
                                    ? '${DateFormat('MMM dd, yyyy').format(_selectedDateRange!.start)} - ${DateFormat('MMM dd, yyyy').format(_selectedDateRange!.end)}'
                                    : 'Select date range...',
                                style: TextStyle(
                                  color: _selectedDateRange != null
                                      ? AppColors.primary
                                      : Colors.grey[600],
                                  fontWeight: _selectedDateRange != null
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                            if (_selectedDateRange != null)
                              GestureDetector(
                                onTap: () {
                                  setState(() => _selectedDateRange = null);
                                  setModalState(() {});
                                },
                                child: Icon(
                                  Icons.close_rounded,
                                  size: 20,
                                  color: Colors.grey[600],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Apply button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Apply Filters',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _refreshData() {
    ref.invalidate(bookTransactionsProvider(_currentBook.id));
    ref.invalidate(bookBalanceProvider(_currentBook.id));
  }

  Future<void> _navigateToEditBook() async {
    final result = await Navigator.of(context).push<dynamic>(
      MaterialPageRoute(
        builder: (context) => CreateBookScreen(
          userId: _currentBook.userId,
          bookToEdit: _currentBook,
        ),
      ),
    );
    if (result == true) {
      // Re-fetch the updated book from database
      try {
        final books = await LocalDatabaseService.instance
            .getUserBooks(_currentBook.userId);
        final updatedBook = books.firstWhere(
          (b) => b.id == _currentBook.id,
          orElse: () => _currentBook,
        );
        setState(() {
          _currentBook = updatedBook;
        });
      } catch (_) {}
      _refreshData();
      ref.invalidate(userBooksProvider(_currentBook.userId));
    }
  }

  Future<void> _navigateToAddTransaction(
      {Transaction? transactionToEdit}) async {
    final result = await Navigator.of(context).push<dynamic>(
      MaterialPageRoute(
        builder: (context) => AddTransactionScreen(
          book: _currentBook,
          transactionToEdit: transactionToEdit,
        ),
      ),
    );
    if (result == true) {
      _refreshData();
    }
  }

  Future<void> _navigateToScanReceipt() async {
    final result = await Navigator.of(context).push<ScannedTransactionData>(
      MaterialPageRoute(
        builder: (context) => ScanReceiptScreen(book: _currentBook),
      ),
    );
    if (result != null) {
      // Auto-create the transaction from scanned data
      try {
        await LocalDatabaseService.instance.createTransaction(
          bookId: _currentBook.id,
          userId: _currentBook.userId,
          date: result.date,
          category: result.categoryId,
          description: result.description,
          amount: result.amount,
          type: result.type,
        );
        _refreshData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Transaction added from receipt!'),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              backgroundColor: AppColors.income,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString()}')),
          );
        }
      }
    }
  }

  Future<void> _deleteTransaction(Transaction transaction) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Transaction?'),
        content: Text(
          'Delete "${transaction.description}" for ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(transaction.amount)}?\n\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await LocalDatabaseService.instance.deleteTransaction(transaction.id);
        _refreshData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('"${transaction.description}" deleted'),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              action: SnackBarAction(
                label: 'OK',
                onPressed: () {},
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString()}')),
          );
        }
      }
    }
  }

  Future<void> _deleteBook() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Book?'),
        content: const Text(
          'This will delete the book and all its transactions. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        await LocalDatabaseService.instance.deleteBook(_currentBook.id);
        ref.invalidate(userBooksProvider(_currentBook.userId));
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString()}')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final transactionsAsync =
        ref.watch(bookTransactionsProvider(_currentBook.id));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // App Bar with Book Info
          _isSelectionMode
              ? SliverAppBar(
                  pinned: true,
                  elevation: 0,
                  backgroundColor: AppColors.primary,
                  leading: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: _toggleSelectionMode,
                  ),
                  title: Text(
                    '${_selectedTransactionIds.length} selected',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  actions: [
                    transactionsAsync.when(
                      data: (transactions) {
                        final filtered = _applyFilters(transactions);
                        final allSelected = filtered.isNotEmpty &&
                            filtered.every(
                                (t) => _selectedTransactionIds.contains(t.id));
                        return IconButton(
                          icon: Icon(
                            allSelected
                                ? Icons.deselect_rounded
                                : Icons.select_all_rounded,
                          ),
                          tooltip: allSelected ? 'Deselect All' : 'Select All',
                          onPressed: () {
                            if (allSelected) {
                              _deselectAll();
                            } else {
                              _selectAll(filtered);
                            }
                          },
                        );
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ],
                )
              : SliverAppBar(
                  expandedHeight: 180,
                  pinned: true,
                  elevation: 0,
                  backgroundColor: AppColors.background,
                  foregroundColor: AppColors.textPrimary,
                  flexibleSpace: FlexibleSpaceBar(
                    title: Text(
                      _currentBook.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    centerTitle: false,
                    titlePadding: const EdgeInsets.only(left: 56, bottom: 16),
                    background: Container(
                      color: AppColors.background,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 40),
                            Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: Color(int.parse(
                                        'FF${_currentBook.color}',
                                        radix: 16))
                                    .withOpacity(0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                IconHelper.getIcon(_currentBook.icon),
                                size: 44,
                                color: Color(int.parse(
                                    'FF${_currentBook.color}',
                                    radix: 16)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  actions: [
                    // Report button
                    IconButton(
                      icon: const Icon(Icons.bar_chart_rounded),
                      tooltip: 'Reports',
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ReportScreen(book: _currentBook),
                          ),
                        );
                      },
                    ),
                    PopupMenuButton<String>(
                      onSelected: (value) async {
                        if (value == 'edit') {
                          _navigateToEditBook();
                        } else if (value == 'delete') {
                          _deleteBook();
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit_rounded,
                                  size: 20, color: AppColors.primary),
                              SizedBox(width: 12),
                              Text('Edit Book'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_rounded,
                                  size: 20, color: AppColors.expense),
                              const SizedBox(width: 12),
                              Text('Delete Book',
                                  style: TextStyle(color: AppColors.expense)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

          // Statistics Section
          transactionsAsync.when(
            data: (transactions) {
              double income = 0;
              double expense = 0;
              for (var transaction in transactions) {
                if (transaction.type == TransactionType.income) {
                  income += transaction.amount;
                } else {
                  expense += transaction.amount;
                }
              }
              final balance = income - expense;
              final stats = {
                'income': income,
                'expense': expense,
                'balance': balance,
              };

              return SliverToBoxAdapter(
                child: _StatisticsCard(stats: stats),
              );
            },
            loading: () => const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
            error: (error, stack) => SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Error loading statistics: $error'),
              ),
            ),
          ),

          // Filter Bar
          transactionsAsync.when(
            data: (transactions) {
              if (transactions.isEmpty) {
                return const SliverToBoxAdapter(child: SizedBox.shrink());
              }
              final hasActiveFilters = _selectedCategory != null ||
                  _selectedDateRange != null ||
                  _selectedType != null;
              final filteredCount = _applyFilters(transactions).length;
              return SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          hasActiveFilters
                              ? 'Showing $filteredCount of ${transactions.length} transactions'
                              : 'All Transactions',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: hasActiveFilters
                                ? AppColors.primary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                      Material(
                        color: hasActiveFilters
                            ? AppColors.primary
                            : AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(12),
                        elevation: hasActiveFilters ? 2 : 0,
                        child: InkWell(
                          onTap: () => _showFilterBottomSheet(transactions),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.filter_list_rounded,
                                  size: 18,
                                  color: hasActiveFilters
                                      ? Colors.white
                                      : AppColors.primary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Filter',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: hasActiveFilters
                                        ? Colors.white
                                        : AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
            loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
            error: (_, __) =>
                const SliverToBoxAdapter(child: SizedBox.shrink()),
          ),

          // Active Filter Chips
          transactionsAsync.when(
            data: (transactions) {
              final chips = <Widget>[];
              if (_selectedType != null) {
                chips.add(_ActiveFilterChip(
                  label: _selectedType == TransactionType.income
                      ? 'Income'
                      : 'Expense',
                  color: _selectedType == TransactionType.income
                      ? AppColors.income
                      : AppColors.expense,
                  onRemove: () => setState(() => _selectedType = null),
                ));
              }
              if (_selectedCategory != null) {
                chips.add(_ActiveFilterChip(
                  label: _selectedCategory!,
                  color: AppColors.primary,
                  onRemove: () => setState(() => _selectedCategory = null),
                ));
              }
              if (_selectedDateRange != null) {
                chips.add(_ActiveFilterChip(
                  label:
                      '${DateFormat('MMM dd').format(_selectedDateRange!.start)} - ${DateFormat('MMM dd').format(_selectedDateRange!.end)}',
                  color: AppColors.primary,
                  onRemove: () => setState(() => _selectedDateRange = null),
                ));
              }
              if (chips.isEmpty) {
                return const SliverToBoxAdapter(child: SizedBox.shrink());
              }
              return SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: chips,
                  ),
                ),
              );
            },
            loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
            error: (_, __) =>
                const SliverToBoxAdapter(child: SizedBox.shrink()),
          ),

          // Transactions List
          transactionsAsync.when(
            data: (transactions) {
              final filteredTransactions = _applyFilters(transactions);

              if (transactions.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 80,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No transactions yet',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Tap + to add your first transaction',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (filteredTransactions.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.filter_list_off_rounded,
                          size: 80,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No matching transactions',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Try adjusting your filters',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 16),
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _selectedCategory = null;
                              _selectedDateRange = null;
                              _selectedType = null;
                            });
                          },
                          icon: const Icon(Icons.clear_all_rounded),
                          label: const Text('Clear Filters'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final transaction = filteredTransactions[index];
                    return _TransactionItem(
                      transaction: transaction,
                      bookColor: _currentBook.color,
                      isSelectionMode: _isSelectionMode,
                      isSelected:
                          _selectedTransactionIds.contains(transaction.id),
                      onEdit: () => _navigateToAddTransaction(
                          transactionToEdit: transaction),
                      onDelete: () => _deleteTransaction(transaction),
                      onSelect: () =>
                          _toggleTransactionSelection(transaction.id),
                      onLongPress: () {
                        if (!_isSelectionMode) {
                          setState(() => _isSelectionMode = true);
                          _toggleTransactionSelection(transaction.id);
                        }
                      },
                    );
                  },
                  childCount: filteredTransactions.length,
                ),
              );
            },
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, stack) => SliverFillRemaining(
              child: Center(
                child: Text('Error: ${error.toString()}'),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: _isSelectionMode
          ? null
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton.small(
                  heroTag: 'scan',
                  onPressed: () => _navigateToScanReceipt(),
                  backgroundColor: AppColors.surfaceVariant,
                  elevation: 2,
                  child: Icon(Icons.document_scanner_rounded,
                      color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 12),
                FloatingActionButton(
                  heroTag: 'add',
                  onPressed: () => _navigateToAddTransaction(),
                  backgroundColor: AppColors.primary,
                  elevation: 4,
                  child: const Icon(Icons.add_rounded,
                      color: Colors.white, size: 28),
                ),
              ],
            ),
      bottomNavigationBar: _isSelectionMode
          ? transactionsAsync.when(
              data: (transactions) {
                final filtered = _applyFilters(transactions);
                final totals = _calculateSelectedTotals(filtered);
                if (_selectedTransactionIds.isEmpty) {
                  return const SizedBox.shrink();
                }
                return _SelectionSummaryBar(totals: totals);
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            )
          : null,
    );
  }
}

class _StatisticsCard extends StatelessWidget {
  final Map<String, double> stats;

  const _StatisticsCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    final income = stats['income'] ?? 0;
    final expense = stats['expense'] ?? 0;
    final balance = stats['balance'] ?? 0;
    final fmt =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _StatItem(
                  label: 'Income',
                  amount: income,
                  color: AppColors.income,
                  icon: Icons.arrow_downward_rounded,
                ),
              ),
              Container(
                width: 1,
                height: 50,
                color: AppColors.divider,
              ),
              Expanded(
                child: _StatItem(
                  label: 'Expense',
                  amount: expense,
                  color: AppColors.expense,
                  icon: Icons.arrow_upward_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: balance >= 0 ? AppColors.incomeBg : AppColors.expenseBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.account_balance_wallet_rounded,
                      color:
                          balance >= 0 ? AppColors.income : AppColors.expense,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Balance',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                Text(
                  fmt.format(balance),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: balance >= 0 ? AppColors.income : AppColors.expense,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final IconData icon;

  const _StatItem({
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 10),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          NumberFormat.currency(
                  locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0)
              .format(amount),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _TransactionItem extends StatelessWidget {
  final Transaction transaction;
  final String bookColor;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback? onSelect;
  final VoidCallback? onLongPress;

  const _TransactionItem({
    required this.transaction,
    required this.bookColor,
    required this.onEdit,
    required this.onDelete,
    this.isSelectionMode = false,
    this.isSelected = false,
    this.onSelect,
    this.onLongPress,
  });

  void _showOptionsBottomSheet(BuildContext context) {
    final isIncome = transaction.type == TransactionType.income;
    final color = isIncome ? AppColors.income : AppColors.expense;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Transaction info header
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [color, color.withOpacity(0.7)],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          isIncome
                              ? Icons.arrow_downward_rounded
                              : Icons.arrow_upward_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              transaction.description,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              '${isIncome ? '+' : '-'} ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(transaction.amount)}',
                              style: TextStyle(
                                color: color,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 24),
                // Edit option
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.edit_rounded,
                        color: AppColors.primary, size: 20),
                  ),
                  title: const Text('Edit Transaction',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Modify amount, category, or details'),
                  onTap: () {
                    Navigator.pop(context);
                    onEdit();
                  },
                ),
                // Delete option
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.delete_rounded,
                        color: Colors.red, size: 20),
                  ),
                  title: const Text('Delete Transaction',
                      style: TextStyle(
                          fontWeight: FontWeight.w600, color: Colors.red)),
                  subtitle: const Text('Remove this transaction permanently'),
                  onTap: () {
                    Navigator.pop(context);
                    onDelete();
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == TransactionType.income;
    final color = isIncome ? AppColors.income : AppColors.expense;

    return Dismissible(
      key: Key(transaction.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        onDelete();
        return false; // We handle deletion in onDelete with confirmation
      },
      background: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete_rounded, color: Colors.white, size: 24),
            SizedBox(height: 4),
            Text('Delete',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
      child: GestureDetector(
        onTap:
            isSelectionMode ? onSelect : () => _showOptionsBottomSheet(context),
        onLongPress: isSelectionMode
            ? null
            : (onLongPress ?? () => _showOptionsBottomSheet(context)),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withOpacity(0.06)
                : AppColors.cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: isSelected
                ? Border.all(
                    color: AppColors.primary.withOpacity(0.2), width: 1.5)
                : null,
            boxShadow: isSelected
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            horizontalTitleGap: 12,
            leading: isSelectionMode
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Checkbox(
                          value: isSelected,
                          onChanged: (_) => onSelect?.call(),
                          activeColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          isIncome
                              ? Icons.arrow_downward_rounded
                              : Icons.arrow_upward_rounded,
                          color: color,
                          size: 16,
                        ),
                      ),
                    ],
                  )
                : Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isIncome
                          ? Icons.arrow_downward_rounded
                          : Icons.arrow_upward_rounded,
                      color: color,
                      size: 22,
                    ),
                  ),
            title: Text(
              transaction.description,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 6),
                Row(
                  children: [
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          transaction.category,
                          style: TextStyle(
                            fontSize: 12,
                            color: color,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.calendar_today,
                      size: 12,
                      color: Colors.grey[500],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('MMM dd, yyyy').format(transaction.date),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            trailing: Text(
              '${isIncome ? '+' : '-'} ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(transaction.amount)}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectionSummaryBar extends StatelessWidget {
  final Map<String, double> totals;

  const _SelectionSummaryBar({required this.totals});

  @override
  Widget build(BuildContext context) {
    final income = totals['income'] ?? 0;
    final expense = totals['expense'] ?? 0;
    final balance = totals['balance'] ?? 0;
    final count = (totals['count'] ?? 0).toInt();
    final currencyFormat =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.calculate_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '$count item${count == 1 ? '' : 's'} selected',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Income / Expense row
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.income.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.arrow_downward_rounded,
                                  color: AppColors.income, size: 16),
                              const SizedBox(width: 4),
                              const Text(
                                'Income',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            currencyFormat.format(income),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.income,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.expense.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.arrow_upward_rounded,
                                  color: AppColors.expense, size: 16),
                              const SizedBox(width: 4),
                              const Text(
                                'Expense',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            currencyFormat.format(expense),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.expense,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Net total row
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: balance >= 0
                        ? [
                            AppColors.income.withOpacity(0.1),
                            AppColors.income.withOpacity(0.05),
                          ]
                        : [
                            AppColors.expense.withOpacity(0.1),
                            AppColors.expense.withOpacity(0.05),
                          ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Net Total',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      currencyFormat.format(balance),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color:
                            balance >= 0 ? AppColors.income : AppColors.expense,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? Colors.white : Colors.grey[700],
          ),
        ),
      ),
    );
  }
}

class _ActiveFilterChip extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onRemove;

  const _ActiveFilterChip({
    required this.label,
    required this.color,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: Icon(
              Icons.close_rounded,
              size: 16,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
