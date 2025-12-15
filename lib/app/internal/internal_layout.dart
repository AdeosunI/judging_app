import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:judging_app/app/app_widget.dart';
import 'package:routefly/routefly.dart';

class InternalLayout extends StatefulWidget {
  const InternalLayout({super.key});

  @override
  State<InternalLayout> createState() => _InternalLayoutState();
}

class _InternalLayoutState extends State<InternalLayout> {
  late final StreamSubscription<User?> _sub;
  bool _isLoading = true;
  bool _didRedirectToLogin = false;
  String _title = 'Home';

  @override
  void initState() {
    super.initState();

    _sub = FirebaseAuth.instance.authStateChanges().listen(
      (user) {
        setState(() {
          _isLoading = true;
        });

        final isLoggedIn = user != null;

        if (!isLoggedIn && !_didRedirectToLogin) {
          _didRedirectToLogin = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Routefly.navigate(routePaths.login);
          });
        }

        if (isLoggedIn) {
          _didRedirectToLogin = false;
        }

        setState(() {
          _isLoading = false;
        });
      },
      onError: (_) {
        setState(() {
          _isLoading = false;
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
      return const ColoredBox(color: Colors.white);
    }

    return Scaffold(
      appBar: AppBar(title: Text(_title)),
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
                        setState(() {
                          _title = 'Home';
                        });
                        Navigator.of(context).pop();
                        Future.microtask(() {
                          Routefly.push(routePaths.internal.home);
                        });
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.event),
                      title: const Text('Overall'),
                      onTap: () {
                        setState(() {
                          _title = 'Overall';
                        });
                        Navigator.of(context).pop();
                        Future.microtask(() {
                          Routefly.push(routePaths.internal.aggregateEvents);
                        });
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.add),
                      title: const Text('Add event'),
                      onTap: () {
                        setState(() {
                          _title = 'Add event';
                        });
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
              InkWell(
                onTap: () {
                  Navigator.of(context).pop();
                  Future.microtask(() {
                    Routefly.push(routePaths.userDetails);
                  });
                },
                child: Padding(
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
                      const Icon(Icons.chevron_right, color: Color(0xFFB0B0B0)),
                    ],
                  ),
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
                      color: Color(0xFF107BFF),
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
      body: SafeArea(child: RouterOutlet()),
    );
  }
}
