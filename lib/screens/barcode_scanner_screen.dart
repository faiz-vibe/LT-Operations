import 'package:flutter/services.dart';
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
  final MobileScannerController _controller = MobileScannerController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Manual Entry Dialog
  Future<void> _showManualEntryDialog() async {
    String manualCode = '';
    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Enter Docket Number'),
        content: TextField(
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.deny(RegExp(r'[a-zA-Z]')),
          ],
          decoration: const InputDecoration(
            hintText: 'Type Docket Number',
            border: OutlineInputBorder(),
          ),
          onChanged: (val) => manualCode = val,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (manualCode.trim().isNotEmpty) {
                Navigator.pop(dialogContext);
                Navigator.pop(context, manualCode.trim().toUpperCase()); // Scanner screen se value return karo
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Barcode'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: _controller.torchState,
              builder: (context, state, child) {
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

          // Bottom me Gallery aur Manual Entry buttons
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 30, left: 16, right: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Naya: Manual Entry Button
                  ElevatedButton.icon(
                    icon: const Icon(Icons.keyboard, color: Colors.white),
                    label: const Text('Manual Entry (No Barcode)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange[800],
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    onPressed: _showManualEntryDialog,
                  ),
                  const SizedBox(height: 12),
                  // Gallery Button
                  ElevatedButton.icon(
                    icon: const Icon(Icons.photo_library, color: Colors.white),
                    label: const Text('Scan from Gallery', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[800],
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    onPressed: () async {
                      final ImagePicker picker = ImagePicker();
                      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

                      if (image != null) {
                        final bool success = await _controller.analyzeImage(image.path);

                        if (success != true && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Is image me koi barcode nahi mila.')),
                          );
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}