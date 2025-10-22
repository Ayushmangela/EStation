import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Import appRouteObserver from main.dart using package import
import 'package:testing/main.dart';

import 'presentation/pages/onboarding_view.dart';

import 'presentation/pages/forgot_password_view.dart';
import 'features/admin/dashboard/admin_home_view.dart';
import 'features/user/home/user_home_view.dart';
import 'presentation/pages/welcome_page.dart'; // Added for EnzivoWelcomeScreen

class MyApp extends StatelessWidget {
  final Widget initialScreen;

  const MyApp({super.key, required this.initialScreen});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Electric Charging Station',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Plus Jakarta Sans',
        textTheme: GoogleFonts.plusJakartaSansTextTheme(
          Theme.of(context).textTheme,
        ),
        primaryTextTheme: GoogleFonts.plusJakartaSansTextTheme(
          Theme.of(context).primaryTextTheme,
        ),
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.grey[100],
        appBarTheme: AppBarTheme(
          titleTextStyle: GoogleFonts.plusJakartaSans(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black54),
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      // Add appRouteObserver to navigatorObservers
      navigatorObservers: [appRouteObserver],
      home: initialScreen,
      routes: {
        '/onboarding': (context) => const OnboardingView(),
        '/welcome': (context) => const EnzivoWelcomeScreen(), // Added route for WelcomeScreen
        '/forgot-password': (context) => const ForgotPasswordView(),
        '/admin-home': (context) => const AdminHomeView(),
        '/user-home': (context) => const UserHomeView(),
        // '/auth': (context) => const AuthView(), // Removed route
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/onboarding' && settings.arguments != null) {
          final args = settings.arguments as Map<String, dynamic>;
          if (args['animate'] == true) {
            return PageRouteBuilder(
              settings: settings,
              pageBuilder: (context, animation, secondaryAnimation) =>
              const OnboardingView(),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                const begin = Offset(-1.0, 0.0);
                const end = Offset.zero;
                const curve = Curves.easeInOut;
                var tween = Tween(
                  begin: begin,
                  end: end,
                ).chain(CurveTween(curve: curve));
                var offsetAnimation = animation.drive(tween);
                return SlideTransition(
                  position: offsetAnimation,
                  child: child,
                );
              },
              transitionDuration: const Duration(milliseconds: 300),
            );
          }
        }
        return null;
      },
    );
  }
}
