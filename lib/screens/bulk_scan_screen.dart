import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter/services.dart';
import '../models/vehicle_entry.dart';
import '../models/box_item.dart';

class BulkScanScreen extends StatefulWidget {
  final VehicleEntry vehicleEntry;
  const BulkScanScreen({super.key, required this.vehicleEntry});

  @override
  State<BulkScanScreen> createState() => _BulkScanScreenState();
}

class _BulkScanScreenState extends State<BulkScanScreen> {
  final MobileScannerController _controller = MobileScannerController();
  final List<String> _scannedCodes = [];
  final Set<String> _codeSet = {}; // Fast duplicate check ke liye
  bool _isProcessing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleBarcode(BarcodeCapture capture) {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final String? code = barcodes.first.rawValue;
      if (code != null && code.isNotEmpty) {
        _isProcessing = true; // Lock laga do taaki rapid double scan na ho

        if (_codeSet.contains(code)) {
          // Duplicate scan detected
          HapticFeedback.heavyImpact(); // Alag vibration
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Duplicate: $code already scanned!'),
              backgroundColor: Colors.red,
              duration: const Duration(milliseconds: 500),
            ),
          );
        } else {
          // New scan
          HapticFeedback.mediumImpact();
          setState(() {
            _scannedCodes.add(code);
            _codeSet.add(code);
          });
        }

        // 500ms ka delay taki user next box scan kar sake
        Future.delayed(const Duration(milliseconds: 500), () {
          _isProcessing = false;
        });
      }
    }
  }

  void _saveAndFinish() {
    for (String code in _scannedCodes) {
      // DB me check karo agar already exist toh nahi karta
      bool exists = widget.vehicleEntry.boxes.any((b) => b.consignmentNo == code);
      if (!exists) {
        final box = BoxItem(
          consignmentNo: code,
          companyName: 'Unknown',
          expectedBoxes: 1,
          receivedBoxes: 1,
          createdAt: DateTime.now(),
        );
        widget.vehicleEntry.boxes.add(box);
      }
    }
    widget.vehicleEntry.lastEditedAt = DateTime.now();
    widget.vehicleEntry.save();

    Navigator.pop(context); // Consignment screen par wapas
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bulk Scan Mode'),
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
      body: Column(
        children: [
          // Top half: Camera
          Expanded(
            flex: 2,
            child: MobileScanner(
              controller: _controller,
              onDetect: _handleBarcode,
            ),
          ),
          // Bottom half: Scanned List
          Expanded(
            flex: 3,
            child: Container(
              color: Colors.grey[100],
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Scanned: ${_scannedCodes.length} Boxes', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        if (_scannedCodes.isNotEmpty)
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _scannedCodes.clear();
                                _codeSet.clear();
                              });
                            },
                            child: const Text('Clear All', style: TextStyle(color: Colors.red)),
                          ),
                      ],
                    ),
                  ),
                  const Divider(),
                  Expanded(
                    child: _scannedCodes.isEmpty
                        ? const Center(child: Text('Start scanning to add boxes fast...'))
                        : ListView.builder(
                      itemCount: _scannedCodes.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          leading: const Icon(Icons.check_circle, color: Colors.green),
                          title: Text(_scannedCodes[index]),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[800],
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _scannedCodes.isEmpty ? null : _saveAndFinish,
                        child: const Text('Save & Finish', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
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