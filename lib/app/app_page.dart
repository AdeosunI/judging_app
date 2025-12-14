import 'dart:async';

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
  bool? isNotConnected;
  StreamSubscription<InternetStatus>? _connectedSub;

  @override
  void initState() {
    super.initState();

    _connectedSub = InternetConnection().onStatusChange.listen((status) {
      bool isConnected = status == InternetStatus.connected;
      setState(() {
        isNotConnected = !isConnected;
      });

      if (isConnected) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Routefly.pushNavigate(routePaths.internal.home);
        });
      }
    });
  }

  @override
  void dispose() {
    _connectedSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isNotConnected == true) {
      return const OfflineScreen();
    }

    return Container(color: Colors.white);
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
