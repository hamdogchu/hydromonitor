import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class WifiDialog extends StatefulWidget {
  const WifiDialog({super.key});

  @override
  State<WifiDialog> createState() => _WifiDialogState();
}

class _WifiDialogState extends State<WifiDialog> {
  List<String> _networks = [];
  bool _isScanning = false;
  String? _currentNetwork;

  @override
  void initState() {
    super.initState();
    _scanNetworks();
  }

  Future<void> _scanNetworks() async {
    setState(() => _isScanning = true);
    try {
      final response = await http.get(Uri.parse('http://127.0.0.1:5001/scan'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _networks = List<String>.from(data['networks']);
          _currentNetwork = data['current_network'];
        });
      }
    } catch (e) {
      // Ignore error, it means we aren't running on the Pi
    }
    setState(() => _isScanning = false);
  }

  void _promptPassword(String ssid) {
    String password = '';

    // Helper function to trigger the OS keyboard via the local Python API
    void showKeyboard() async {
      try {
        await http.post(Uri.parse('http://127.0.0.1:5000/toggle_keyboard'));
      } catch (_) {}
    }

    // Attempt to show it automatically as soon as the dialog opens
    showKeyboard();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF161B22),
          title: Text('Connect to $ssid', style: const TextStyle(color: Colors.white)),
          content: TextField(
            obscureText: true,
            style: const TextStyle(color: Colors.white),
            onTap: showKeyboard, // Shows keyboard if user taps the text field
            decoration: InputDecoration(
              labelText: 'Wi-Fi Password',
              labelStyle: const TextStyle(color: Color(0xFF8B949E)),
              enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF30363D))),
              focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF58A6FF))),
              suffixIcon: IconButton(
                icon: const Icon(Icons.keyboard, color: Color(0xFF58A6FF)),
                tooltip: 'Show Keyboard',
                onPressed: showKeyboard, // Manual override button
              ),
            ),
            onChanged: (val) => password = val,
          ),
          actions: [
            TextButton(
              onPressed: () {
                showKeyboard(); // Send command to toggle/hide the keyboard
                Navigator.pop(context);
              },
              child: const Text('Cancel', style: TextStyle(color: Color(0xFF8B949E))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF238636)),
              onPressed: () {
                showKeyboard(); // Send command to toggle/hide the keyboard
                Navigator.pop(context);
                _connectToNetwork(ssid, password);
              },
              child: const Text('Connect', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _connectToNetwork(String ssid, String password) async {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Connecting to $ssid...')));
    try {
      final response = await http.post(
        Uri.parse('http://127.0.0.1:5001/connect'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'ssid': ssid, 'password': password}),
      );
      final data = json.decode(response.body);
      if (data['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Connected successfully!'), backgroundColor: Colors.green));
        }
        _scanNetworks(); // Rescan immediately to update the UI with the green checkmark
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: ${data['error']}'), backgroundColor: Colors.red));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF161B22),
      title: const Text('Wi-Fi Networks', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      content: SizedBox(
        width: double.maxFinite,
        height: 300,
        child: Column(
          children: [
            if (_isScanning)
              const Padding(
                padding: EdgeInsets.only(bottom: 16.0),
                child: LinearProgressIndicator(color: Color(0xFF58A6FF), backgroundColor: Color(0xFF30363D)),
              ),
            Expanded(
              child: _networks.isEmpty && !_isScanning
                  ? const Center(child: Text("No networks found.", style: TextStyle(color: Color(0xFF8B949E))))
                  : ListView.builder(
                      itemCount: _networks.length,
                      itemBuilder: (context, index) {
                        final ssid = _networks[index];
                        final isConnected = ssid == _currentNetwork;

                        return ListTile(
                          leading: Icon(
                            isConnected ? Icons.wifi : Icons.wifi_lock, 
                            color: isConnected ? const Color(0xFF3FB950) : const Color(0xFF8B949E)
                          ),
                          title: Text(
                            ssid, 
                            style: TextStyle(
                              color: isConnected ? const Color(0xFF3FB950) : Colors.white, 
                              fontWeight: isConnected ? FontWeight.bold : FontWeight.normal,
                            )
                          ),
                          subtitle: isConnected 
                              ? const Text("Connected", style: TextStyle(color: Color(0xFF3FB950), fontSize: 12)) 
                              : null,
                          onTap: () => isConnected ? null : _promptPassword(ssid), // Disable tapping if already connected
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isScanning ? null : _scanNetworks,
          child: const Text('Rescan', style: TextStyle(color: Color(0xFF58A6FF))),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close', style: TextStyle(color: Color(0xFF8B949E))),
        ),
      ],
    );
  }
}