import 'package:expense_tracker/api/auth_notifier.dart';
import 'package:expense_tracker/main.dart';
import 'package:expense_tracker/screens/auth_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    // Consumer widget rebuilds whenever the AuthNotifier calls notifyListeners().
    return Consumer<AuthNotifier>(
      builder: (context, authNotifier, child) {
        // Use a switch statement to handle the different authentication states.
        switch (authNotifier.status) {
          case AuthStatus.uninitialized:
          // Show a loading screen while the app checks for a user session.
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          case AuthStatus.authenticated:
          // If the user is authenticated, show the main expense tracker screen.
            return const ExpenseHome();
          case AuthStatus.unauthenticated:
          // If the user is not authenticated, show the login/signup screen.
            return const AuthScreen();
        }
      },
    );
  }
}
