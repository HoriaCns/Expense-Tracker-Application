import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class NewExpense extends StatefulWidget {
  final Function(String, double, DateTime) onAddExpense;

  NewExpense({required this.onAddExpense});

  @override
  _NewExpenseState createState() => _NewExpenseState();

}

class _NewExpenseState extends State<NewExpense> {
  final titleController = TextEditingController();
  final amountController = TextEditingController();
  DateTime? selectedDate;

  void _submitData() {
    final enteredTitle = titleController.text;
    final enteredAmount = double.tryParse(amountController.text) ?? 0;

    if (enteredTitle.isEmpty || enteredAmount <= 0 || selectedDate == null) {
      return;
    }

    widget.onAddExpense(enteredTitle, enteredAmount, selectedDate!);
    Navigator.of(context).pop();
  }

  void _presentDatePicker() {
    showDatePicker(context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(2022),
        lastDate: DateTime.now()
    ).then((pickedDate) {
      setState(() {
        selectedDate = pickedDate!;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 5,
      child: Padding(
        padding: EdgeInsets.all(10),
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(labelText: 'Title'),
              controller: titleController,
            ),
            TextField(
              decoration: InputDecoration(labelText: 'Amount'),
              controller: amountController,
              keyboardType: TextInputType.number,
            ),
            Row(
              children: [
                Expanded(
                    child: Text(
                      selectedDate == null
                          ? 'No Date Chosen!'
                          : 'Picked Date: ${DateFormat.yMd().format(selectedDate!)}',
                    ),
                ),
                TextButton(
                  onPressed: _presentDatePicker,
                  child: Text('Choose Date'),
                ),
              ],
            ),
            ElevatedButton(
              onPressed: _submitData,
              child: Text('Add Expense'),
            ),
          ],
        ),
      ),
    );
  }
}