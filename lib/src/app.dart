import 'package:flutter/material.dart';
import 'presentation/pages/onboarding_view.dart';
import 'presentation/pages/login_view.dart';
import 'presentation/pages/signup_view.dart';
import 'presentation/pages/forgot_password_view.dart';
import 'features/admin/dashboard/admin_home_view.dart';
import 'features/user/home/user_home_view.dart';
import 'presentation/pages/auth_view.dart'; // Added import for AuthView

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Electric Charging Station',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      // 🚀 Always start with Onboarding first
      initialRoute: '/onboarding',
      routes: {
        '/onboarding': (context) => const OnboardingView(),
        '/login': (context) => const LoginView(),
        '/signup': (context) => const SignupView(),
        '/forgot-password': (context) => const ForgotPasswordView(),
        '/admin-home': (context) => const AdminHomeView(),
        '/user-home': (context) => const UserHomeView(),
        '/auth': (context) => const AuthView(), // Added /auth route
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
