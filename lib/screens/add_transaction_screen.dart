import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/book.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../services/local_database_service.dart';
import 'package:intl/intl.dart';

class AddTransactionScreen extends ConsumerStatefulWidget {
  final Book book;
  final Transaction? transactionToEdit;

  const AddTransactionScreen({
    super.key,
    required this.book,
    this.transactionToEdit,
  });

  @override
  ConsumerState<AddTransactionScreen> createState() =>
      _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _isLoading = false;
  TransactionType _type = TransactionType.expense;
  DateTime _selectedDate = DateTime.now();
  Category? _selectedCategory;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.transactionToEdit != null) {
      _amountController.text = widget.transactionToEdit!.amount.toString();
      _descriptionController.text = widget.transactionToEdit!.description;
      _type = widget.transactionToEdit!.type;
      _selectedDate = widget.transactionToEdit!.date;

      // Find matching category
      _selectedCategory = Category.defaultCategories.firstWhere(
        (cat) => cat.id == widget.transactionToEdit!.category,
        orElse: () => Category.defaultCategories.first,
      );
    } else {
      // Set default category based on type
      _selectedCategory =
          Category.defaultCategories.where((cat) => cat.type == _type).first;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  List<Category> get _filteredCategories {
    return Category.defaultCategories
        .where((cat) => cat.type == _type)
        .toList();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Color(int.parse('FF${widget.book.color}', radix: 16)),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCategory == null) {
      setState(() {
        _errorMessage = 'Please select a category';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final amount = double.parse(_amountController.text);
      final dbService = LocalDatabaseService.instance;

      if (widget.transactionToEdit == null) {
        // Create new transaction
        await dbService.createTransaction(
          bookId: widget.book.id,
          userId: widget.book.userId,
          date: _selectedDate,
          category: _selectedCategory!.id,
          description: _descriptionController.text.trim(),
          amount: amount,
          type: _type,
        );
      } else {
        // Update existing transaction
        await dbService.updateTransaction(
          widget.transactionToEdit!.copyWith(
            date: _selectedDate,
            category: _selectedCategory!.id,
            description: _descriptionController.text.trim(),
            amount: amount,
            type: _type,
          ),
        );
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: Text(
          widget.transactionToEdit == null
              ? 'Add Transaction'
              : 'Edit Transaction',
          style:
              const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(int.parse('FF${widget.book.color}', radix: 16)),
                Color(int.parse('FF${widget.book.color}', radix: 16))
                    .withOpacity(0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Error Message
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.shade100.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.redAccent.shade100),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          color: Colors.redAccent, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                              color: Colors.redAccent, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),

              // Type Selection (Income/Expense)
              Row(
                children: [
                  Expanded(
                    child: _TypeButton(
                      label: 'Expense',
                      icon: Icons.arrow_upward_rounded,
                      color: const Color(0xFFFF6B9D),
                      isSelected: _type == TransactionType.expense,
                      onTap: () {
                        setState(() {
                          _type = TransactionType.expense;
                          _selectedCategory = _filteredCategories.first;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _TypeButton(
                      label: 'Income',
                      icon: Icons.arrow_downward_rounded,
                      color: const Color(0xFF00D9A6),
                      isSelected: _type == TransactionType.income,
                      onTap: () {
                        setState(() {
                          _type = TransactionType.income;
                          _selectedCategory = _filteredCategories.first;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Amount
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: TextFormField(
                  controller: _amountController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'^\d+\.?\d{0,2}')),
                  ],
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                  ),
                  decoration: InputDecoration(
                    labelText: 'Amount',
                    labelStyle: const TextStyle(color: Color(0xFF6C63FF)),
                    prefixText: 'Rp ',
                    prefixStyle: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6C63FF),
                    ),
                    border: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(20)),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an amount';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    if (double.parse(value) <= 0) {
                      return 'Amount must be greater than 0';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Category Selection
              Text(
                'Category',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _filteredCategories.map((category) {
                  final isSelected = _selectedCategory?.id == category.id;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = category),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Color(int.parse('FF${category.color}', radix: 16))
                            : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? Color(
                                  int.parse('FF${category.color}', radix: 16))
                              : Colors.grey.shade300,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(category.icon,
                              style: const TextStyle(fontSize: 20)),
                          const SizedBox(width: 8),
                          Text(
                            category.name,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? Colors.white
                                  : const Color(0xFF2C3E50),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Description
              TextFormField(
                controller: _descriptionController,
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: 'Description',
                  hintText: 'What was this for?',
                  prefixIcon: const Icon(Icons.notes),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.white,
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Date Selection
              InkWell(
                onTap: () => _selectDate(context),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today,
                          color: Color(0xFF5F27CD)),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Date',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF7F8C8D),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('MMMM dd, yyyy').format(_selectedDate),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      const Icon(Icons.chevron_right, color: Color(0xFF7F8C8D)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Save Button
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [
                      Color(int.parse('FF${widget.book.color}', radix: 16)),
                      Color(int.parse('FF${widget.book.color}', radix: 16))
                          .withOpacity(0.8),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color:
                          Color(int.parse('FF${widget.book.color}', radix: 16))
                              .withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSave,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          widget.transactionToEdit == null
                              ? 'Add Transaction'
                              : 'Save Changes',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _TypeButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [color, color.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.transparent : color.withOpacity(0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? color.withOpacity(0.3)
                  : Colors.black.withOpacity(0.05),
              blurRadius: isSelected ? 12 : 8,
              offset: Offset(0, isSelected ? 6 : 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : color,
              size: 24,
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : const Color(0xFF2C3E50),
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
