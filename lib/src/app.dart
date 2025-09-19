import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // Added for Google Fonts
import 'presentation/pages/onboarding_view.dart';
import 'presentation/pages/login_view.dart';
import 'presentation/pages/signup_view.dart';
import 'presentation/pages/forgot_password_view.dart';
import 'features/admin/dashboard/admin_home_view.dart';
import 'features/user/home/user_home_view.dart';
import 'presentation/pages/auth_view.dart'; 

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Electric Charging Station',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Set "Plus Jakarta Sans" as the default font family
        fontFamily: 'Plus Jakarta Sans',
        
        // Apply "Plus Jakarta Sans" to the text themes for better integration
        textTheme: GoogleFonts.plusJakartaSansTextTheme(
          Theme.of(context).textTheme,
        ),
        primaryTextTheme: GoogleFonts.plusJakartaSansTextTheme(
          Theme.of(context).primaryTextTheme,
        ),
        
        primarySwatch: Colors.blue, // Keep your existing primary swatch or change as needed
        scaffoldBackgroundColor: Colors.grey[100], // Example global scaffold background
        
        appBarTheme: AppBarTheme(
          // Ensure AppBar uses the global font, or define it explicitly
          titleTextStyle: GoogleFonts.plusJakartaSans(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          backgroundColor: Colors.white, // Or Colors.transparent if you prefer
          foregroundColor: Colors.black,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black54), // Consistent icon color for AppBars
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: '/onboarding',
      routes: {
        '/onboarding': (context) => const OnboardingView(),
        '/login': (context) => const LoginView(),
        '/signup': (context) => const SignupView(),
        '/forgot-password': (context) => const ForgotPasswordView(),
        '/admin-home': (context) => const AdminHomeView(),
        '/user-home': (context) => const UserHomeView(),
        '/auth': (context) => const AuthView(),
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
