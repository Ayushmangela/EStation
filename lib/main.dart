import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/supabase_config.dart';
import 'src/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

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

  // DEBUG: Print Supabase config values
  print('DEBUG main.dart: Supabase URL from config: ${SupabaseConfig.supabaseUrl}');
  print('DEBUG main.dart: Supabase Anon Key (first 10 chars): ${SupabaseConfig.supabaseAnonKey.substring(0, 10)}');

  // Initialize Supabase
  try {
    await Supabase.initialize(
      url: SupabaseConfig.supabaseUrl,
      anonKey: SupabaseConfig.supabaseAnonKey,
    );
    print('DEBUG main.dart: Supabase initialized successfully.');
  } catch (e) {
    print('DEBUG main.dart: Supabase initialization FAILED: ${e.toString()}');
    return;
  }

  // 🚀 Always launch with Onboarding first
  runApp(const MyApp());
}

// Supabase client instance
final supabase = Supabase.instance.client;
