import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Import Supabase
import 'config/supabase_config.dart'; // Import Supabase config
import 'src/app.dart'; // Import the new MyApp class

Future<void> main() async { // Make main async
  WidgetsFlutterBinding.ensureInitialized(); // Ensure Flutter bindings are initialized

  // DEBUG: Print Supabase config values before initialization
  print('DEBUG main.dart: Supabase URL from config: ${SupabaseConfig.supabaseUrl}');
  print('DEBUG main.dart: Supabase Anon Key from config (first 10 chars): ${SupabaseConfig.supabaseAnonKey.substring(0, 10)}');

  // Initialize Supabase
  try {
    await Supabase.initialize(
      url: SupabaseConfig.supabaseUrl,
      anonKey: SupabaseConfig.supabaseAnonKey,
    );
    print('DEBUG main.dart: Supabase initialized successfully.');
  } catch (e) {
    print('DEBUG main.dart: Supabase initialization FAILED: ${e.toString()}');
    // If initialization fails, you might not want to run the app
    // or handle it in a way that informs the user.
    return; 
  }
  
  runApp(const MyApp()); // Run the MyApp from src/app.dart
}

// Supabase client instance
// This will eventually be better managed, perhaps injected or accessed via a service locator
final supabase = Supabase.instance.client;
