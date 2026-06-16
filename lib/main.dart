import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Import your dashboard screen from the screens folder
import 'screens/dashboard_screen.dart';

// Initialize the global notification plugin
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

void main() async {
  // 1. This MUST be the first line when using async setup in main()
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // 2. Initialize Supabase
    // Make sure your URL starts with https://
    await Supabase.initialize(
      url: 'https://eiqtrqnioobwslzntkdo.supabase.co', 
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVpcXRycW5pb29id3Nsem50a2RvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODA4OTk1NDMsImV4cCI6MjA5NjQ3NTU0M30.cUNW3nWp3D6iO2IjLsq1-8zLNz4_3i1bgEe8dy6Dyag',
    );

    // 3. Initialize Local Notifications for Android
    // This tells the app to use your default app icon for the notification
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
        
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );
    
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  } catch (e) {
    // If anything fails (like a bad Supabase URL), it will print here 
    // instead of crashing the app on the splash screen.
    print('FATAL INITIALIZATION ERROR: $e');
  }

  // 4. Launch the App
  runApp(const HydroMonitorApp());
}

class HydroMonitorApp extends StatelessWidget {
  const HydroMonitorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HydroMonitor',
      debugShowCheckedModeBanner: false,
      // Global Theme matching your dark HTML design
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFF0D1117), 
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0D1117),
          elevation: 0,
          iconTheme: IconThemeData(color: Color(0xFF8B949E)),
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Color(0xFFE6EDF3), fontFamily: 'Inter'),
        ),
      ),
      // Set the first screen the user sees
      home: const DashboardScreen(),
    );
  }
}