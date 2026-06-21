import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:web/web.dart' as web; // <--- CHANGED: Use the modern, Wasm-ready web package
import '../widgets/wifi_dialog.dart';
import 'wave_log_screen.dart';
import 'offline_queue_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Timer? _localApiPoller;
  Timer? _countdownTimer; 
  
  // Local State Variables
  bool _isPaused = false;
  bool _isScanning = false;
  bool _isUploading = false; 
  int _intervalMins = 30;
  bool _isLocalApiOffline = false;

  int _secondsUntilNextWave = 0; 
  DateTime? _targetTime; 

  late Stream<List<Map<String, dynamic>>> _wavesStream;

  @override
  void initState() {
    super.initState();
    
    // Fallback stream from Supabase (handles offline gracefully)
    _wavesStream = Supabase.instance.client
        .from('waves')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .limit(1);

    // 1. Fetch Local Flask API settings every 2 seconds
    _localApiPoller = Timer.periodic(const Duration(seconds: 2), (timer) {
      _fetchLocalSettings();
    });

    // 1.5 Local UI Timer for the countdown
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_targetTime != null) {
        if (mounted) {
          setState(() {
            _secondsUntilNextWave = _targetTime!.difference(DateTime.now()).inSeconds;
            if (_secondsUntilNextWave < 0) _secondsUntilNextWave = 0; 
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _localApiPoller?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  // --- LOCAL API COMMUNICATION ---
  Future<void> _fetchLocalSettings() async {
    try {
      final response = await http.get(Uri.parse('http://127.0.0.1:5000/settings')).timeout(const Duration(seconds: 1));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            _isPaused = data['is_paused'] ?? false;
            _intervalMins = data['interval_minutes'] ?? 30;
            _isScanning = data['is_scanning'] ?? false; 
            _isUploading = data['is_uploading'] ?? false;
            _isLocalApiOffline = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLocalApiOffline = true);
    }
  }

  Future<void> _updateLocalSettings(Map<String, dynamic> updates) async {
    try {
      await http.post(
        Uri.parse('http://127.0.0.1:5000/settings'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(updates),
      );
      _fetchLocalSettings(); // Refresh instantly
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to reach local RPi script.')));
      }
    }
  }

  // --- CHANGED: Native Web Fullscreen Toggle using package:web ---
  void _toggleFullscreen() {
    // Check if the browser is already in fullscreen mode using the modern API
    if (web.document.fullscreenElement != null) {
      web.document.exitFullscreen(); // Native exit
    } else {
      web.document.documentElement?.requestFullscreen(); // Native enter
    }
  }

  // --- DIALOGS & NAVIGATION ---
  void _showIntervalDialog() {
    int selected = _intervalMins;
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: const Color(0xFF161B22),
              title: const Text("Set Scan Interval", style: TextStyle(color: Colors.white)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Slider(
                    value: selected.toDouble(),
                    min: 5,
                    max: 120,
                    divisions: 23,
                    activeColor: const Color(0xFF58A6FF),
                    label: "$selected mins",
                    onChanged: (val) {
                      setStateDialog(() => selected = val.toInt());
                    },
                  ),
                  Text("$selected minutes", style: const TextStyle(color: Color(0xFF8B949E))),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel", style: TextStyle(color: Color(0xFF8B949E))),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF238636)),
                  onPressed: () {
                    _updateLocalSettings({'interval_minutes': selected});
                    Navigator.pop(context);
                  },
                  child: const Text("Save", style: TextStyle(color: Colors.white)),
                )
              ],
            );
          }
        );
      }
    );
  }

  void _smoothNavigate(Widget screen) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => screen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  // --- UI BUILDER ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1117),
        title: const Text('HydroMonitor (Local)', style: TextStyle(color: Colors.white)),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.fullscreen_exit, color: Color(0xFF8B949E)),
            tooltip: 'Exit Fullscreen',
            onPressed: _toggleFullscreen,
          ),
          IconButton(
            icon: const Icon(Icons.wifi, color: Color(0xFF8B949E)),
            tooltip: 'Wi-Fi Settings',
            onPressed: () {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const WifiDialog(),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // MAIN STATUS CARD
              Card(
                color: const Color(0xFF161B22),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: const BorderSide(color: Color(0xFF30363D)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Tray 1', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      
                      // Status & Timer Stream
                      StreamBuilder<List<Map<String, dynamic>>>(
                        stream: _wavesStream,
                        builder: (context, waveSnapshot) {
                          bool isInternetOffline = waveSnapshot.hasError;

                          if (waveSnapshot.hasData && waveSnapshot.data!.isNotEmpty) {
                            final latestWave = waveSnapshot.data!.first;
                            
                            if (_isScanning || _isUploading || _isPaused) {
                              _targetTime = null; 
                            } else if (latestWave['completed_at'] != null) {
                              DateTime completedAt = DateTime.parse(latestWave['completed_at']).toLocal();
                              _targetTime = completedAt.add(Duration(minutes: _intervalMins));
                            }
                          }

                          return Row(
                            children: [
                              Icon(
                                _isLocalApiOffline ? Icons.warning_amber_rounded 
                                    : (_isScanning ? Icons.camera_alt 
                                    : (_isUploading ? Icons.cloud_upload 
                                    : (isInternetOffline ? Icons.wifi_off : Icons.timer))),
                                color: _isLocalApiOffline ? Colors.red : (_isScanning || _isUploading ? const Color(0xFF58A6FF) : const Color(0xFF8B949E)),
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _isLocalApiOffline ? 'Main.py script is not running.' 
                                      : _isScanning ? 'Scanning 14 plants...' 
                                      : _isUploading ? 'Uploading to Cloud...'
                                      : _isPaused ? 'Monitoring Suspended'
                                      : _secondsUntilNextWave <= 0 
                                          ? 'Preparing next scan...' 
                                          : (isInternetOffline ? 'Offline Mode - Next wave in: ' : 'Next wave in: ') + '${_secondsUntilNextWave ~/ 60}:${(_secondsUntilNextWave % 60).toString().padLeft(2, '0')}',
                                  style: TextStyle(color: _isLocalApiOffline ? Colors.red : (_isScanning || _isUploading ? const Color(0xFF58A6FF) : const Color(0xFF8B949E))),
                                ),
                              ),
                            ],
                          );
                        }
                      ),
                      
                      const Divider(color: Color(0xFF30363D), height: 30),
                      
                      // Controls Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildControlBtn(
                            icon: Icons.play_arrow, 
                            label: "Scan Now", 
                            color: _isLocalApiOffline || _isScanning || _isUploading ? const Color(0xFF30363D) : const Color(0xFF3FB950),
                            onTap: _isLocalApiOffline || _isScanning || _isUploading ? null : () => _updateLocalSettings({'force_trigger': true}),
                          ),
                          _buildControlBtn(
                            icon: _isPaused ? Icons.play_circle_fill : Icons.pause_circle_filled, 
                            label: _isPaused ? "Resume" : "Pause", 
                            color: _isLocalApiOffline ? const Color(0xFF30363D) : const Color(0xFFD29922),
                            onTap: _isLocalApiOffline ? null : () => _updateLocalSettings({'is_paused': !_isPaused}),
                          ),
                          _buildControlBtn(
                            icon: Icons.settings, 
                            label: "${_intervalMins}m", 
                            color: _isLocalApiOffline ? const Color(0xFF30363D) : const Color(0xFF8B949E),
                            onTap: _isLocalApiOffline ? null : _showIntervalDialog,
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // OFFLINE QUEUE BUTTON
              InkWell(
                onTap: () => _smoothNavigate(const OfflineQueueScreen()),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF161B22),
                    border: Border.all(color: const Color(0xFF21262D)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.sd_storage, color: Colors.orange, size: 24),
                      SizedBox(width: 16),
                      Text('View Local Offline Queue', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      Spacer(),
                      Icon(Icons.arrow_forward_ios, color: Color(0xFF8B949E), size: 16),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // CLOUD HISTORY BUTTON
              InkWell(
                onTap: () => _smoothNavigate(const WaveLogScreen()),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF161B22),
                    border: Border.all(color: const Color(0xFF21262D)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.history, color: const Color(0xFF58A6FF), size: 24),
                      SizedBox(width: 16),
                      Text('View Cloud History', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      Spacer(),
                      Icon(Icons.arrow_forward_ios, color: Color(0xFF8B949E), size: 16),
                    ],
                  ),
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }

  // --- BUTTON HELPER ---
  Widget _buildControlBtn({required IconData icon, required String label, required Color color, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}