import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/vehicle_entry.dart';

class ExportService {
  // 1. WhatsApp Export
  static Future<void> exportToWhatsApp(VehicleEntry entry) async {
    final activeBoxes = entry.boxes.where((b) => !b.isDeleted).toList();

    String message = "*Transport Supervisor Report*\n\n";
    message += "Vehicle: ${entry.vehicleNumber}\n";
    message += "Driver: ${entry.driverName} (${entry.driverMobile})\n";
    message += "Status: ${entry.vehicleStatus} | Gate: ${entry.gateNumber}\n";
    message += "Date: ${entry.entryDate.day}/${entry.entryDate.month}/${entry.entryDate.year}\n";
    message += "----------------------------------\n";

    for (var box in activeBoxes) {
      message += "Consignment: ${box.consignmentNo}\n";
      message += "Company: ${box.companyName}\n";
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

  // Helper: Images load karne ke liye
  static Future<List<pw.MemoryImage>> _loadImages(List<String> paths) async {
    List<pw.MemoryImage> images = [];
    for (var path in paths) {
      final file = File(path);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        images.add(pw.MemoryImage(bytes));
      }
    }
    return images;
  }

  // 4. PDF Export (Modern & High Quality with All Photos)
  static Future<void> exportToPdf(VehicleEntry entry) async {
    final pdf = pw.Document();
    final activeBoxes = entry.boxes.where((b) => !b.isDeleted && b.consignmentNo.isNotEmpty).toList();

    // Page 1: Vehicle Details aur Table
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(20),
        build: (pw.Context context) {
          return [
            pw.Container(
                width: double.infinity,
                color: PdfColors.blue800,
                padding: pw.EdgeInsets.all(20),
                child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('LT Operations', style: pw.TextStyle(color: PdfColors.white, fontSize: 24, fontWeight: pw.FontWeight.bold)),
                      pw.Text('Transport Supervisor Report', style: pw.TextStyle(color: PdfColors.white, fontSize: 14)),
                      pw.SizedBox(height: 10),
                      pw.Text('Generated: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}  ${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}', style: pw.TextStyle(color: PdfColors.white, fontSize: 12)),
                    ]
                )
            ),
            pw.SizedBox(height: 20),
            // Naya: Infographic Summary Section
            pw.Container(
                padding: pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Vehicle Summary', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
                      pw.SizedBox(height: 10),
                      pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                          children: [
                            // Total Boxes (Blue)
                            pw.Container(
                                padding: pw.EdgeInsets.all(8),
                                decoration: pw.BoxDecoration(color: PdfColors.blue100, borderRadius: pw.BorderRadius.circular(5)),
                                child: pw.Column(
                                    children: [
                                      pw.Text('Total Boxes', style: pw.TextStyle(fontSize: 10, color: PdfColors.blue800)),
                                      pw.Text(entry.totalReceivedBoxes.toString(), style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
                                    ]
                                )
                            ),
                            // Total Shortage (Orange)
                            pw.Container(
                                padding: pw.EdgeInsets.all(8),
                                decoration: pw.BoxDecoration(color: PdfColors.orange100, borderRadius: pw.BorderRadius.circular(5)),
                                child: pw.Column(
                                    children: [
                                      pw.Text('Shortage', style: pw.TextStyle(fontSize: 10, color: PdfColors.orange800)),
                                      pw.Text(entry.totalShortage.toString(), style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.orange800)),
                                    ]
                                )
                            ),
                            // Total Extra (Purple)
                            pw.Container(
                                padding: pw.EdgeInsets.all(8),
                                decoration: pw.BoxDecoration(color: PdfColors.purple100, borderRadius: pw.BorderRadius.circular(5)),
                                child: pw.Column(
                                    children: [
                                      pw.Text('Extra', style: pw.TextStyle(fontSize: 10, color: PdfColors.purple800)),
                                      pw.Text(entry.totalExtra.toString(), style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.purple800)),
                                    ]
                                )
                            ),
                            // Total Damaged (Red)
                            pw.Container(
                                padding: pw.EdgeInsets.all(8),
                                decoration: pw.BoxDecoration(color: PdfColors.red100, borderRadius: pw.BorderRadius.circular(5)),
                                child: pw.Column(
                                    children: [
                                      pw.Text('Damaged', style: pw.TextStyle(fontSize: 10, color: PdfColors.red800)),
                                      pw.Text(entry.totalDamaged.toString(), style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.red800)),
                                    ]
                                )
                            ),
                          ]
                      )
                    ]
                )
            ),
            pw.SizedBox(height: 20),
            pw.SizedBox(height: 20),
            pw.TableHelper.fromTextArray(
              context: context,
              data: <List<String>>[
                ['Consignment', 'Company', 'Exp', 'Recv', 'Short/Extra', 'Mode'],
                ...activeBoxes.map((box) => [
                  box.consignmentNo,
                  box.companyName,
                  box.expectedBoxes.toString(),
                  box.receivedBoxes.toString(),
                  box.shortage == 0 ? '0' : (box.shortage > 0 ? 'Short: ${box.shortage}' : 'Extra: ${-box.shortage}'),
                  box.transportMode
                ])
              ],
              cellStyle: pw.TextStyle(fontSize: 10),
              headerStyle: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: pw.BoxDecoration(color: PdfColors.blue800),
              cellAlignments: {
                2: pw.Alignment.center,
                3: pw.Alignment.center,
                4: pw.Alignment.center,
                5: pw.Alignment.center,
              },
            ),
          ];
        },
      ),
    );

    // Page 2: Start Photos (Seal, Gate Open, Empty Vehicle)
    if (entry.startPhotos.isNotEmpty) {
      final startImages = await _loadImages(entry.startPhotos);
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.all(20),
          build: (pw.Context context) {
            List<pw.Widget> widgets = [];
            widgets.add(pw.Header(level: 1, text: 'Start Photos', textStyle: pw.TextStyle(color: PdfColors.blue800, fontSize: 20)));
            widgets.add(pw.SizedBox(height: 10));

            for (var img in startImages) {
              widgets.add(pw.Center(
                  child: pw.Image(img, width: 400, height: 350, fit: pw.BoxFit.contain)
              ));
              widgets.add(pw.SizedBox(height: 20));
            }
            return widgets;
          },
        ),
      );
    }

    // Page 3: End Photos (Empty Vehicle, Seal, Meter)
    if (entry.endPhotos.isNotEmpty) {
      final endImages = await _loadImages(entry.endPhotos);
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.all(20),
          build: (pw.Context context) {
            List<pw.Widget> widgets = [];
            widgets.add(pw.Header(level: 1, text: 'End Photos', textStyle: pw.TextStyle(color: PdfColors.green800, fontSize: 20)));
            widgets.add(pw.SizedBox(height: 10));

            for (var img in endImages) {
              widgets.add(pw.Center(
                  child: pw.Image(img, width: 400, height: 350, fit: pw.BoxFit.contain)
              ));
              widgets.add(pw.SizedBox(height: 20));
            }
            return widgets;
          },
        ),
      );
    }

    // Page 4: Damage Photos (High Quality, No Compression)
    bool hasDamagePhotos = activeBoxes.any((b) => b.isDamaged && b.damagePhotos.isNotEmpty);
    if (hasDamagePhotos) {
      Map<String, List<pw.MemoryImage>> boxDamageImages = {};
      for (var box in activeBoxes.where((b) => b.isDamaged && b.damagePhotos.isNotEmpty)) {
        boxDamageImages[box.consignmentNo] = await _loadImages(box.damagePhotos);
      }

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.all(20),
          build: (pw.Context context) {
            List<pw.Widget> widgets = [];
            widgets.add(pw.Header(level: 1, text: 'Damage Proof Photos', textStyle: pw.TextStyle(color: PdfColors.red, fontSize: 20)));
            widgets.add(pw.SizedBox(height: 10));

            for (var box in activeBoxes.where((b) => b.isDamaged && b.damagePhotos.isNotEmpty)) {
              final damageImages = boxDamageImages[box.consignmentNo] ?? [];
              int imgIndex = 0;

              for (var _ in box.damagePhotos) {
                if (imgIndex < damageImages.length) {
                  widgets.add(pw.Center(
                      child: pw.Image(
                        damageImages[imgIndex],
                        width: 400,
                        height: 350,
                        fit: pw.BoxFit.contain,
                      )
                  ));

                  widgets.add(pw.SizedBox(height: 5));
                  widgets.add(pw.Center(
                      child: pw.Text(
                          'Consignment: ${box.consignmentNo}',
                          style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)
                      )
                  ));

                  if (box.damageDetails.isNotEmpty) {
                    widgets.add(pw.Center(
                        child: pw.Text(
                            'Details: ${box.damageDetails}',
                            style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700)
                        )
                    ));
                  }

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

    // PDF File Save aur Share karenge
    final directory = await getTemporaryDirectory();
    final filePath = '${directory.path}/LT_Operations_Report_${entry.vehicleNumber}.pdf';
    final file = File(filePath);
    await file.writeAsBytes(await pdf.save());

    await Share.shareXFiles([XFile(filePath)], text: 'Transport PDF Report - ${entry.vehicleNumber}');
  }
}