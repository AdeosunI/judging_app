import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:routefly/routefly.dart';
import 'package:judging_app/helpers/handle_auth_error.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final FirebaseAuth auth = FirebaseAuth.instance;

  String email = '';
  String password = '';

  Future<void> handleLogin() async {
    final trimmedEmail = email.trim();

    if (trimmedEmail.isEmpty || password.isEmpty) {
      _showError('Please enter both an email and password.');
      return;
    }

    try {
      await auth.signInWithEmailAndPassword(
        email: trimmedEmail,
        password: password,
      );

      if (!mounted) return;
      Routefly.replace('/app');
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      _handleAuthError(e.code);
    }
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(content: Text(message)),
    );
  }

  void _handleAuthError(String code) {
    _showError(authErrorMessage(code));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Login',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              TextField(
                autocorrect: false,
                keyboardType: TextInputType.emailAddress,
                decoration: _inputDecoration('Email'),
                onChanged: (v) => setState(() => email = v),
              ),
              const SizedBox(height: 20),
              TextField(
                obscureText: true,
                decoration: _inputDecoration('Password'),
                onChanged: (v) => setState(() => password = v),
                onSubmitted: (_) => handleLogin(),
              ),
              const SizedBox(height: 10),
              TextButton(onPressed: handleLogin, child: _buttonText('Log In')),
              TextButton(
                onPressed: () => Routefly.push('/reset'),
                child: _buttonText('Forgot your password? Reset it'),
              ),
              TextButton(
                onPressed: () => Routefly.push('/signup'),
                child: _buttonText("Don't have an account? Sign Up"),
              ),
            ],
          ),
        ),
      ),
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

  static Widget _buttonText(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF007BFF),
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
      textAlign: TextAlign.center,
    );
  }
}
