import 'package:expense_tracker/models/category.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/expense.dart';

class NewExpense extends StatefulWidget {
  final Function(String, double, DateTime, ExpenseCategory) onAddExpense;
  final Function(Expense) onUpdateExpense;
  final Expense? expenseToEdit;

  const NewExpense({
    super.key,
    required this.onAddExpense,
    required this.onUpdateExpense,
    this.expenseToEdit,
  });

  @override
  State<NewExpense> createState() => _NewExpenseState();
}

class _NewExpenseState extends State<NewExpense> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  DateTime? _selectedDate;
  ExpenseCategory? _selectedCategory;

  bool get _isEditing => widget.expenseToEdit != null;

  @override
  void initState() {
    super.initState();
    // If we are editing, pre-fill the form fields.
    if (_isEditing) {
      final expense = widget.expenseToEdit!;
      _titleController.text = expense.title;
      _amountController.text = expense.amount.toString();
      _selectedDate = expense.date;
      _selectedCategory = expense.category;
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Invalid Input'),
        content: Text(message),
        actions: [
          TextButton(
            child: const Text('Okay'),
            onPressed: () {
              Navigator.of(ctx).pop();
            },
          ),
        ],
      ),
    );
  }

  void _submitData() {
    final enteredAmount = double.tryParse(_amountController.text);
    final isAmountInvalid = enteredAmount == null || enteredAmount <= 0;
    final isTitleInvalid = _titleController.text.trim().isEmpty;

    if (isTitleInvalid || isAmountInvalid || _selectedDate == null || _selectedCategory == null) {
      _showErrorDialog('Please fill in all fields correctly.');
      return;
    }

    if (_isEditing) {
      // If editing, create an updated expense object and call the update callback.
      final updatedExpense = Expense(
        id: widget.expenseToEdit!.id, // Use the original ID
        title: _titleController.text,
        amount: enteredAmount,
        date: _selectedDate!,
        category: _selectedCategory!,
      );
      widget.onUpdateExpense(updatedExpense);
    } else {
      // If creating, call the add callback as before.
      widget.onAddExpense(
        _titleController.text,
        enteredAmount,
        _selectedDate!,
        _selectedCategory!,
      );
    }
    Navigator.of(context).pop();
  }

  void _presentDatePicker() async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year - 1, now.month, now.day);

    // `await` makes the code cleaner than using .then()
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: firstDate,
      lastDate: now,
    );

    setState(() {
      _selectedDate = pickedDate;
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // This padding ensures the view is pushed up by the keyboard
    final keyboardSpace = MediaQuery.of(context).viewInsets.bottom;

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, keyboardSpace + 16),
        child: Column(
          mainAxisSize: MainAxisSize.min, // Take up minimum vertical space
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add a New Expense',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
              maxLength: 50,
              textInputAction: TextInputAction.next, // Moves to next field
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountController,
              decoration: const InputDecoration(
                prefixText: '\£ ',
                labelText: 'Amount',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textInputAction: TextInputAction.done, // Triggers submit
              onSubmitted: (_) => _submitData(),
            ),
            const SizedBox(height: 20),
            Text('Category', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            SizedBox(
              height: 50,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: availableCategories.map((category) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(category.name),
                      avatar: Icon(category.icon, color: _selectedCategory == category.type ? Colors.white : category.color),
                      selected: _selectedCategory == category.type,
                      onSelected: (isSelected) {
                        setState(() {
                          if (isSelected) {
                            _selectedCategory = category.type;
                          }
                        });
                      },
                      selectedColor: category.color,
                      labelStyle: TextStyle(
                        color: _selectedCategory == category.type ? Colors.white : Colors.black,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),
            // A more intuitive date picker button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_month_outlined, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    _selectedDate == null
                        ? 'Select Date'
                        : DateFormat.yMMMd().format(_selectedDate!),
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.edit_calendar_outlined),
                    onPressed: _presentDatePicker,
                    tooltip: 'Choose Date',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Just close the modal
                  },
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _submitData,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: const Text('Save Expense'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}