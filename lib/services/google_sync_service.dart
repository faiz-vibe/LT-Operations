import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/vehicle_entry.dart';

class GoogleSyncService {
  static const String _scriptUrl = 'https://script.google.com/macros/s/AKfycbwpT1pLgykTzrsYpyJHlFb_D5Es-m5iZ2k_pRg8zLiG1bIaEkbTYChusFbG8pp-_s4/exec';

  static Future<bool> syncToSheet(VehicleEntry entry) async {
    try {
      final activeBoxes = entry.boxes.where((b) => !b.isDeleted && b.consignmentNo.isNotEmpty).toList();

      // Har box ki detail JSON me convert karein
      List<Map<String, dynamic>> boxesJson = activeBoxes.map((box) {
        return {
          'consignmentNo': box.consignmentNo,
          'companyName': box.companyName,
          'sourceLocation': box.sourceLocation,
          'destinationLocation': box.destinationLocation,
          'expectedBoxes': box.expectedBoxes,
          'receivedBoxes': box.receivedBoxes,
          'shortage': box.shortage,
          'transportMode': box.transportMode,
        };
      }).toList();

      // Pur data payload ready karein
      final Map<String, dynamic> payload = {
        'vehicleNumber': entry.vehicleNumber,
        'driverName': entry.driverName,
        'driverMobile': entry.driverMobile,
        'vehicleStatus': entry.vehicleStatus,
        'gateNumber': entry.gateNumber,
        'dateTime': '${entry.entryDate.day}/${entry.entryDate.month}/${entry.entryDate.year} ${entry.entryDate.hour.toString().padLeft(2, '0')}:${entry.entryDate.minute.toString().padLeft(2, '0')}',
        'totalBoxes': entry.totalReceivedBoxes,
        'totalShortage': entry.totalShortage,
        'boxes': boxesJson, // Yahan saari boxes ki list jayegi
      };

      // Google Sheet ko data bhejein
      final response = await http.post(
        Uri.parse(_scriptUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        return true; // Sync successful
      } else {
        return false; // Sync failed
      }
    } catch (e) {
      print('Google Sync Error: $e');
      return false;
    }
  }
}