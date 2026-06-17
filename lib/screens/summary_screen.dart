import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'gallery_screen.dart';

class SummaryScreen extends StatelessWidget {
  final String waveId;
  const SummaryScreen({super.key, required this.waveId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(backgroundColor: const Color(0xFF0D1117), title: const Text('Wave Summary', style: TextStyle(color: Colors.white))),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: Supabase.instance.client.from('wave_images').select().eq('wave_id', waveId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          int healthy = 0, disease = 0, pest = 0;
          for (var img in snapshot.data!) {
            if (img['classification'] == 'healthy') healthy++;
            if (img['classification'] == 'disease') disease++;
            if (img['classification'] == 'pest') pest++;
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildCategoryCard(context, 'Healthy', healthy, const Color(0xFF3FB950)),
              _buildCategoryCard(context, 'Disease', disease, const Color(0xFFE3B341)),
              _buildCategoryCard(context, 'Pest', pest, const Color(0xFFF85149)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCategoryCard(BuildContext context, String title, int count, Color color) {
    return Card(
      color: const Color(0xFF161B22),
      shape: RoundedRectangleBorder(side: const BorderSide(color: Color(0xFF21262D)), borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        title: Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        trailing: Text('$count plants', style: const TextStyle(color: Colors.white)),
        onTap: () {
          Navigator.push(context, MaterialPageRoute(
            builder: (_) => GalleryScreen(waveId: waveId, classification: title.toLowerCase())
          ));
        },
      ),
    );
  }
}