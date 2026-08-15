import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  bool _isDetected = false;
  // Camera controller ko global banaya taaki torch aur gallery control kar sakein
  final MobileScannerController _controller = MobileScannerController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Barcode'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        actions: [
          // Torch (Flashlight) Toggle Button
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: _controller.torchState,
              builder: (context, state, child) {
                // Agar torch on hai toh yellow icon, warna white
                if (state == TorchState.on) {
                  return const Icon(Icons.flash_on, color: Colors.yellow);
                }
                return const Icon(Icons.flash_off, color: Colors.white);
              },
            ),
            onPressed: () => _controller.toggleTorch(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty && !_isDetected) {
                _isDetected = true; // Lock laga do

                // Phone vibrate kare (Haptic feedback)
                HapticFeedback.mediumImpact();

                final String? code = barcodes.first.rawValue;
                if (code != null) {
                  Navigator.pop(context, code); // Scanned code wapas bhej do
                } else {
                  Navigator.pop(context, '');
                }
              }
            },
          ),

          // Gallery se Scan karne ka button (Bottom Center me)
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 30),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.photo_library, color: Colors.white),
                label: const Text('Scan from Gallery', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[800],
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                onPressed: () async {
                  final ImagePicker picker = ImagePicker();
                  // Gallery se image select karein
                  final XFile? image = await picker.pickImage(source: ImageSource.gallery);

                  if (image != null) {
                    // Image me barcode search karein
                    final bool? success = await _controller.analyzeImage(image.path);

                    // Agar image me barcode nahi mila
                    if (success != true && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Is image me koi barcode nahi mila.')),
                      );
                    }
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}