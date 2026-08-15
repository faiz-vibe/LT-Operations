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

    // Headers (Wrapped in TextCellValue)
    sheet.appendRow([TextCellValue('Vehicle Number'), TextCellValue(entry.vehicleNumber)]);
    sheet.appendRow([TextCellValue('Driver Name'), TextCellValue(entry.driverName)]);
    sheet.appendRow([TextCellValue('Driver Mobile'), TextCellValue(entry.driverMobile)]);
    sheet.appendRow([TextCellValue('Status'), TextCellValue('${entry.vehicleStatus} | ${entry.gateNumber}')]);
    sheet.appendRow([TextCellValue('Date'), TextCellValue('${entry.entryDate.day}/${entry.entryDate.month}/${entry.entryDate.year}')]);
    sheet.appendRow([]); // Empty row

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

    // File save karein
    final directory = await getTemporaryDirectory();
    final filePath = '${directory.path}/Transport_Report_${entry.vehicleNumber}_${DateTime.now().millisecondsSinceEpoch}.xlsx';
    final file = File(filePath);
    await file.writeAsBytes(excel.save()!);

    // Share karein
    await Share.shareXFiles([XFile(filePath)], text: 'Transport Excel Report - ${entry.vehicleNumber}');
  }

  // 3. Image Export
  static Future<void> shareImage(File imageFile, String vehicleNumber) async {
    await Share.shareXFiles([XFile(imageFile.path)], text: 'Transport Slip - $vehicleNumber');
  }

  // 4. PDF Export (Modern & High Quality)
  static Future<void> exportToPdf(VehicleEntry entry) async {
    final pdf = pw.Document();
    final activeBoxes = entry.boxes.where((b) => !b.isDeleted && b.consignmentNo.isNotEmpty).toList();

    // Page 1: Vehicle Details aur Table
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        build: (pw.Context context) {
          return [
            // Header
            pw.Container(
                width: double.infinity,
                color: PdfColors.blue800,
                padding: const pw.EdgeInsets.all(20),
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
            // Vehicle Info
            pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(entry.vehicleNumber, style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 4),
                        pw.Text('Driver: ${entry.driverName}', style: pw.TextStyle(fontSize: 14, color: PdfColors.black)),
                        pw.Text('Mobile: ${entry.driverMobile}', style: pw.TextStyle(fontSize: 12, color: PdfColors.grey)),
                      ]
                  ),
                  pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: pw.BoxDecoration(
                        color: entry.vehicleStatus == 'Loading' ? PdfColors.blue100 : PdfColors.orange100,
                        borderRadius: pw.BorderRadius.circular(8),
                      ),
                      child: pw.Text('${entry.vehicleStatus} | ${entry.gateNumber}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: entry.vehicleStatus == 'Loading' ? PdfColors.blue800 : PdfColors.orange800))
                  )
                ]
            ),
            pw.SizedBox(height: 20),
            // Table
            pw.Table.fromTextArray(
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
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blue800),
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

    // Page 2: Damage Photos (High Quality, No Compression)
    bool hasDamagePhotos = activeBoxes.any((b) => b.isDamaged && b.damagePhotos.isNotEmpty);
    if (hasDamagePhotos) {
      // Pehle saari images ko memory me load karein (High Quality)
      List<pw.MemoryImage> pdfImages = [];
      for (var box in activeBoxes.where((b) => b.isDamaged && b.damagePhotos.isNotEmpty)) {
        for (var path in box.damagePhotos) {
          final imageFile = File(path);
          if (await imageFile.exists()) {
            final bytes = await imageFile.readAsBytes();
            pdfImages.add(pw.MemoryImage(bytes));
          }
        }
      }

      // Photos ke liye naya page banayein
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          build: (pw.Context context) {
            List<pw.Widget> widgets = [];
            widgets.add(pw.Header(level: 1, text: 'Damage Proof Photos', textStyle: pw.TextStyle(color: PdfColors.red, fontSize: 20)));
            widgets.add(pw.SizedBox(height: 10));

            int imgIndex = 0;
            for (var box in activeBoxes.where((b) => b.isDamaged && b.damagePhotos.isNotEmpty)) {
              for (var path in box.damagePhotos) {
                if (imgIndex < pdfImages.length) {
                  // Image ko bada aur clear dikhane ke liye
                  widgets.add(pw.Center(
                      child: pw.Image(
                        pdfImages[imgIndex],
                        width: 400,
                        height: 350,
                        fit: pw.BoxFit.contain,
                      )
                  ));

                  // Consignment Number image ke just niche (Center me)
                  widgets.add(pw.SizedBox(height: 5));
                  widgets.add(pw.Center(
                      child: pw.Text(
                          'Consignment: ${box.consignmentNo}',
                          style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)
                      )
                  ));

                  // Damage Details bhi consignment number ke niche (Center me)
                  if (box.damageDetails.isNotEmpty) {
                    widgets.add(pw.Center(
                        child: pw.Text(
                            'Details: ${box.damageDetails}',
                            style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700)
                        )
                    ));
                  }

                  widgets.add(pw.SizedBox(height: 20)); // Agale image se space ke liye
                  imgIndex++;
                }
              }
            }

            return widgets;
          },
        ),
      );
    }

    // PDF File Save aur Share karein
    final directory = await getTemporaryDirectory();
    final filePath = '${directory.path}/LT_Operations_Report_${entry.vehicleNumber}.pdf';
    final file = File(filePath);
    await file.writeAsBytes(await pdf.save());

    await Share.shareXFiles([XFile(filePath)], text: 'Transport PDF Report - ${entry.vehicleNumber}');
  }
}