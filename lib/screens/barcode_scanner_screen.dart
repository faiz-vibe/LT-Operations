import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter/services.dart'; // Haptic feedback ke liye

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  bool _isDetected = false; // Ek hi barcode ko multiple baar scan na karein uske liye

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Barcode'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
      ),
      body: MobileScanner(
        onDetect: (capture) {
          final List<Barcode> barcodes = capture.barcodes;
          if (barcodes.isNotEmpty && !_isDetected) {
            _isDetected = true; // Lock laga do

            // Phone vibrate kare (Haptic feedback)
            HapticFeedback.mediumImpact();

            final String? code = barcodes.first.rawValue;
            if (code != null) {
              // scanned code wapas consignment screen par bhej do
              Navigator.pop(context, code);
            } else {
              Navigator.pop(context, '');
            }
          }
        },
      ),
    );
  }
}