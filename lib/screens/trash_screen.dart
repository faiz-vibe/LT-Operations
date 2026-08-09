import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/vehicle_entry.dart';

class TrashScreen extends StatelessWidget {
  const TrashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Hive.box<VehicleEntry>('vehicle_entries').listenable(),
      builder: (context, Box<VehicleEntry> box, _) {
        // Sirf un entries ko dikhaye jo delete hui hain
        final trashEntries = box.values.where((e) => e.isDeleted).toList().reversed.toList();

        return Scaffold(
          appBar: AppBar(
            title: const Text('Trash (Recycle Bin)', style: TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: Colors.grey[800],
            foregroundColor: Colors.white,
          ),
          body: trashEntries.isEmpty
              ? const Center(
            child: Text(
              'Trash khaali hai.\nKoi deleted item nahi hai.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          )
              : ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: trashEntries.length,
            itemBuilder: (context, index) {
              final entry = trashEntries[index];
              return Card(
                color: Colors.grey[200],
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  title: Text(
                    entry.vehicleNumber,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black54),
                  ),
                  subtitle: Text('Driver: ${entry.driverName}\nTotal Boxes: ${entry.totalReceivedBoxes}'),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Restore Button
                      IconButton(
                        icon: const Icon(Icons.restore, color: Colors.green),
                        tooltip: 'Restore',
                        onPressed: () {
                          entry.isDeleted = false; // Wapas active kar do
                          entry.save();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('${entry.vehicleNumber} successfully restored!')),
                          );
                        },
                      ),
                      // Permanent Delete Button
                      IconButton(
                        icon: const Icon(Icons.delete_forever, color: Colors.red),
                        tooltip: 'Delete Permanently',
                        onPressed: () {
                          // Pehle confirm kare
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Permanent Delete'),
                              content: Text('Are you sure? ${entry.vehicleNumber} permanently delete ho jayega aur isko wapas nahi laya ja sakta.'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Cancel'),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                  onPressed: () {
                                    entry.delete(); // Hive se hamesha ke liye delete kar do
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('${entry.vehicleNumber} permanently deleted!')),
                                    );
                                  },
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
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