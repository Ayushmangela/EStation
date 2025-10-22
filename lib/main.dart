import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'config/supabase_config.dart';
import 'src/app.dart';
import 'src/features/user/home/user_home_view.dart';
import 'src/features/admin/home/admin_home_view.dart';
import 'src/presentation/pages/onboarding_view.dart';
import 'src/presentation/pages/welcome_page.dart';
import 'src/presentation/pages/splash_view.dart';

// Define appRouteObserver as a top-level final variable
final RouteObserver<ModalRoute<void>> appRouteObserver = RouteObserver<ModalRoute<void>>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Hide system navigation bar on app start, but allow swipe up to reveal
  await SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.immersiveSticky,
  );

  // Set status bar icons to light for visibility
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colors.black,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  // Initialize Supabase
  try {
    await Supabase.initialize(
      url: SupabaseConfig.supabaseUrl,
      anonKey: SupabaseConfig.supabaseAnonKey,
    );
  } catch (e) {
    print('DEBUG main.dart: Supabase initialization FAILED: ${e.toString()}');
    return;
  }

  final prefs = await SharedPreferences.getInstance();
  final bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
  final String? userRole = prefs.getString('userRole');

  Widget initialScreen;
  if (isLoggedIn && userRole != null) {
    if (userRole == 'admin') {
      initialScreen = const SplashView(nextScreen: AdminHomeView());
    } else {
      initialScreen = const SplashView(nextScreen: UserHomeView());
    }
  } else {
    final bool onboardingComplete = prefs.getBool('onboardingComplete') ?? false;
    if (onboardingComplete) {
      initialScreen = const EnzivoWelcomeScreen();
    } else {
      initialScreen = const OnboardingView();
    }
  }

  // 🚀 Launch with determined initial route
  runApp(MyApp(initialScreen: initialScreen));
}

// Supabase client instance
final supabase = Supabase.instance.client;
