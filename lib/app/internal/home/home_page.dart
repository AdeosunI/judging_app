import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:routefly/routefly.dart';
import 'package:judging_app/app/app_widget.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  late final StreamSubscription<User?> _sub;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    _sub = FirebaseAuth.instance.authStateChanges().listen(
      (user) {
        final isLoggedIn = user != null;

        if (!isLoggedIn) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Routefly.pushNavigate(routePaths.login);
          });
        }

        setState(() {
          _isLoading = false;
        });
      },
      onError: (_) {
        setState(() {
          _isLoading = true;
        });
      },
    );
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Text("home");
  }
}

class OfflineScreen extends StatelessWidget {
  const OfflineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFF9F9F9),
      body: Center(
        child: Text(
          'You need to connect to the internet.',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF333333),
          ),
        ),
      ),
    );
  }
}
