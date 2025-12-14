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
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.home),
                      title: const Text('Home'),
                      onTap: () {
                        Navigator.of(context).pop();
                        // Routefly.navigate(routePaths.index);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.event),
                      title: const Text('Events'),
                      onTap: () {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Events page not added yet'),
                          ),
                        );
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.add),
                      title: const Text('Add event'),
                      onTap: () {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Add event page not added yet'),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.person, color: Color(0xFF808080)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Logged in as ${FirebaseAuth.instance.currentUser?.email ?? ''}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF808080),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: TextButton(
                  onPressed: () async {
                    try {
                      await FirebaseAuth.instance.signOut();
                    } catch (e) {
                      if (!context.mounted) return;
                      showDialog(
                        context: context,
                        builder: (_) =>
                            AlertDialog(content: Text('Error signing out: $e')),
                      );
                    }
                  },
                  child: const Text(
                    'Sign out',
                    style: TextStyle(
                      color: Color(0xFF007BFF),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: const Center(child: Text('You are logged in')),
    );
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
