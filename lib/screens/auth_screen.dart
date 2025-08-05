import 'package:appwrite/appwrite.dart';
import 'package:expense_tracker/api/auth_notifier.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isSigningUp = false;
  bool _isLoading = false;

  // REFACTORED: This method now uses the AuthNotifier.
  void _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Get the AuthNotifier instance from the provider.
    // listen: false is important here because we are in a method, not the build method.
    final authNotifier = Provider.of<AuthNotifier>(context, listen: false);

    try {
      if (_isSigningUp) {
        // --- SIGN UP LOGIC ---
        await authNotifier.signUp(
          email: _emailController.text,
          password: _passwordController.text,
        );

        // ADDED: Immediately sign out to destroy the session created by signUp.
        // This ensures the user is returned to the sign-in page.
        await authNotifier.signOut();

        // Show a success message as requested.
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: Colors.green,
              content: Text('You have registered successfully! Please sign in.'),
            ),
          );
        }

        // Switch the UI back to the Sign In page.
        setState(() {
          _isSigningUp = false;
        });

      } else {
        // --- SIGN IN LOGIC ---
        await authNotifier.signIn(
          email: _emailController.text,
          password: _passwordController.text,
        );
        // The AuthGate will now automatically navigate to ExpenseHome.
      }
    } on AppwriteException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text(e.message ?? 'An error occurred'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF96A4D3),
                    shape: BoxShape.circle,
                  ),
                  child: Image.asset(
                    'assets/images/Finora.png',
                    height: 80,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  _isSigningUp ? 'Create an Account' : 'Welcome Back!',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: Color(0xFF152046)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
                  style: TextStyle(color: Color(0xFF152046)),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) => (value?.isEmpty ?? true) ? 'Please enter an email' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder()),
                  style: TextStyle(color: Color(0xFF152046)),
                  obscureText: true,
                  validator: (value) => (value?.length ?? 0) < 8 ? 'Password must be at least 8 characters' : null,
                ),
                const SizedBox(height: 24),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), backgroundColor: Color(0xFF152046), foregroundColor: Colors.white),
                  child: Text(_isSigningUp ? 'Sign Up' : 'Sign In'),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isSigningUp = !_isSigningUp;
                    });
                  },
                  child: Text(_isSigningUp ? 'Already have an account? Sign In' : 'Need an account? Sign Up'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
