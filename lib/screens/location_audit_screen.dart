import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/vehicle_entry.dart';
import '../models/box_item.dart';

class LocationAuditScreen extends StatefulWidget {
  const LocationAuditScreen({super.key});

  @override
  State<LocationAuditScreen> createState() => _LocationAuditScreenState();
}

class _LocationAuditScreenState extends State<LocationAuditScreen> {
  String? _selectedZone;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedZone == null ? 'Location & Audit' : 'Zone $_selectedZone Details'),
        backgroundColor: const Color(0xFFD84315),
        foregroundColor: Colors.white,
      ),
      body: _selectedZone == null ? _buildGridMap() : _buildZoneList(_selectedZone!),
    );
  }

  Widget _buildGridMap() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(flex: 1, child: Column(children: List.generate(6, (index) => Expanded(flex: 1, child: Padding(padding: const EdgeInsets.all(4.0), child: _buildGridItem('Z${index + 1}')))))),
          Expanded(flex: 1, child: Column(children: [
            ...List.generate(4, (index) => Expanded(flex: 1, child: Padding(padding: const EdgeInsets.all(4.0), child: _buildGridItem('Z${index + 7}')))),
            Expanded(flex: 2, child: Padding(padding: const EdgeInsets.all(4.0), child: _buildGridItem('Z11'))),
          ])),
          Expanded(flex: 1, child: Column(children: List.generate(6, (index) => Expanded(flex: 1, child: Padding(padding: const EdgeInsets.all(4.0), child: _buildGridItem('Z${index + 12}')))))),
        ],
      ),
    );
  }

  Widget _buildGridItem(String zoneName) {
    final zoneBox = Hive.box<String>('zone_mapping');
    // Count active boxes in this zone
    final vehicleBox = Hive.box<VehicleEntry>('vehicle_entries');
    int count = 0;
    for (var entry in vehicleBox.values) {
      if (entry.isCompleted || entry.isDeleted) continue;
      for (var box in entry.boxes) {
        if (zoneBox.get(box.consignmentNo) == zoneName) count++;
      }
    }

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFD84315),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 2,
      ),
      onPressed: () => setState(() => _selectedZone = zoneName),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(zoneName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          if (count > 0) Text('$count parcels', style: const TextStyle(fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildZoneList(String zoneName) {
    final zoneBox = Hive.box<String>('zone_mapping');
    return ValueListenableBuilder(
      valueListenable: Hive.box<VehicleEntry>('vehicle_entries').listenable(),
      builder: (context, Box<VehicleEntry> vehicleBox, _) {
        List<Map<String, dynamic>> docketsInZone = [];

        for (var entry in vehicleBox.values) {
          if (entry.isCompleted || entry.isDeleted) continue; // Skip dispatched or deleted vehicles
          for (var box in entry.boxes) {
            if (box.isDeleted) continue;
            if (zoneBox.get(box.consignmentNo) == zoneName) {
              docketsInZone.add({
                'docket': box.consignmentNo,
                'company': box.companyName,
                'route': '${box.sourceLocation} To ${box.destinationLocation}',
                'boxes': box.receivedBoxes,
                'mode': box.transportMode,
                'vehicle': entry.vehicleNumber,
                'date': '${entry.entryDate.day}/${entry.entryDate.month}/${entry.entryDate.year}',
              });
            }
          }
        }

        if (docketsInZone.isEmpty) {
          return Center(child: Text('No parcels in Zone $zoneName', style: const TextStyle(color: Colors.grey)));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docketsInZone.length,
          itemBuilder: (context, index) {
            final d = docketsInZone[index];
            return Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                title: Text(d['docket'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text('Company: ${d['company']}'),
                    Text('Route: ${d['route']}'),
                    Text('Total Boxes: ${d['boxes']} | Mode: ${d['mode']}'),
                    const Divider(),
                    Text('Vehicle: ${d['vehicle']}', style: const TextStyle(color: const Color(0xFFD84315), fontWeight: FontWeight.bold)),
                    Text('Entry Date: ${d['date']}', style: const TextStyle(color: Colors.grey, fontSize: 10)),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () {
                    zoneBox.delete(d['docket']);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${d['docket']} removed from zone')));
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
}