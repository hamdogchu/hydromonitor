import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'wave_log_screen.dart';
import 'package:hydromonitor/widgets/offline_warning.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Timer? _timer;
  int _secondsUntilNextWave = 0;
  DateTime? _targetTime; // The exact time the next wave should start

  final _wavesStream = Supabase.instance.client
      .from('waves')
      .stream(primaryKey: ['id'])
      .order('started_at', ascending: false)
      .limit(1);

  @override
  void initState() {
    super.initState();
    // This timer no longer just counts down. It checks the actual clock every second.
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_targetTime != null) {
        setState(() {
          _secondsUntilNextWave = _targetTime!.difference(DateTime.now()).inSeconds;
          if (_secondsUntilNextWave < 0) _secondsUntilNextWave = 0; // Prevent negative numbers
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _smoothNavigate(Widget screen) {
    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (context, a1, a2) => screen,
        transitionsBuilder: (context, a1, a2, child) {
          return FadeTransition(
            opacity: Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: a1, curve: Curves.easeOut)),
            child: child,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1117),
        title: const Text('Farm Guard Lite', style: TextStyle(color: Colors.white)),
        elevation: 0,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _wavesStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            // Rebuilds the stream to attempt a new connection
            return OfflineWarningWidget(
              onRetry: () => setState(() {}),
            );
          }

          bool isMonitoring = false;
          if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            final latestWave = snapshot.data!.first;
            isMonitoring = latestWave['status'] == 'monitoring';
            
            // Calculate the exact target time based on database reality
            if (isMonitoring) {
              _targetTime = null; 
            } else if (latestWave['completed_at'] != null) {
              // Convert the database UTC time to the phone's local timezone
              DateTime completedAt = DateTime.parse(latestWave['completed_at']).toLocal();
              _targetTime = completedAt.add(const Duration(minutes: 30));
            }
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: InkWell(
              onTap: () => _smoothNavigate(const WaveLogScreen()),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF161B22),
                  border: Border.all(color: const Color(0xFF21262D)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Tray 1', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          isMonitoring ? Icons.camera_alt : Icons.timer,
                          color: isMonitoring ? const Color(0xFF58A6FF) : const Color(0xFF8B949E),
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isMonitoring 
                            ? 'Scanning 14 plants...' 
                            : 'Next wave in: ${_secondsUntilNextWave ~/ 60}:${(_secondsUntilNextWave % 60).toString().padLeft(2, '0')}',
                          style: TextStyle(color: isMonitoring ? const Color(0xFF58A6FF) : const Color(0xFF8B949E)),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}