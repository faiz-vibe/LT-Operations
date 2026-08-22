import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/vehicle_entry.dart';

class GoogleSyncService {
  // Aapka Google Apps Script Web App URL
  static const String _scriptUrl = 'https://script.google.com/macros/s/AKfycbwpT1pLgykTzrsYpyJHlFb_D5Es-m5iZ2k_pRg8zLiG1bIaEkbTYChusFbG8pp-_s4/exec';

  static Future<bool> syncToSheet(VehicleEntry entry) async {
    try {
      final activeBoxes = entry.boxes.where((b) => !b.isDeleted).toList();
      final totalDamaged = activeBoxes.fold(0, (sum, b) => sum + b.damagedCount);

      // Jo data bhejna hai wo prepare karein
      final Map<String, dynamic> payload = {
        'vehicleNumber': entry.vehicleNumber,
        'driverName': entry.driverName,
        'driverMobile': entry.driverMobile,
        'vehicleStatus': entry.vehicleStatus,
        'gateNumber': entry.gateNumber,
        'totalBoxes': entry.totalReceivedBoxes,
        'totalShortage': entry.totalShortage,
        'totalDamaged': totalDamaged,
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