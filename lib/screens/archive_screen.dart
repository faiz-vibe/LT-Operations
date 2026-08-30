import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/vehicle_entry.dart';

class ArchiveScreen extends StatelessWidget {
  const ArchiveScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Hive.box<VehicleEntry>('vehicle_entries').listenable(),
      builder: (context, Box<VehicleEntry> box, _) {
        final archiveBox = Hive.box<String>('archive_box');

        // Sirf un vehicles ko dikhao jo archive me hain aur delete nahi hue hain
        final archivedEntries = box.values.where((e) => archiveBox.containsKey(e.key.toString()) && !e.isDeleted).toList().reversed.toList();

        return Scaffold(
          appBar: AppBar(
            title: const Text('Archived Vehicles'),
            backgroundColor: const Color(0xFFD84315), // Corporate Orange
            foregroundColor: Colors.white,
          ),
          body: archivedEntries.isEmpty
              ? const Center(child: Text('Koi archived vehicle nahi hai.', style: TextStyle(color: Colors.grey)))
              : ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: archivedEntries.length,
            itemBuilder: (context, index) {
              final entry = archivedEntries[index];
              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  title: Text(entry.vehicleNumber, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  subtitle: Text('Driver: ${entry.driverName}\nBoxes: ${entry.totalReceivedBoxes}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.restore, color: Colors.green),
                    tooltip: 'Restore',
                    onPressed: () {
                      archiveBox.delete(entry.key.toString());
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${entry.vehicleNumber} wapas restore ho gaya!')),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}