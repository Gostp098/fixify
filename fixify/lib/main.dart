import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';

import 'views/client/home_client.dart';
import 'views/client/client_profile_screen.dart';
import 'views/client/service_request_screen.dart';
import 'views/client/my_bookings_page.dart';          // ← was my_bookings_screen.dart
import 'views/client/booking_detail_screen.dart';
import 'views/pro/home_pro.dart';
import 'views/pro/complete_profile_screen.dart';
import 'views/pro/incoming_jobs_screen.dart';
import 'views/pro/my_jobs_screen.dart';
import 'views/pro/job_detail_screen.dart';

import 'providers/auth_provider.dart' as app;
import 'providers/client_profile_provider.dart';
import 'providers/technician_profile_provider.dart';
import 'providers/service_request_provider.dart';
import 'providers/booking_provider.dart';


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
        ChangeNotifierProvider(create: (_) => app.AuthProvider()),
        ChangeNotifierProvider(create: (_) => ClientProfileProvider()),
        ChangeNotifierProvider(create: (_) => TechnicianProfileProvider()),
        ChangeNotifierProvider(create: (_) => ServiceRequestProvider()),
        ChangeNotifierProvider(create: (_) => BookingProvider()),
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
          '/':                 (context) => const SplashScreen(),
          '/login':            (context) => const LoginScreen(),
          '/register':         (context) => const RegisterScreen(),
          '/home_client':      (context) => const HomeClient(),
          '/home_pro':         (context) => const HomePro(),
          '/client_profile':   (context) => const ClientProfileScreen(),
          '/complete_profile': (context) => const CompleteProfileScreen(),
          '/service_request':  (context) => const ServiceRequestScreen(),
          '/my_bookings':      (context) => const MyBookingsPage(),  // ← was MyBookingsScreen
          '/incoming_jobs':    (context) => const IncomingJobsScreen(),
          '/my_jobs':          (context) => const MyJobsScreen(),
        },
      ),
    );
  }
}