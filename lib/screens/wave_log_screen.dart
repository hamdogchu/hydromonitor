import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'summary_screen.dart';

class WaveLogScreen extends StatelessWidget {
  const WaveLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(backgroundColor: const Color(0xFF0D1117), title: const Text('Wave History', style: TextStyle(color: Colors.white))),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: Supabase.instance.client.from('waves').stream(primaryKey: ['id']), // Removed SQL order, doing it in Dart
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          final waves = snapshot.data!;
          if (waves.isEmpty) return const Center(child: Text('No waves found.', style: TextStyle(color: Colors.white)));

          // 1. Enforce strict sorting: Newest waves at the top
          waves.sort((a, b) {
            String timeA = a['started_at'] ?? '';
            String timeB = b['started_at'] ?? '';
            return timeB.compareTo(timeA); 
          });

          return ListView.builder(
            itemCount: waves.length,
            itemBuilder: (context, index) {
              var wave = waves[index];
              
              // 2. Format the Date and Time
              String subtitleText = 'Status: ${wave['status']}';
              if (wave['status'] == 'completed' && wave['completed_at'] != null) {
                DateTime dt = DateTime.parse(wave['completed_at']).toLocal();
                
                // Formats to: "Finished: 10/24/2026 at 14:30"
                String date = '${dt.month.toString().padLeft(2,'0')}/${dt.day.toString().padLeft(2,'0')}/${dt.year}';
                String time = '${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
                subtitleText = 'Finished: $date at $time';
              }

              return ListTile(
                title: Text(wave['id'].toString().substring(0, 8), style: const TextStyle(color: Colors.white)),
                subtitle: Text(subtitleText, style: const TextStyle(color: Color(0xFF8B949E))),
                trailing: const Icon(Icons.chevron_right, color: Color(0xFF8B949E)),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => SummaryScreen(waveId: wave['id'])
                  ));
                },
              );
            },
          );
        },
      ),
    );
  }
}