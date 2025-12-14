import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:routefly/routefly.dart';
import 'package:judging_app/helpers/handle_auth_error.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final FirebaseAuth auth = FirebaseAuth.instance;

  String email = '';
  String password = '';
  String confirmPassword = '';
  String displayName = '';

  Future<void> handleSignUp() async {
    final trimmedEmail = email.trim();
    final trimmedDisplayName = displayName.trim();

    if (trimmedEmail.isEmpty) {
      _showDialog('Error', 'Enter an email');
      return;
    } else if (password.isEmpty) {
      _showDialog('Error', 'Enter a password');
      return;
    } else if (confirmPassword.isEmpty) {
      _showDialog('Error', 'Confirm your password');
      return;
    } else if (trimmedDisplayName.isEmpty) {
      _showDialog('Error', 'Enter a display name');
      return;
    } else if (password != confirmPassword) {
      _showDialog('Error', 'Passwords do not match');
      return;
    }

    try {
      final credential = await auth.createUserWithEmailAndPassword(
        email: trimmedEmail,
        password: password,
      );

      await credential.user?.updateDisplayName(trimmedDisplayName);

      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (_) =>
            const AlertDialog(content: Text('User registered successfully!')),
      );

      if (!mounted) return;
      Routefly.pop(context);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      _showDialog('Error', authErrorMessage(e.code));
    }
  }

  void _showDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(title: Text(title), content: Text(message)),
    );
  }

  static InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(5)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(5),
        borderSide: const BorderSide(color: Color(0xFFCCCCCC)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(title: const Text('Signup')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                autocorrect: false,
                keyboardType: TextInputType.emailAddress,
                decoration: _inputDecoration('Email'),
                onChanged: (v) => setState(() => email = v),
              ),
              const SizedBox(height: 20),
              TextField(
                autocorrect: false,
                decoration: _inputDecoration('Display name'),
                onChanged: (v) => setState(() => displayName = v),
              ),
              const SizedBox(height: 20),
              TextField(
                autocorrect: false,
                obscureText: true,
                decoration: _inputDecoration('Password'),
                onChanged: (v) => setState(() => password = v),
              ),
              const SizedBox(height: 20),
              TextField(
                autocorrect: false,
                obscureText: true,
                decoration: _inputDecoration('Confirm Password'),
                onChanged: (v) => setState(() => confirmPassword = v),
                onSubmitted: (_) => handleSignUp(),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: handleSignUp,
                child: const Text(
                  'Sign Up',
                  style: TextStyle(
                    color: Color(0xFF007BFF),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
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
