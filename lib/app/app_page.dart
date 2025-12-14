import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:routefly/routefly.dart';

import 'app_widget.dart';

class AppPage extends StatefulWidget {
  const AppPage({super.key});

  @override
  State<AppPage> createState() => _AppPageState();
}

class _AppPageState extends State<AppPage> {
  late final StreamSubscription<User?> _sub;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    _sub = FirebaseAuth.instance.authStateChanges().listen(
      (user) {
        final isLoggedIn = user != null;

        setState(() {
          _isLoading = false;
        });

        if (!isLoggedIn) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Routefly.pushNavigate(routePaths.login);
          });
        }
      },
      onError: (_) {
        setState(() {
          _isLoading = false;
        });

        WidgetsBinding.instance.addPostFrameCallback((_) {
          Routefly.pushNavigate(routePaths.login);
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
      return const Center(child: CircularProgressIndicator());
    }

    return Center(child: Text("You are logged in"));
  }
}
