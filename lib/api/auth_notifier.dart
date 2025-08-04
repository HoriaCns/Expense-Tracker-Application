import 'package:flutter/material.dart';
import 'package:appwrite/models.dart' as models;
import 'package:expense_tracker/api/appwrite_client.dart';

// Enum to represent the different states of authentication.
enum AuthStatus {
  uninitialized,
  authenticated,
  unauthenticated,
}

class AuthNotifier extends ChangeNotifier {
  final AppwriteClient _appwriteClient = AppwriteClient();

  AuthStatus _status = AuthStatus.uninitialized;
  models.User? _currentUser;

  // Public getters to access the private state variables.
  AuthStatus get status => _status;
  models.User? get currentUser => _currentUser;

  // Constructor runs when the notifier is created.
  AuthNotifier() {
    checkCurrentUser();
  }

  /// Checks for an existing user session on app start.
  Future<void> checkCurrentUser() async {
    try {
      _currentUser = await _appwriteClient.getCurrentUser();
      _status = AuthStatus.authenticated;
    } catch (e) {
      _status = AuthStatus.unauthenticated;
    }
    // Notify all listeners that the state has changed.
    notifyListeners();
  }

  /// Signs the user in and updates the state.
  Future<void> signIn({required String email, required String password}) async {
    await _appwriteClient.signIn(email: email, password: password);
    // Re-check user status after a successful sign-in.
    await checkCurrentUser();
  }

  /// Signs a new user up but does NOT log them in.
  Future<void> signUp({required String email, required String password}) async {
    await _appwriteClient.signUp(email: email, password: password);
  }

  /// Signs the user out and updates the state.
  Future<void> signOut() async {
    try {
      await _appwriteClient.signOut();
    } catch (e) {
      // Log the error for debugging, but don't stop the function.
      // We want to update the UI state regardless of a server error.
      print("Error during sign out: $e");
    } finally {
      // This 'finally' block will ALWAYS run, even if an error occurs above.
      // This ensures the app's state is correctly reset.
      _status = AuthStatus.unauthenticated;
      _currentUser = null;
      notifyListeners();
    }
  }
}
