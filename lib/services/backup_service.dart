import 'dart:convert';
import 'dart:io';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../models/vehicle_entry.dart';

class BackupService {
  Future<void> exportData() async {
    final box = Hive.box<VehicleEntry>('vehicle_entries');
    final List<Map<String, dynamic>> jsonData = box.values.map((e) => e.toJson()).toList();

    final now = DateTime.now();
    final String fileName = "Transport_Backup_${now.day}_${now.month}_${now.year}_${now.hour}_${now.minute}_${now.second}.json";

    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/$fileName');
    await file.writeAsString(jsonEncode(jsonData));

    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Transport Supervisor App Backup File',
    );
  }

  Future<void> importData(BuildContext context) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final jsonString = await file.readAsString();
        final List<dynamic> jsonList = jsonDecode(jsonString);

        // PRO FIX: Pehle saara data ek temporary list me load aur parse karo
        final List<VehicleEntry> parsedEntries = [];
        for (var item in jsonList) {
          final entry = VehicleEntry.fromJson(item as Map<String, dynamic>);
          parsedEntries.add(entry);
        }

        // Agar parsing 100% successful raha, tabhi purana data delete karo
        final box = Hive.box<VehicleEntry>('vehicle_entries');
        await box.clear();

        // Naya data add karo
        await box.addAll(parsedEntries);

        if (!context.mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Backup successfully imported!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Import failed: $e'), backgroundColor: Colors.red),
      );
    }
  }
}