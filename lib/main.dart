import 'package:flutter/material.dart';

import 'screens/auth_screen.dart';
import 'screens/dashboard_screen.dart';
import 'services/api_client.dart';
import 'theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const DeadlineDashApp());
}

class DeadlineDashApp extends StatefulWidget {
  const DeadlineDashApp({super.key});

  @override
  State<DeadlineDashApp> createState() => _DeadlineDashAppState();
}

class _DeadlineDashAppState extends State<DeadlineDashApp> {
  late final Future<ApiClient> _clientFuture = ApiClient.create();
  ApiClient? _client;
  bool _signedIn = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Deadline Dash',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: canvas,
        colorScheme: ColorScheme.fromSeed(
          seedColor: forest,
          primary: forest,
          secondary: leaf,
          surface: Colors.white,
        ),
        fontFamily: 'Aptos',
        appBarTheme: const AppBarTheme(
          backgroundColor: canvas,
          foregroundColor: ink,
          elevation: 0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF3F5F1),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: forest, width: 1.5),
          ),
        ),
      ),
      home: FutureBuilder<ApiClient>(
        future: _clientFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator(color: forest)),
            );
          }
          _client ??= snapshot.data!;
          _signedIn = _client!.isAuthenticated;
          return _signedIn ? _dashboard() : _auth();
        },
      ),
    );
  }

  Widget _auth() => AuthScreen(
        api: _client!,
        onAuthenticated: () => setState(() => _signedIn = true),
      );

  Widget _dashboard() => DashboardScreen(
        api: _client!,
        onSignOut: () => setState(() => _signedIn = false),
      );
}