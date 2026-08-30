import 'package:flutter/material.dart';

class ZoneSelectionScreen extends StatelessWidget {
  const ZoneSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Warehouse Zone'),
        backgroundColor: const Color(0xFFD84315),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Column 1: Z1 to Z6
            Expanded(
              flex: 1,
              child: Column(
                children: List.generate(6, (index) {
                  final zone = 'Z${index + 1}';
                  return Expanded(
                    flex: 1,
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: _buildZoneBox(context, zone),
                    ),
                  );
                }),
              ),
            ),
            // Column 2: Z7 to Z11 (Z11 is double size)
            Expanded(
              flex: 1,
              child: Column(
                children: [
                  ...List.generate(4, (index) {
                    final zone = 'Z${index + 7}';
                    return Expanded(
                      flex: 1,
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: _buildZoneBox(context, zone),
                      ),
                    );
                  }),
                  Expanded(
                    flex: 2, // Double size for Z11
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: _buildZoneBox(context, 'Z11'),
                    ),
                  ),
                ],
              ),
            ),
            // Column 3: Z12 to Z17
            Expanded(
              flex: 1,
              child: Column(
                children: List.generate(6, (index) {
                  final zone = 'Z${index + 12}';
                  return Expanded(
                    flex: 1,
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: _buildZoneBox(context, zone),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildZoneBox(BuildContext context, String zoneName) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFFD84315),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: const Color(0xFFD84315).withOpacity(0.5), width: 1.5),
        ),
        elevation: 2,
      ),
      onPressed: () => Navigator.pop(context, zoneName),
      child: Text(zoneName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }
}