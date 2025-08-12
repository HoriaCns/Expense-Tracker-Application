import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:expense_tracker/models/category.dart';
import 'package:expense_tracker/models/expense.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';

import '../models/budget.dart';

class AppwriteClient {
  Client client = Client();
  late final Account account;
  late final Databases databases;

  // --- Appwrite Project Details from .env ---
  final String endpoint = dotenv.env['APPWRITE_ENDPOINT']!;
  final String projectId = dotenv.env['APPWRITE_PROJECT_ID']!;
  final String databaseId = dotenv.env['APPWRITE_DATABASE_ID']!;
  final String collectionId = dotenv.env['APPWRITE_EXPENSE_COLLECTION_ID']!;
  final String budgetCollectionId = dotenv.env['APPWRITE_BUDGETS_COLLECTION_ID']!;

  AppwriteClient() {
    client
        .setEndpoint(endpoint)
        .setProject(projectId)
        .setSelfSigned(status: true);

    account = Account(client);
    databases = Databases(client);
  }

  // --- Authentication Methods ---

  Future<models.User?> getCurrentUser() async {
    try {
      return await account.get();
    } on AppwriteException {
      return null;
    }
  }

  Future<models.Session> signIn({required String email, required String password}) {
    return account.createEmailPasswordSession(email: email, password: password);
  }

  Future<models.User> signUp({required String email, required String password}) {
    return account.create(userId: ID.unique(), email: email, password: password);
  }

  Future<void> signOut() async {
    await account.deleteSession(sessionId: 'current');
  }

  // --- Database Methods ---
  Future<List<Expense>> getExpenses(String userId) async {
    try {
      final response = await databases.listDocuments(
        databaseId: databaseId,
        collectionId: collectionId,
        queries: [
          Query.equal('userId', userId),
          Query.orderDesc('\$createdAt'), // Get newest first
        ],
      );

      return response.documents.map((doc) {
        final categoryString = doc.data['category'] as String? ?? 'other';
        final category = ExpenseCategory.values.firstWhere(
              (e) => e.name == categoryString,
          orElse: () => ExpenseCategory.other,
        );

        return Expense(
          id: doc.$id,
          title: doc.data['title'],
          amount: (doc.data['amount'] as num).toDouble(),
          date: DateTime.parse(doc.data['date']),
          category: category,
        );
      }).toList();
    } on AppwriteException catch (e) {
      print('Error fetching expenses: $e');
      // Re-throw a user-friendly exception
      throw Exception('Failed to fetch expenses from the server.');
    }
  }

  Future<void> addExpense(Expense expense, String userId) async {
    try {
      await databases.createDocument(
        databaseId: databaseId,
        collectionId: collectionId,
        documentId: ID.unique(),
        data: {
          'title': expense.title,
          'amount': expense.amount,
          'date': expense.date.toIso8601String(),
          'userId': userId,
          'category': expense.category.name,
        },
      );
    } on AppwriteException catch (e) {
      print('Error adding expense: $e');
      throw Exception('Failed to save expense.');
    }
  }

  Future<void> updateExpense(Expense expense) async {
    try {
      await databases.updateDocument(
        databaseId: databaseId,
        collectionId: collectionId,
        documentId: expense.id,
        data: {
          'title': expense.title,
          'amount': expense.amount,
          'date': expense.date.toIso8601String(),
          'category': expense.category.name,
        },
      );
    } on AppwriteException catch (e) {
      print('Error updating expense: $e');
      throw Exception('Failed to update expense.');
    }
  }

  Future<void> deleteExpense(String documentId) async {
    try {
      await databases.deleteDocument(
        databaseId: databaseId,
        collectionId: collectionId,
        documentId: documentId,
      );
    } on AppwriteException catch (e) {
      print('Error deleting expense: $e');
      throw Exception('Failed to delete expense.');
    }
  }

  Future<Budget> getBudgetForCurrentMonth(String userId) async {
    final monthString = DateFormat('yyyy-MM').format(DateTime.now());
    final response = await databases.listDocuments(
      databaseId: databaseId,
      collectionId: budgetCollectionId,
      queries: [
        Query.equal('userId', userId),
        Query.equal('month', monthString),
        Query.limit(1),
      ],
    );

    if (response.documents.isEmpty) {
      throw Exception('document_not_found');
    }

    final doc = response.documents.first;
    return Budget(
      id: doc.$id,
      userId: doc.data['userId'],
      amount: (doc.data['amount'] as num).toDouble(),
      month: doc.data['month'],
    );
  }

  Future<void> createBudget(String userId, double amount) async {
    final monthString = DateFormat('yyyy-MM').format(DateTime.now());
    await databases.createDocument(
      databaseId: databaseId,
      collectionId: budgetCollectionId,
      documentId: ID.unique(),
      data: {
        'userId': userId,
        'amount': amount,
        'month': monthString,
      },
    );
  }

  Future<void> updateBudget(String documentId, double amount) async {
    await databases.updateDocument(
      databaseId: databaseId,
      collectionId: budgetCollectionId,
      documentId: documentId,
      data: {'amount': amount},
    );
  }
}