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
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1117), 
        title: Text('${classification.toUpperCase()} Gallery', style: const TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        // Make sure we select the new 'detections' column here!
        future: Supabase.instance.client
            .from('wave_images')
            .select('image_url, position, detections') 
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
              final imageData = images[index];
              return InkWell(
                // When tapped, navigate to the new maximized screen
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => MaximizedDetectionScreen(
                      imageUrl: imageData['image_url'],
                      position: imageData['position'].toString(),
                      // Default to empty list if no detections exist
                      detections: imageData['detections'] ?? [], 
                    )
                  ));
                },
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFF21262D)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(imageData['image_url'], fit: BoxFit.cover),
                      Positioned(
                        bottom: 0, left: 0, right: 0,
                        child: Container(
                          color: Colors.black.withOpacity(0.7),
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                            'Plant ${imageData['position']}', 
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// --- NEW FULL SCREEN WIDGET ---
class MaximizedDetectionScreen extends StatelessWidget {
  final String imageUrl;
  final String position;
  final dynamic detections;

  const MaximizedDetectionScreen({
    super.key, 
    required this.imageUrl, 
    required this.position, 
    required this.detections
  });

  @override
  Widget build(BuildContext context) {
    // Ensure detections is treated as a List
    List<dynamic> detectionList = detections is List ? detections : [];

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text('Plant $position Analysis', style: const TextStyle(color: Colors.white)),
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // 1. Pinch-to-Zoom Image Viewer
          Center(
            child: InteractiveViewer(
              panEnabled: true,
              minScale: 1.0,
              maxScale: 4.0,
              child: Image.network(imageUrl, fit: BoxFit.contain),
            ),
          ),
          
          // 2. Floating Detections Card
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF161B22).withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF30363D)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Detections:', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  
                  if (detectionList.isEmpty)
                    const Text('No issues detected.', style: TextStyle(color: Colors.green)),
                    
                  // Loop through the JSON data and build a row for each disease found
                  ...detectionList.map((d) {
                    final className = d['class'] ?? 'Unknown';
                    // Optional: If your AI sends confidence scores, you can display them here!
                    final confidence = d['confidence'] != null 
                        ? '${(d['confidence'] * 100).toStringAsFixed(1)}%' 
                        : '';
                    
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 16),
                          const SizedBox(width: 8),
                          Text(className, style: const TextStyle(color: Color(0xFFE6EDF3), fontSize: 14)),
                          const Spacer(),
                          Text(confidence, style: const TextStyle(color: Color(0xFF8B949E), fontSize: 14)),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}