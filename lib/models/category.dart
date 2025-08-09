import 'package:flutter/material.dart';

// An enum to represent the different expense categories in a type-safe way.
enum ExpenseCategory {
  food,
  transport,
  bills,
  entertainment,
  shopping,
  health,
  other,
}

// A helper class to manage the properties of each category.
class Category {
  final ExpenseCategory type;
  final String name;
  final IconData icon;
  final Color color;

  const Category({
    required this.type,
    required this.name,
    required this.icon,
    required this.color,
  });
}

// A centralized list of all available categories.
// This makes it easy to add or modify categories in the future.
const List<Category> availableCategories = [
  Category(
    type: ExpenseCategory.food,
    name: 'Food',
    icon: Icons.lunch_dining,
    color: Colors.orange,
  ),
  Category(
    type: ExpenseCategory.transport,
    name: 'Transport',
    icon: Icons.directions_car,
    color: Colors.blue,
  ),
  Category(
    type: ExpenseCategory.bills,
    name: 'Bills',
    icon: Icons.receipt_long,
    color: Colors.red,
  ),
  Category(
    type: ExpenseCategory.entertainment,
    name: 'Entertainment',
    icon: Icons.movie,
    color: Colors.purple,
  ),
  Category(
    type: ExpenseCategory.shopping,
    name: 'Shopping',
    icon: Icons.shopping_bag,
    color: Colors.yellow,
  ),
  Category(
    type: ExpenseCategory.health,
    name: 'Health',
    icon: Icons.medical_services,
    color: Colors.pink,
  ),
  Category(
    type: ExpenseCategory.other,
    name: 'Other',
    icon: Icons.more_horiz,
    color: Colors.blueGrey,
  ),
];
