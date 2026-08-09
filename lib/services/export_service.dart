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
}