import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/detail_screen.dart'; // <--- ADD THIS LINE

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Supabase.initialize(
      url: 'https://YOUR_ACTUAL_PROJECT_ID.supabase.co', // MUST include https://
      anonKey: 'YOUR_ACTUAL_ANON_KEY',
    );
  } catch (e) {
    print('Supabase Initialization Error: $e');
  }

  runApp(const HydroMonitorApp());
}

class HydroMonitorApp extends StatelessWidget {
  const HydroMonitorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HydroMonitor',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFF0D1117), // Dark theme from HTML
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Color(0xFFE6EDF3), fontFamily: 'Inter'),
        ),
      ),
      home: const DashboardScreen(),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Listen to real-time changes in the Supabase 'scans' table
/*
  final _scanStream = Supabase.instance.client
      .from('scans')
      .stream(primaryKey: ['id'])
      .order('created_at', ascending: false)
      .limit(4); // Get the latest scan for the 4 trays
*/
  final Stream<List<Map<String, dynamic>>> _mockScanStream = Stream.value([
    {
      'id': 1,
      'tray_id': 'TRAY-001',
      'disease_detected': true,
      'pest_detected': false,
    },
    {
      'id': 2,
      'tray_id': 'TRAY-002',
      'disease_detected': false,
      'pest_detected': true,
    },
    {
      'id': 3,
      'tray_id': 'TRAY-003',
      'disease_detected': false,
      'pest_detected': false,
    },
    {
      'id': 4,
      'tray_id': 'TRAY-004',
      'disease_detected': true,
      'pest_detected': true,
    },
  ]);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1117),
        title: const Text('HydroMonitor', style: TextStyle(color: Colors.white)),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: const Color(0xFF21262D), height: 1.0),
        ),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _mockScanStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Waiting for initial captures..."));
          }

          final scans = snapshot.data!;

          return Padding(
            padding: const EdgeInsets.all(12.0),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 0.85,
              ),
              itemCount: scans.length,
              itemBuilder: (context, index) {
                final scan = scans[index];
                return TrayCard(scan: scan);
              },
            ),
          );
        },
      ),
    );
  }
}

// Modular Widget for the Tray Card
// Modular Widget for the Tray Card
class TrayCard extends StatelessWidget {
  final Map<String, dynamic> scan;

  const TrayCard({super.key, required this.scan});

  @override
  Widget build(BuildContext context) {
    // 1. Safely handle potential null values from the database
    bool diseaseDetected = scan['disease_detected'] ?? false;
    bool pestDetected = scan['pest_detected'] ?? false;
    bool hasAlert = diseaseDetected || pestDetected;
    
    // If tray_id or disease_name is null in the DB, provide a fallback string
    String trayId = scan['tray_id']?.toString() ?? 'Unknown Tray';
    String diseaseName = scan['disease_name']?.toString() ?? 'Unknown Disease';

    // 2. Wrap in an InkWell to make it clickable
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          PageRouteBuilder(
            // Controls the speed of the transition
            transitionDuration: const Duration(milliseconds: 400),
            reverseTransitionDuration: const Duration(milliseconds: 300),
            pageBuilder: (context, animation, secondaryAnimation) => DetailScreen(scan: scan),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              // 1. Subtle slide up from slightly below the screen
              const begin = Offset(0.0, 0.05); 
              const end = Offset.zero;
              const curve = Curves.easeOutCubic; // Smooth deceleration

              var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
              var offsetAnimation = animation.drive(tween);

              // 2. Smooth fade in
              var fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOut),
              );

              // 3. Combine both animations
              return FadeTransition(
                opacity: fadeAnimation,
                child: SlideTransition(
                  position: offsetAnimation,
                  child: child,
                ),
              );
            },
          ),
        );
      },
      borderRadius: BorderRadius.circular(10), // Keeps the ripple effect inside the borders
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF161B22),
          border: Border.all(color: const Color(0xFF21262D), width: 1),
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  trayId, // Safely using the fallback variable
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6E7681),
                  ),
                ),
                // Alert Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: hasAlert ? const Color(0xFF2D1117) : const Color(0xFF0D2015),
                    border: Border.all(
                      color: hasAlert ? const Color(0xFF6E1C1C) : const Color(0xFF1A5C2A),
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    hasAlert ? 'Alert' : 'Clear',
                    style: TextStyle(
                      fontSize: 9,
                      color: hasAlert ? const Color(0xFFF85149) : const Color(0xFF3FB950),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              "Hydroponic Tray",
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const Divider(color: Color(0xFF21262D)),
            // Disease Status
            Row(
              children: [
                Container(
                  width: 6, height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: diseaseDetected ? const Color(0xFFD29922) : const Color(0xFF238636),
                  ),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    diseaseDetected ? diseaseName : 'No disease', // Safely using the fallback variable
                    style: const TextStyle(fontSize: 10, color: Color(0xFFC9D1D9)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}