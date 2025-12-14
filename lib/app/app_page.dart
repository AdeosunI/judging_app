import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:routefly/routefly.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

import 'app_widget.dart';

class AppPage extends StatefulWidget {
  const AppPage({super.key});

  @override
  State<AppPage> createState() => _AppPageState();
}

class _AppPageState extends State<AppPage> {
  late final StreamSubscription<User?> _sub;
  bool _isLoading = true;
  bool? isConnected;
  StreamSubscription<InternetStatus>? _connectedSub;

  @override
  void initState() {
    super.initState();

    _connectedSub = InternetConnection().onStatusChange.listen((status) {
      setState(() {
        isConnected = status == InternetStatus.connected;
      });
    });

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
    _connectedSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isConnected != true) {
      return const OfflineScreen();
    }

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Center(child: Text("You are logged in"));
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
