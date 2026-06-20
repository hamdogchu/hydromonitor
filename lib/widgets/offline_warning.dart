import 'package:flutter/material.dart';

class OfflineWarningWidget extends StatelessWidget {
  final VoidCallback onRetry;
  
  const OfflineWarningWidget({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.wifi_off_rounded, 
              size: 80, 
              color: Color(0xFF8B949E)
            ),
            const SizedBox(height: 20),
            const Text(
              'No Internet Connection', 
              style: TextStyle(
                color: Colors.white, 
                fontSize: 20, 
                fontWeight: FontWeight.bold
              )
            ),
            const SizedBox(height: 8),
            const Text(
              'HydroMonitor cannot reach the database. Please check your network settings and try again.', 
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF8B949E), 
                fontSize: 14,
                height: 1.5,
              )
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 20),
              label: const Text('Retry Connection'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF238636), // Professional green button
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}