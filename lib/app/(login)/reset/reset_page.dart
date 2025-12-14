import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:judging_app/helpers/handle_auth_error.dart';

class ResetPage extends StatefulWidget {
  const ResetPage({super.key});

  @override
  State<ResetPage> createState() => _ResetPageState();
}

class _ResetPageState extends State<ResetPage> {
  final FirebaseAuth auth = FirebaseAuth.instance;

  String email = '';

  Future<void> attemptReset() async {
    final trimmedEmail = email.trim();

    if (trimmedEmail.isEmpty) {
      showDialog(
        context: context,
        builder: (_) => const AlertDialog(
          title: Text('Error'),
          content: Text('Please enter an email'),
        ),
      );
      return;
    }

    try {
      await auth.sendPasswordResetEmail(email: trimmedEmail);

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => const AlertDialog(
          title: Text('Success'),
          content: Text('The reset link has been sent to your email.'),
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Error'),
          content: Text(authErrorMessage(e.code)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(title: const Text("Reset password")),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                autocorrect: false,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'Email',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(5),
                    borderSide: const BorderSide(color: Color(0xFFCCCCCC)),
                  ),
                ),
                onChanged: (v) => setState(() => email = v),
                onSubmitted: (_) => attemptReset(),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: attemptReset,
                child: const Text(
                  'Send Reset Email',
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
