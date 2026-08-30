import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:image/image.dart' as img;
import '../models/vehicle_entry.dart';

class ExportService {
  // 1. WhatsApp Export
  static Future<void> exportToWhatsApp(VehicleEntry entry) async {
    final activeBoxes = entry.boxes.where((b) => !b.isDeleted).toList();

    String message = "*LT Operations - Transport Report*\n\n";
    message += "Vehicle: ${entry.vehicleNumber}\n";
    message += "Driver: ${entry.driverName} (${entry.driverMobile})\n";
    message += "Status: ${entry.vehicleStatus} | Gate: ${entry.gateNumber}\n";
    message += "Date: ${entry.entryDate.day}/${entry.entryDate.month}/${entry.entryDate.year}\n";
    message += "----------------------------------\n";

    for (var box in activeBoxes) {
      message += "Docket: ${box.consignmentNo}\n";
      message += "Company: ${box.companyName}\n";
      message += "Route: ${box.sourceLocation} To ${box.destinationLocation}\n";
      message += "Expected: ${box.expectedBoxes} | Received: ${box.receivedBoxes}\n";
      if (box.shortage > 0) {
        message += "Shortage: ${box.shortage}\n";
      } else if (box.shortage < 0) {
        message += "Extra: ${-box.shortage}\n";
      }
      if (box.isDamaged) {
        message += "Damaged: ${box.damagedCount} (${box.damageDetails})\n";
      }
      message += "----------------------------------\n";
    }

    message += "Total Boxes: ${entry.totalReceivedBoxes}\n";
    message += "Total Shortage: ${entry.totalShortage}\n";

    await Share.share(message, subject: 'Transport Report - ${entry.vehicleNumber}');
  }

  // 2. Excel Export
  static Future<void> exportToExcel(VehicleEntry entry) async {
    final activeBoxes = entry.boxes.where((b) => !b.isDeleted).toList();

    final excel = Excel.createExcel();
    final sheet = excel['Transport Report'];

    sheet.appendRow([TextCellValue('Vehicle Number'), TextCellValue(entry.vehicleNumber)]);
    sheet.appendRow([TextCellValue('Driver Name'), TextCellValue(entry.driverName)]);
    sheet.appendRow([TextCellValue('Driver Mobile'), TextCellValue(entry.driverMobile)]);
    sheet.appendRow([TextCellValue('Status'), TextCellValue('${entry.vehicleStatus} | ${entry.gateNumber}')]);
    sheet.appendRow([TextCellValue('Date'), TextCellValue('${entry.entryDate.day}/${entry.entryDate.month}/${entry.entryDate.year}')]);
    sheet.appendRow([]);

    sheet.appendRow([
      TextCellValue('Consignment No'),
      TextCellValue('Company'),
      TextCellValue('Source'),
      TextCellValue('Destination'),
      TextCellValue('Expected'),
      TextCellValue('Received'),
      TextCellValue('Shortage'),
      TextCellValue('Damaged'),
      TextCellValue('Damage Details')
    ]);

    for (var box in activeBoxes) {
      sheet.appendRow([
        TextCellValue(box.consignmentNo),
        TextCellValue(box.companyName),
        TextCellValue(box.sourceLocation),
        TextCellValue(box.destinationLocation),
        IntCellValue(box.expectedBoxes),
        IntCellValue(box.receivedBoxes),
        IntCellValue(box.shortage),
        box.isDamaged ? IntCellValue(box.damagedCount) : TextCellValue('No'),
        TextCellValue(box.damageDetails)
      ]);
    }

    sheet.appendRow([]);
    sheet.appendRow([TextCellValue('Total Boxes'), IntCellValue(entry.totalReceivedBoxes)]);
    sheet.appendRow([TextCellValue('Total Shortage'), IntCellValue(entry.totalShortage)]);

    final directory = await getTemporaryDirectory();
    final filePath = '${directory.path}/Transport_Report_${entry.vehicleNumber}_${DateTime.now().millisecondsSinceEpoch}.xlsx';
    final file = File(filePath);
    await file.writeAsBytes(excel.save()!);

    await Share.shareXFiles([XFile(filePath)], text: 'Transport Excel Report - ${entry.vehicleNumber}');
  }

  // 3. Image Export
  static Future<void> shareImage(File imageFile, String vehicleNumber) async {
    await Share.shareXFiles([XFile(imageFile.path)], text: 'Transport Slip - $vehicleNumber');
  }

  // PRO FIX: Image ko compress karke RAM bachane wala function
  static Future<List<pw.MemoryImage>> _loadImages(List<String> paths) async {
    List<pw.MemoryImage> images = [];
    for (var path in paths) {
      final file = File(path);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        final decodedImage = img.decodeImage(bytes);
        if (decodedImage != null) {
          final resized = img.copyResize(decodedImage, width: 800);
          final compressedBytes = img.encodeJpg(resized, quality: 70);
          images.add(pw.MemoryImage(compressedBytes));
        }
      }
    }
    return images;
  }

  // 4. PDF Export (Advanced & Modern)
  static Future<void> exportToPdf(VehicleEntry entry) async {
    final pdf = pw.Document();
    final activeBoxes = entry.boxes.where((b) => !b.isDeleted && b.consignmentNo.isNotEmpty).toList();

    // Get main route for the advanced summary
    String mainRoute = "N/A";
    if (activeBoxes.isNotEmpty && activeBoxes.first.sourceLocation.isNotEmpty) {
      mainRoute = "${activeBoxes.first.sourceLocation} To ${activeBoxes.first.destinationLocation}";
    }

    // Page 1: Main Report with Header & Footer
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(30),
        header: (pw.Context context) => pw.Container(
            padding: const pw.EdgeInsets.only(bottom: 10),
            decoration: const pw.BoxDecoration(
                border: pw.Border(bottom: pw.BorderSide(color: PdfColors.deepOrange, width: 2))
            ),
            child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('LT Operations', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.deepOrange)),
                  pw.Text('Transport Report', style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey)),
                ]
            )
        ),
        footer: (pw.Context context) => pw.Container(
            alignment: pw.Alignment.center,
            child: pw.Text('Page ${context.pageNumber} of ${context.pagesCount} | Generated on ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey))
        ),
        build: (pw.Context context) {
          return [
            // Vehicle Details Section
            pw.Container(
                padding: const pw.EdgeInsets.all(15),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Vehicle: ${entry.vehicleNumber}', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
                      pw.SizedBox(height: 5),
                      pw.Text('Driver: ${entry.driverName} (${entry.driverMobile})', style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey800)),
                      pw.SizedBox(height: 5),
                      pw.Container(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: pw.BoxDecoration(
                            color: PdfColors.deepOrange,
                            borderRadius: pw.BorderRadius.circular(20),
                          ),
                          child: pw.Text('${entry.vehicleStatus} | Gate: ${entry.gateNumber}', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 10))
                      )
                    ]
                )
            ),
            pw.SizedBox(height: 10),

            // Route Section
            pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.deepOrange, width: 1.5),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Center(
                  child: pw.Text('Main Route: $mainRoute', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.deepOrange)),
                )
            ),
            pw.SizedBox(height: 15),

            // Summary Grid
            pw.Row(
                children: [
                  _buildPdfMetricBox('Total Boxes', entry.totalReceivedBoxes.toString(), PdfColors.blue),
                  pw.SizedBox(width: 10),
                  _buildPdfMetricBox('Shortage', entry.totalShortage.toString(), PdfColors.red),
                  pw.SizedBox(width: 10),
                  _buildPdfMetricBox('Damaged', entry.totalDamaged.toString(), PdfColors.orange),
                ]
            ),
            pw.SizedBox(height: 20),

            // Table
            pw.Text('Consignment Details', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.deepOrange)),
            pw.SizedBox(height: 10),
            pw.TableHelper.fromTextArray(
              context: context,
              data: <List<String>>[
                ['Docket', 'Company', 'Route', 'Exp', 'Recv', 'Short', 'Mode'],
                ...activeBoxes.map((box) {
                  final shortage = box.shortage;
                  return [
                    box.consignmentNo,
                    box.companyName,
                    '${box.sourceLocation} To ${box.destinationLocation}',
                    box.expectedBoxes.toString(),
                    box.receivedBoxes.toString(),
                    shortage == 0 ? '0' : (shortage > 0 ? 'S:$shortage' : 'E:${-shortage}'),
                    box.transportMode
                  ];
                })
              ],
              border: pw.TableBorder.all(color: PdfColors.grey300),
              headerStyle: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.deepOrange),
              cellStyle: const pw.TextStyle(fontSize: 9),
              cellAlignments: {
                3: pw.Alignment.center, 4: pw.Alignment.center, 5: pw.Alignment.center, 6: pw.Alignment.center
              },
            ),
          ];
        },
      ),
    );

    // Page 2: Start Photos
    if (entry.startPhotos.isNotEmpty) {
      final startImages = await _loadImages(entry.startPhotos);
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(30),
          build: (pw.Context context) {
            List<pw.Widget> widgets = [];
            widgets.add(pw.Header(level: 1, text: 'Start Photos', textStyle: const pw.TextStyle(color: PdfColors.deepOrange, fontSize: 20)));
            widgets.add(pw.SizedBox(height: 10));
            for (var img in startImages) {
              widgets.add(pw.Center(child: pw.Image(img, width: 400, height: 300, fit: pw.BoxFit.contain)));
              widgets.add(pw.SizedBox(height: 20));
            }
            return widgets;
          },
        ),
      );
    }

    // Page 3: End Photos
    if (entry.endPhotos.isNotEmpty) {
      final endImages = await _loadImages(entry.endPhotos);
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(30),
          build: (pw.Context context) {
            List<pw.Widget> widgets = [];
            widgets.add(pw.Header(level: 1, text: 'End Photos', textStyle: const pw.TextStyle(color: PdfColors.green, fontSize: 20)));
            widgets.add(pw.SizedBox(height: 10));
            for (var img in endImages) {
              widgets.add(pw.Center(child: pw.Image(img, width: 400, height: 300, fit: pw.BoxFit.contain)));
              widgets.add(pw.SizedBox(height: 20));
            }
            return widgets;
          },
        ),
      );
    }

    // Page 4: Damage Photos
    bool hasDamagePhotos = activeBoxes.any((b) => b.isDamaged && b.damagePhotos.isNotEmpty);
    if (hasDamagePhotos) {
      Map<String, List<pw.MemoryImage>> boxDamageImages = {};
      for (var box in activeBoxes.where((b) => b.isDamaged && b.damagePhotos.isNotEmpty)) {
        boxDamageImages[box.consignmentNo] = await _loadImages(box.damagePhotos);
      }

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(30),
          build: (pw.Context context) {
            List<pw.Widget> widgets = [];
            widgets.add(pw.Header(level: 1, text: 'Damage Proof Photos', textStyle: const pw.TextStyle(color: PdfColors.red, fontSize: 20)));
            widgets.add(pw.SizedBox(height: 10));

            for (var box in activeBoxes.where((b) => b.isDamaged && b.damagePhotos.isNotEmpty)) {
              final damageImages = boxDamageImages[box.consignmentNo] ?? [];
              int imgIndex = 0;

              for (var _ in box.damagePhotos) {
                if (imgIndex < damageImages.length) {
                  widgets.add(pw.Center(child: pw.Image(damageImages[imgIndex], width: 400, height: 300, fit: pw.BoxFit.contain)));
                  widgets.add(pw.SizedBox(height: 5));
                  widgets.add(pw.Center(child: pw.Text('Docket: ${box.consignmentNo} | Details: ${box.damageDetails}', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold))));
                  widgets.add(pw.SizedBox(height: 20));
                  imgIndex++;
                }
              }
            }
            return widgets;
          },
        ),
      );
    }

    final directory = await getTemporaryDirectory();
    final filePath = '${directory.path}/LT_Operations_Report_${entry.vehicleNumber}.pdf';
    final file = File(filePath);
    await file.writeAsBytes(await pdf.save());

    await Share.shareXFiles([XFile(filePath)], text: 'Transport PDF Report - ${entry.vehicleNumber}');
  }

  // Helper for PDF Metric Box
  static pw.Widget _buildPdfMetricBox(String title, String value, PdfColor color) {
    return pw.Expanded(
        child: pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.circular(8),
              border: pw.Border.all(color: color, width: 1),
            ),
            child: pw.Column(
                children: [
                  pw.Text(value, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: color)),
                  pw.SizedBox(height: 4),
                  pw.Text(title, style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700, fontWeight: pw.FontWeight.bold)),
                ]
            )
        )
    );
  }
}