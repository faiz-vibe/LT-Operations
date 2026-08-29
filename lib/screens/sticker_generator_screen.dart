import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class StickerGeneratorScreen extends StatefulWidget {
  const StickerGeneratorScreen({super.key});

  @override
  State<StickerGeneratorScreen> createState() => _StickerGeneratorScreenState();
}

class _StickerGeneratorScreenState extends State<StickerGeneratorScreen> {
  final _companyController = TextEditingController(text: '');
  final _docketController = TextEditingController(text: '100012312');
  final _boxCountController = TextEditingController(text: '29');
  final _sourceController = TextEditingController(text: '');
  final _destinationController = TextEditingController(text: '');

  String _selectedMode = 'Surface';
  String _selectedType = 'QR Code';
  bool _isLoading = false;

  Future<void> _generatePdf() async {
    setState(() => _isLoading = true);

    try {
      final company = _companyController.text.trim().toUpperCase();
      final docket = _docketController.text.trim();
      int totalBoxes = int.tryParse(_boxCountController.text) ?? 0;
      final source = _sourceController.text.trim();
      final destination = _destinationController.text.trim();
      final mode = _selectedMode;

      if (docket.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Docket Number zaruri hai!'), backgroundColor: Colors.red),
        );
        return;
      }

      if (totalBoxes <= 0 || totalBoxes > 10000) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Box Count 1 se 10,000 ke beech honi chahiye!'), backgroundColor: Colors.red),
        );
        return;
      }

      final pdf = pw.Document();

      // Total boxes ka string format (e.g., "29")
      String totalStr = totalBoxes.toString().padLeft(2, '0');

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.all(20),
          build: (pw.Context context) {
            return [
              pw.Wrap(
                spacing: 10,
                runSpacing: 10,
                children: List.generate(totalBoxes, (index) {
                  int i = index + 1;

                  // QR/Barcode me sirf docket aur box number jayega (e.g., 100012312 - 1)
                  String scanData = '$docket - $i';

                  // Visual text ke liye box number format (e.g., 01 / 29)
                  String currentBoxStr = i.toString().padLeft(2, '0');
                  String boxCountText = 'Box: $currentBoxStr / $totalStr';

                  // Barcode ya QR Code generate karne ka logic
                  pw.Widget codeWidget;
                  if (_selectedType == 'QR Code') {
                    codeWidget = pw.BarcodeWidget(
                      data: scanData,
                      barcode: pw.Barcode.qrCode(),
                      width: 80,
                      height: 80,
                    );
                  } else {
                    codeWidget = pw.BarcodeWidget(
                      data: scanData,
                      barcode: pw.Barcode.code128(),
                      width: 140,
                      height: 35,
                      drawText: false,
                    );
                  }

                  return pw.Container(
                    width: 160,
                    height: 130, // Height badhai taaki saari info aa sake
                    padding: pw.EdgeInsets.all(5),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.black, width: 0.5),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      mainAxisAlignment: pw.MainAxisAlignment.center,
                      children: [
                        codeWidget, // QR ya Barcode yahan aayega
                        pw.SizedBox(height: 5),
                        pw.Text('Docket: $docket', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 2),
                        pw.Text(boxCountText, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)), // 01 / 29 format
                        pw.SizedBox(height: 2),
                        if (source.isNotEmpty || destination.isNotEmpty)
                          pw.Text('$source To $destination', style: pw.TextStyle(fontSize: 8)),
                        pw.SizedBox(height: 2),
                        pw.Text('Mode: $mode', style: pw.TextStyle(fontSize: 8)),
                      ],
                    ),
                  );
                }),
              )
            ];
          },
        ),
      );

      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/Stickers_$docket.pdf';
      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());

      if (!mounted) return;
      await Share.shareXFiles([XFile(filePath)], text: 'Stickers - $docket');

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Generate Stickers'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Generate QR or Barcode stickers for boxes.', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 20),

            DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Sticker Type (QR Code scans better)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.qr_code),
              ),
              items: const [
                DropdownMenuItem(value: 'QR Code', child: Text('QR Code (Recommended)')),
                DropdownMenuItem(value: 'Barcode', child: Text('Barcode (Code 128)')),
              ],
              onChanged: (val) {
                setState(() {
                  _selectedType = val!;
                });
              },
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _docketController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Docket Number (e.g., 100012312)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.receipt_long),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _sourceController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Source',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.location_on),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _destinationController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Destination',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.flag),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedMode,
              decoration: const InputDecoration(
                labelText: 'Transport Mode',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.local_shipping),
              ),
              items: const [
                DropdownMenuItem(value: 'Surface', child: Text('Surface')),
                DropdownMenuItem(value: 'Road', child: Text('Road')),
                DropdownMenuItem(value: 'Air', child: Text('Air')),
                DropdownMenuItem(value: 'Train', child: Text('Train')),
              ],
              onChanged: (val) {
                setState(() {
                  _selectedMode = val!;
                });
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _boxCountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Total Boxes (e.g., 29)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.inventory_2),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                icon: _isLoading
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.print, color: Colors.white),
                label: Text(_isLoading ? 'Generating...' : 'Generate & Share PDF',
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[800]),
                onPressed: _isLoading ? null : _generatePdf,
              ),
            ),
          ],
        ),
      ),
    );
  }
}