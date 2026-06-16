import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GalleryScreen extends StatelessWidget {
  final String waveId;
  final String classification;
  
  const GalleryScreen({super.key, required this.waveId, required this.classification});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(backgroundColor: const Color(0xFF0D1117), title: Text('${classification.toUpperCase()} Gallery')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: Supabase.instance.client
            .from('wave_images')
            .select()
            .eq('wave_id', waveId)
            .eq('classification', classification)
            .order('position', ascending: true),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          final images = snapshot.data!;
          if (images.isEmpty) return const Center(child: Text("No images found.", style: TextStyle(color: Colors.white)));

          return GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, crossAxisSpacing: 8, mainAxisSpacing: 8,
            ),
            itemCount: images.length,
            itemBuilder: (context, index) {
              return Container(
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF21262D)),
                  borderRadius: BorderRadius.circular(8),
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(images[index]['image_url'], fit: BoxFit.cover),
                    Positioned(
                      bottom: 0, left: 0, right: 0,
                      child: Container(
                        color: Colors.black.withOpacity(0.7),
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          'Plant ${images[index]['position']}', 
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                    )
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}