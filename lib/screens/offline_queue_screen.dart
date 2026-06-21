import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class OfflineQueueScreen extends StatefulWidget {
  const OfflineQueueScreen({super.key});

  @override
  State<OfflineQueueScreen> createState() => _OfflineQueueScreenState();
}

class _OfflineQueueScreenState extends State<OfflineQueueScreen> {
  List<String> _offlineWaves = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchOfflineWaves();
  }

  Future<void> _fetchOfflineWaves() async {
    try {
      final response = await http.get(Uri.parse('http://127.0.0.1:5000/offline_waves'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _offlineWaves = List<String>.from(data['waves']);
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  String _formatWaveName(String waveName) {
    // Converts "wave_20231027_153000" into a readable date/time
    try {
      final parts = waveName.split('_');
      if (parts.length >= 3) {
        final d = parts[1];
        final t = parts[2];
        return "${d.substring(0, 4)}-${d.substring(4, 6)}-${d.substring(6, 8)} at ${t.substring(0, 2)}:${t.substring(2, 4)}";
      }
    } catch (_) {}
    return waveName;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1117),
        title: const Text('Local Offline Queue', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF58A6FF)))
        : _offlineWaves.isEmpty
          ? const Center(
              child: Text(
                'No pending offline waves.\nEverything is synced to the cloud!', 
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF8B949E), fontSize: 16)
              )
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _offlineWaves.length,
              itemBuilder: (context, index) {
                final wave = _offlineWaves[index];
                return Card(
                  color: const Color(0xFF161B22),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: const BorderSide(color: Color(0xFF21262D))),
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: const Icon(Icons.sd_storage, color: Colors.orange),
                    title: Text(_formatWaveName(wave), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    subtitle: const Text("Pending Cloud Upload", style: TextStyle(color: Color(0xFF8B949E))),
                    trailing: const Icon(Icons.arrow_forward_ios, color: Color(0xFF8B949E), size: 16),
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => OfflineWaveDetailsScreen(waveId: wave, waveTitle: _formatWaveName(wave))));
                    },
                  ),
                );
              },
            ),
    );
  }
}

class OfflineWaveDetailsScreen extends StatefulWidget {
  final String waveId;
  final String waveTitle;
  const OfflineWaveDetailsScreen({super.key, required this.waveId, required this.waveTitle});

  @override
  State<OfflineWaveDetailsScreen> createState() => _OfflineWaveDetailsScreenState();
}

class _OfflineWaveDetailsScreenState extends State<OfflineWaveDetailsScreen> {
  Map<String, dynamic> _results = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchWaveData();
  }

  Future<void> _fetchWaveData() async {
    try {
      final response = await http.get(Uri.parse('http://127.0.0.1:5000/offline_waves/${widget.waveId}/data'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _results = data['results'];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageFilenames = _results.keys.toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1117),
        title: Text(widget.waveTitle, style: const TextStyle(color: Colors.white, fontSize: 16)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF58A6FF)))
        : GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.8,
            ),
            itemCount: imageFilenames.length,
            itemBuilder: (context, index) {
              final filename = imageFilenames[index];
              final imageUrl = 'http://127.0.0.1:5000/offline_waves/${widget.waveId}/image/$filename';
              
              // Count total AI detections for this image
              final detections = _results[filename] as List<dynamic>? ?? [];
              final issueCount = detections.length;

              return ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  color: const Color(0xFF161B22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, color: Colors.grey, size: 50),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8.0),
                        color: issueCount > 0 ? Colors.red.withOpacity(0.2) : Colors.green.withOpacity(0.2),
                        child: Text(
                          issueCount > 0 ? '$issueCount Issues Detected' : 'Healthy',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: issueCount > 0 ? Colors.redAccent : Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              );
            },
          ),
    );
  }
}