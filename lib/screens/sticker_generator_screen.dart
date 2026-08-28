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
  // Controllers for the new format
  final _companyController = TextEditingController(text: 'PEP');
  final _docketController = TextEditingController(text: '100032436');
  final _boxCountController = TextEditingController(text: '10');

  bool _isLoading = false;

  Future<void> _generatePdf() async {
    setState(() => _isLoading = true);

    try {
      final company = _companyController.text.trim().toUpperCase();
      final docket = _docketController.text.trim();
      int totalBoxes = int.tryParse(_boxCountController.text) ?? 0;

      if (company.isEmpty || docket.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Company aur Docket Number zaruri hai!'), backgroundColor: Colors.red),
        );
        return;
      }

      if (totalBoxes <= 0 || totalBoxes > 500) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Box Count 1 se 500 ke beech honi chahiye!'), backgroundColor: Colors.red),
        );
        return;
      }

      final pdf = pw.Document();

      // Generate sticker codes in the format: COMPANY+DOCKET - BOX_NUMBER
      List<String> codes = [];
      for (int i = 1; i <= totalBoxes; i++) {
        codes.add('$company$docket - $i');
      }

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.all(20),
          build: (pw.Context context) {
            return [
              pw.Wrap(
                spacing: 10,
                runSpacing: 10,
                children: codes.map((code) {
                  return pw.Container(
                    width: 150,
                    height: 80,
                    padding: pw.EdgeInsets.all(5),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.black, width: 0.5),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      mainAxisAlignment: pw.MainAxisAlignment.center,
                      children: [
                        pw.BarcodeWidget(
                          data: code,
                          barcode: pw.Barcode.code128(),
                          width: 130,
                          height: 40,
                          drawText: false,
                        ),
                        pw.SizedBox(height: 5),
                        pw.Text(code, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                      ],
                    ),
                  );
                }).toList(),
              )
            ];
          },
        ),
      );

      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/Stickers_${company}_$docket.pdf';
      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());

      if (!mounted) return;
      await Share.shareXFiles([XFile(filePath)], text: 'Barcode Stickers - $company $docket');

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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Generate box-wise stickers for a single docket.', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 20),
            TextField(
              controller: _companyController,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Company Name (e.g., PEP)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.business),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _docketController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Docket Number (e.g., 100032436)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.receipt_long),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _boxCountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Total Boxes (e.g., 10)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.inventory_2),
              ),
            ),
            const Spacer(),
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