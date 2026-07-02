import 'package:flutter/material.dart';

import 'screens/dashboard_screen.dart';
import 'screens/login_screen.dart';
import 'screens/welcome_screen.dart';
import 'screens/biometric_screen.dart';
import 'screens/more_screen.dart';
import 'screens/contact_us_screen.dart';
import 'screens/about_app_screen.dart';
import 'screens/lets_chat_screen.dart';
import 'screens/terms_condition_screen.dart';
import 'screens/version_screen.dart';
import 'screens/security_features_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const LookForApp());
}

class LookForApp extends StatelessWidget {
  const LookForApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF005BAB),
      primary: const Color(0xFF005BAB),
      secondary: const Color(0xFFFFCC00),
      surface: Colors.white,
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'LookFor',
      theme: ThemeData(
        colorScheme: colorScheme,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF6F8FB),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF005BAB),
          elevation: 0,
          scrolledUnderElevation: 1,
          centerTitle: true,
          surfaceTintColor: Colors.white,
        ),
        drawerTheme: const DrawerThemeData(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.horizontal(right: Radius.circular(18)),
          ),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFFCC00),
            foregroundColor: const Color(0xFF111827),
            elevation: 0,
            minimumSize: const Size(48, 44),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF005BAB),
            minimumSize: const Size(48, 44),
            side: const BorderSide(color: Color(0xFFB7C7DA)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFD6DEE8)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFD6DEE8)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF005BAB), width: 1.4),
          ),
        ),
      ),
      //initialRoute: '/login',
      initialRoute: '/',
      
routes: {
  '/': (context) => const WelcomeScreen(),
  '/login': (context) => const LoginScreen(),
  '/dashboard': (context) => const DashboardScreen(),
  '/biometric': (context) => const BiometricScreen(), 
  '/more': (context) => const MoreScreen(),
  '/contact': (context) => const ContactUsScreen(),
  '/about': (context) => const AboutAppScreen(),
  '/lets-chat': (context) => const LetsChatScreen(),
  '/terms': (context) => const TermsConditionScreen(),
  '/version': (context) => const VersionScreen(),
  '/security': (context) => const SecurityFeaturesScreen(),
},

        //'/login': (context) => const LoginScreen(),
        //'/dashboard': (context) => const DashboardScreen(),

        
     
    );
  }
}
