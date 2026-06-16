import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'summary_screen.dart';

class WaveLogScreen extends StatelessWidget {
  const WaveLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(backgroundColor: const Color(0xFF0D1117), title: const Text('Wave History')),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: Supabase.instance.client.from('waves').stream(primaryKey: ['id']).order('started_at', ascending: false),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          final waves = snapshot.data!;
          return ListView.builder(
            itemCount: waves.length,
            itemBuilder: (context, index) {
              var wave = waves[index];
              return ListTile(
                title: Text(wave['id'].toString().substring(0, 8), style: const TextStyle(color: Colors.white)),
                subtitle: Text('Status: ${wave['status']}', style: const TextStyle(color: Color(0xFF8B949E))),
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