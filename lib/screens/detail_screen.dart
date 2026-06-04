import 'package:flutter/material.dart';

class DetailScreen extends StatelessWidget {
  final Map<String, dynamic> scan;

  const DetailScreen({super.key, required this.scan});

  @override
  Widget build(BuildContext context) {
    // Safely extract data
    String trayId = scan['tray_id']?.toString() ?? 'Unknown';
    bool diseaseDetected = scan['disease_detected'] ?? false;
    String diseaseName = scan['disease_name']?.toString() ?? 'Unknown Disease';
    bool pestDetected = scan['pest_detected'] ?? false;
    String pestName = scan['pest_name']?.toString() ?? 'Unknown Pest';

    String diseaseDesc = diseaseDetected 
        ? "A soil-borne viral disease causing vein clearing and leaf distortion. Reduce irrigation and improve drainage to limit spread."
        : "No visual symptoms of disease were detected in the latest scan.";
        
    String pestDesc = pestDetected
        ? "Larvae that tunnel through leaf tissue leaving winding trails. They weaken plants and reduce photosynthesis. Remove affected leaves."
        : "No pest activity found in this tray.";

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1117),
        elevation: 0,
        automaticallyImplyLeading: false, 
        title: Row(
          children: [
            InkWell(
              onTap: () => Navigator.pop(context),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF21262D), width: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.arrow_back, size: 14, color: Color(0xFF8B949E)),
                    SizedBox(width: 6),
                    Text('All trays', style: TextStyle(fontSize: 12, color: Color(0xFF8B949E))),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  trayId,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF58A6FF)),
                ),
                const Text(
                  'Hydroponic Tray',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFFE6EDF3)),
                ),
              ],
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(10.0),
          child: Container(color: const Color(0xFF21262D), height: 0.5),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          children: [
            _buildDetailCard(
              label: 'DISEASE STATUS',
              isAlert: diseaseDetected,
              badgeText: diseaseDetected ? 'Suspected disease' : 'No disease detected',
              badgeColor: const Color(0xFFE3B341),
              badgeBg: const Color(0xFF2D2010),
              badgeBorder: const Color(0xFF6E4C0A),
              title: diseaseDetected ? diseaseName : 'Plants appear healthy',
              description: diseaseDesc,
            ),
            const SizedBox(height: 12),
            
            _buildDetailCard(
              label: 'PEST DETECTION',
              isAlert: pestDetected,
              badgeText: pestDetected ? 'Pests detected' : 'No pests detected',
              badgeColor: const Color(0xFFF85149),
              badgeBg: const Color(0xFF2D1117),
              badgeBorder: const Color(0xFF6E1C1C),
              title: pestDetected ? pestName : 'Clear',
              description: pestDesc,
            ),
            const SizedBox(height: 12),

            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF161B22),
                border: Border.all(color: const Color(0xFF21262D), width: 0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'LAST CAPTURED IMAGE',
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Color(0xFF6E7681), letterSpacing: 1.2),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 160,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D1117),
                      border: Border.all(color: const Color(0xFF21262D), width: 0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.camera_alt_outlined, size: 28, color: Color(0xFF21262D)),
                        SizedBox(height: 8),
                        Text('Latest capture from tray camera', style: TextStyle(fontSize: 11, color: Color(0xFF484F58))),
                      ],
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildDetailCard({
    required String label, required bool isAlert, required String badgeText,
    required Color badgeColor, required Color badgeBg, required Color badgeBorder,
    required String title, required String description,
  }) {
    Color finalBadgeColor = isAlert ? badgeColor : const Color(0xFF3FB950);
    Color finalBadgeBg = isAlert ? badgeBg : const Color(0xFF0D2015);
    Color finalBadgeBorder = isAlert ? badgeBorder : const Color(0xFF1A5C2A);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        border: Border.all(color: const Color(0xFF21262D), width: 0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Color(0xFF6E7681), letterSpacing: 1.2),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: finalBadgeBg,
              border: Border.all(color: finalBadgeBorder, width: 0.5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              badgeText,
              style: TextStyle(fontSize: 10, color: finalBadgeColor, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFFE6EDF3)),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: const TextStyle(fontSize: 11, color: Color(0xFF8B949E), height: 1.5),
          ),
        ],
      ),
    );
  }
}