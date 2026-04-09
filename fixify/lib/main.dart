// ============================================================
// lib/main.dart — register providers, add route
// ============================================================

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'views/client/home_client.dart';
import 'views/client/client_profile_screen.dart';
import 'views/pro/home_pro.dart';
import 'views/pro/complete_profile_screen.dart';
import 'providers/client_profile_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const FixifyApp());
}

class FixifyApp extends StatelessWidget {
  const FixifyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Register all providers here as the app grows
        ChangeNotifierProvider(create: (_) => ClientProfileProvider()),
      ],
      child: MaterialApp(
        title: 'Fixify',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primaryColor: const Color(0xFF2E5BFF),
          fontFamily: 'Roboto',
          scaffoldBackgroundColor: Colors.grey.shade50,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            elevation: 0,
            iconTheme: IconThemeData(color: Color(0xFF2E5BFF)),
            titleTextStyle: TextStyle(
              color: Color(0xFF2E5BFF),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => const SplashScreen(),
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/home_client': (context) => const HomeClient(),
          '/home_pro': (context) => const HomePro(),
          '/client_profile': (context) => const ClientProfileScreen(),
          '/complete_profile': (context) => const CompleteProfileScreen(),
        },
      ),
    );
  }
}