import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/offline_warning.dart';
import 'wave_log_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Timer? _timer;
  int _secondsUntilNextWave = 0;
  DateTime? _targetTime; 

  late Stream<List<Map<String, dynamic>>> _wavesStream;
  late Stream<List<Map<String, dynamic>>> _settingsStream;

  @override
  void initState() {
    super.initState();
    _initStreams();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_targetTime != null) {
        setState(() {
          _secondsUntilNextWave = _targetTime!.difference(DateTime.now()).inSeconds;
          if (_secondsUntilNextWave < 0) _secondsUntilNextWave = 0; 
        });
      }
    });
  }

  void _initStreams() {
    _wavesStream = Supabase.instance.client
        .from('waves')
        .stream(primaryKey: ['id'])
        .order('started_at', ascending: false)
        .limit(1);
        
    _settingsStream = Supabase.instance.client
        .from('tray_settings')
        .stream(primaryKey: ['id'])
        .eq('id', 1); 
  }

  Future<void> _refreshData() async {
    setState(() {
      _initStreams(); 
    });
    await Future.delayed(const Duration(milliseconds: 600));
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

  Future<void> _togglePause(bool isCurrentlyPaused) async {
    await Supabase.instance.client.from('tray_settings').update({'is_paused': !isCurrentlyPaused}).eq('id', 1);
  }

  Future<void> _forceTrigger() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        backgroundColor: Color(0xFF161B22),
        content: Row(
          children: [
            CircularProgressIndicator(color: Color(0xFF58A6FF)),
            SizedBox(width: 20),
            Expanded(child: Text("Waking up Raspberry Pi...", style: TextStyle(color: Colors.white))),
          ],
        ),
      ),
    );

    try {
      await Supabase.instance.client.from('tray_settings').update({'force_trigger': true}).eq('id', 1);

      bool acknowledged = false;
      for (int i = 0; i < 15; i++) { 
        await Future.delayed(const Duration(seconds: 1));
        final check = await Supabase.instance.client.from('tray_settings').select('force_trigger').eq('id', 1).single();
        if (check['force_trigger'] == false) {
          acknowledged = true;
          break;
        }
      }

      if (mounted) Navigator.pop(context);

      if (acknowledged) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Success! Raspberry Pi acknowledged and is starting the scan."), backgroundColor: Color(0xFF238636))
          );
        }
      } else {
        await Supabase.instance.client.from('tray_settings').update({'force_trigger': false}).eq('id', 1); 
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Error: Raspberry Pi is offline or not responding."), backgroundColor: Colors.red)
          );
        }
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Network Error: $e"), backgroundColor: Colors.red)
        );
      }
    }
  }

  Future<void> _confirmAction({required String title, required String content, required VoidCallback onConfirm}) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF161B22),
          title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: Text(content, style: const TextStyle(color: Color(0xFF8B949E))),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text("Cancel", style: TextStyle(color: Color(0xFF8B949E))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF238636)),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text("Confirm", style: TextStyle(color: Colors.white)),
            )
          ],
        );
      }
    );

    if (confirm == true) onConfirm();
  }

  void _showIntervalDialog(int currentInterval) {
    int selected = currentInterval;
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF161B22),
              title: const Text("Set Timer Interval", style: TextStyle(color: Colors.white)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Minimum interval is 10 minutes.", style: TextStyle(color: Color(0xFF8B949E))),
                  const SizedBox(height: 20),
                  Slider(
                    value: selected.toDouble(),
                    min: 10,
                    max: 120,
                    divisions: 11,
                    activeColor: const Color(0xFF58A6FF),
                    label: "$selected mins",
                    onChanged: (val) => setDialogState(() => selected = val.toInt()),
                  ),
                  Text("$selected Minutes", style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel", style: TextStyle(color: Color(0xFF8B949E))),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF238636)),
                  onPressed: () async {
                    await Supabase.instance.client.from('tray_settings').update({'interval_minutes': selected}).eq('id', 1);
                    if (mounted) Navigator.pop(context);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1117),
        title: const Text('HydroMonitor', style: TextStyle(color: Colors.white)),
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh, color: Color(0xFF8B949E)), onPressed: _refreshData),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        backgroundColor: const Color(0xFF161B22),
        color: const Color(0xFF58A6FF),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(), 
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: _settingsStream,
            builder: (context, settingsSnapshot) {
              if (settingsSnapshot.hasError) return Padding(
                padding: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.2),
                child: OfflineWarningWidget(onRetry: _refreshData),
              );
              
              final settings = settingsSnapshot.data?.isNotEmpty == true ? settingsSnapshot.data!.first : null;
              final bool isPaused = settings?['is_paused'] ?? false;
              final int intervalMins = settings?['interval_minutes'] ?? 30;
              final bool isScanning = settings?['is_scanning'] ?? false; 

              // Heartbeat logic
              bool isPiOffline = true;
              if (settings != null && settings['last_heartbeat'] != null) {
                // Use UTC to prevent timezone glitches and .abs() to prevent clock-drift bugs!
                final hb = DateTime.parse(settings['last_heartbeat']).toUtc();
                final secondsSincePing = DateTime.now().toUtc().difference(hb).inSeconds;
                
                // Increased tolerance to 120 seconds
                if (secondsSincePing.abs() < 120) {
                  isPiOffline = false; 
                }
              }

              // OVERRIDE: If the Pi says it is actively scanning, it is definitely not offline!
              if (isScanning) {
                isPiOffline = false;
              }

              return StreamBuilder<List<Map<String, dynamic>>>(
                stream: _wavesStream,
                builder: (context, waveSnapshot) {
                  if (waveSnapshot.hasError) return Padding(
                    padding: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.2),
                    child: OfflineWarningWidget(onRetry: _refreshData),
                  );

                  if (waveSnapshot.hasData && waveSnapshot.data!.isNotEmpty) {
                    final latestWave = waveSnapshot.data!.first;
                    
                    if (isScanning || isPaused) {
                      _targetTime = null; 
                    } else if (latestWave['completed_at'] != null) {
                      DateTime completedAt = DateTime.parse(latestWave['completed_at']).toLocal();
                      _targetTime = completedAt.add(Duration(minutes: intervalMins));
                    }
                  }

                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        InkWell(
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
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Tray 1', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                                    if (isPiOffline)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(color: Colors.red.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                                        child: const Text('PI OFFLINE', style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
                                      )
                                    else if (isPaused)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(color: Colors.orange.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                                        child: const Text('PAUSED', style: TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)),
                                      )
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Icon(
                                      isPiOffline ? Icons.warning_amber_rounded : (isScanning ? Icons.camera_alt : Icons.timer),
                                      color: isPiOffline ? Colors.red : (isScanning ? const Color(0xFF58A6FF) : const Color(0xFF8B949E)),
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      isPiOffline
                                        ? 'Connection to Raspberry Pi lost.'
                                        : isScanning 
                                            ? 'Scanning 14 plants...' 
                                            : isPaused 
                                                ? 'Monitoring Suspended'
                                                : _secondsUntilNextWave <= 0 
                                                    ? 'Preparing next scan...' 
                                                    : 'Next wave in: ${_secondsUntilNextWave ~/ 60}:${(_secondsUntilNextWave % 60).toString().padLeft(2, '0')}',
                                      style: TextStyle(color: isPiOffline ? Colors.red : (isScanning ? const Color(0xFF58A6FF) : const Color(0xFF8B949E))),
                                    ),
                                  ],
                                ),
                                const Divider(color: Color(0xFF30363D), height: 30),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    _buildControlBtn(
                                      icon: isPaused ? Icons.play_arrow : Icons.pause, 
                                      label: isPaused ? "Resume" : "Pause", 
                                      color: isPiOffline ? const Color(0xFF30363D) : (isPaused ? const Color(0xFF3FB950) : Colors.orange),
                                      onTap: isPiOffline ? null : () => _confirmAction(
                                        title: isPaused ? "Resume Monitoring" : "Pause Monitoring",
                                        content: isPaused ? "Resume automatic schedule?" : "Pause automatic schedule?",
                                        onConfirm: () => _togglePause(isPaused),
                                      ),
                                    ),
                                    _buildControlBtn(
                                      icon: Icons.flash_on, 
                                      label: "Scan Now", 
                                      color: isPiOffline ? const Color(0xFF30363D) : const Color(0xFF58A6FF),
                                      onTap: (isScanning || isPiOffline) ? null : () => _confirmAction(
                                        title: "Trigger Manual Scan",
                                        content: "Trigger a manual scan right now?",
                                        onConfirm: _forceTrigger,
                                      ),
                                    ),
                                    _buildControlBtn(
                                      icon: Icons.settings, 
                                      label: "${intervalMins}m", 
                                      color: isPiOffline ? const Color(0xFF30363D) : const Color(0xFF8B949E),
                                      onTap: isPiOffline ? null : () => _showIntervalDialog(intervalMins),
                                    ),
                                  ],
                                )
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            }
          ),
        ),
      ),
    );
  }

  Widget _buildControlBtn({required IconData icon, required String label, required Color color, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Opacity(
        opacity: onTap == null ? 0.3 : 1.0,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}