import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:expense_tracker/models/expense.dart';

class AppwriteClient {
  Client client = Client();
  late final Account account;
  late final Databases databases;

  // --- Appwrite Project Details ---
  final String endpoint = 'https://cloud.appwrite.io/v1';
  final String projectId = '6888d41200119a354530';
  final String databaseId = '6888d9030028080295df';
  final String collectionId = '6888d90a000c303ab5e1'; // For expenses

  AppwriteClient() {
    client
        .setEndpoint(endpoint)
        .setProject(projectId)
        .setSelfSigned(status: true);

    account = Account(client);
    databases = Databases(client);
  }

  // --- Authentication Methods ---

  // CORRECTED: The return type is now Future<models.User?>
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
        ],
      );

      return response.documents.map((doc) {
        return Expense(
          id: doc.$id,
          title: doc.data['title'],
          amount: (doc.data['amount'] as num).toDouble(),
          date: DateTime.parse(doc.data['date']),
        );
      }).toList();
    } on AppwriteException catch (e) {
      print('Error fetching expenses: $e');
      return [];
    }
  }

  Future<void> addExpense(Expense expense, String userId) async {
    await databases.createDocument(
      databaseId: databaseId,
      collectionId: collectionId,
      documentId: ID.unique(),
      data: {
        'title': expense.title,
        'amount': expense.amount,
        'date': expense.date.toIso8601String(),
        'userId': userId,
      },
    );
  }

  Future<void> deleteExpense(String documentId) async {
    await databases.deleteDocument(
      databaseId: databaseId,
      collectionId: collectionId,
      documentId: documentId,
    );
  }
}
