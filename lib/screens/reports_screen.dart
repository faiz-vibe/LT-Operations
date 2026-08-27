import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/vehicle_entry.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  // PRO FIX: Saari heavy calculations build method se bahar nikal di
  Map<String, dynamic> _calculateStats(Box<VehicleEntry> box) {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);

    final allEntries = box.values.where((e) => !e.isDeleted).toList();
    final todayEntries = allEntries.where((e) => e.entryDate.isAfter(startOfDay)).toList();

    int totalVehicles = todayEntries.length;
    int totalBoxes = todayEntries.fold(0, (sum, e) => sum + e.totalReceivedBoxes);
    int totalShortage = todayEntries.fold(0, (sum, e) => sum + e.totalShortage);
    int totalExtra = todayEntries.fold(0, (sum, e) => sum + e.totalExtra);
    int totalDamaged = todayEntries.fold(0, (sum, e) => sum + e.totalDamaged);
    int totalExpected = todayEntries.fold(0, (sum, e) => sum + e.boxes.where((b) => !b.isDeleted).fold(0, (s, b) => s + b.expectedBoxes));

    double shortagePercent = totalExpected > 0 ? (totalShortage / totalExpected) * 100 : 0;
    double avgBoxes = totalVehicles > 0 ? totalBoxes / totalVehicles : 0;
    int loadingCount = todayEntries.where((e) => e.vehicleStatus == 'Loading').length;
    int unloadingCount = todayEntries.where((e) => e.vehicleStatus == 'Unloading').length;
    int pendingDrafts = allEntries.where((e) => !e.isCompleted).length;

    Map<String, int> gateCounts = {};
    for (var e in todayEntries) {
      gateCounts[e.gateNumber] = (gateCounts[e.gateNumber] ?? 0) + 1;
    }

    Map<String, int> modeCounts = {};
    for (var e in todayEntries) {
      for (var b in e.boxes.where((b) => !b.isDeleted)) {
        modeCounts[b.transportMode] = (modeCounts[b.transportMode] ?? 0) + b.receivedBoxes;
      }
    }

    Map<String, int> companyCounts = {};
    for (var e in todayEntries) {
      for (var b in e.boxes.where((b) => !b.isDeleted)) {
        companyCounts[b.companyName] = (companyCounts[b.companyName] ?? 0) + b.receivedBoxes;
      }
    }
    var sortedCompanies = companyCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    Map<String, int> routeCounts = {};
    for (var e in todayEntries) {
      for (var b in e.boxes.where((b) => !b.isDeleted)) {
        if(b.sourceLocation.isNotEmpty || b.destinationLocation.isNotEmpty) {
          String route = "${b.sourceLocation} To ${b.destinationLocation}";
          routeCounts[route] = (routeCounts[route] ?? 0) + b.receivedBoxes;
        }
      }
    }
    var sortedRoutes = routeCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    Map<String, int> driverCounts = {};
    for (var e in todayEntries) {
      driverCounts[e.driverName] = (driverCounts[e.driverName] ?? 0) + 1;
    }
    var sortedDrivers = driverCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return {
      'totalVehicles': totalVehicles,
      'totalBoxes': totalBoxes,
      'totalShortage': totalShortage,
      'totalExtra': totalExtra,
      'totalDamaged': totalDamaged,
      'shortagePercent': shortagePercent,
      'avgBoxes': avgBoxes,
      'loadingCount': loadingCount,
      'unloadingCount': unloadingCount,
      'pendingDrafts': pendingDrafts,
      'gateCounts': gateCounts,
      'modeCounts': modeCounts,
      'sortedCompanies': sortedCompanies,
      'sortedRoutes': sortedRoutes,
      'sortedDrivers': sortedDrivers,
    };
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Hive.box<VehicleEntry>('vehicle_entries').listenable(),
      builder: (context, Box<VehicleEntry> box, _) {

        // Calculations yahan honge, UI build karne se pehle
        final stats = _calculateStats(box);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Reports & Analytics', style: TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: Colors.blue[800],
            foregroundColor: Colors.white,
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text('Today\'s Summary', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
              const SizedBox(height: 16),

              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.5,
                children: [
                  _buildMetricCard('Total Vehicles', stats['totalVehicles'].toString(), Colors.blue),
                  _buildMetricCard('Total Boxes', stats['totalBoxes'].toString(), Colors.indigo),
                  _buildMetricCard('Shortage', stats['totalShortage'].toString(), Colors.red),
                  _buildMetricCard('Extra', stats['totalExtra'].toString(), Colors.purple),
                  _buildMetricCard('Damaged', stats['totalDamaged'].toString(), Colors.orange),
                  _buildMetricCard('Pending Drafts', stats['pendingDrafts'].toString(), Colors.grey),
                ],
              ),
              const SizedBox(height: 24),

              _buildSectionCard(
                title: 'Key Statistics',
                children: [
                  _buildStatRow('Loading vs Unloading', '${stats['loadingCount']} L / ${stats['unloadingCount']} U'),
                  _buildStatRow('Shortage Percentage', '${(stats['shortagePercent'] as double).toStringAsFixed(1)}%'),
                  _buildStatRow('Avg Boxes / Vehicle', (stats['avgBoxes'] as double).toStringAsFixed(1)),
                ],
              ),
              const SizedBox(height: 16),

              _buildSectionCard(
                title: 'Gate-wise Summary (Today)',
                children: (stats['gateCounts'] as Map<String, int>).isEmpty
                    ? [const Text('No data')]
                    : (stats['gateCounts'] as Map<String, int>).entries.map((e) => _buildStatRow(e.key, '${e.value} Vehicles')).toList(),
              ),
              const SizedBox(height: 16),

              _buildSectionCard(
                title: 'Transport Mode (Boxes)',
                children: (stats['modeCounts'] as Map<String, int>).isEmpty
                    ? [const Text('No data')]
                    : (stats['modeCounts'] as Map<String, int>).entries.map((e) => _buildStatRow(e.key, '${e.value} Boxes')).toList(),
              ),
              const SizedBox(height: 16),

              _buildSectionCard(
                title: 'Top Companies (Boxes)',
                children: (stats['sortedCompanies'] as List).isEmpty
                    ? [const Text('No data')]
                    : (stats['sortedCompanies'] as List).take(5).map((e) => _buildStatRow(e.key, '${e.value} Boxes')).toList(),
              ),
              const SizedBox(height: 16),

              _buildSectionCard(
                title: 'Top Routes (Boxes)',
                children: (stats['sortedRoutes'] as List).isEmpty
                    ? [const Text('No data')]
                    : (stats['sortedRoutes'] as List).take(5).map((e) => _buildStatRow(e.key, '${e.value} Boxes')).toList(),
              ),
              const SizedBox(height: 16),

              _buildSectionCard(
                title: 'Top Drivers (Trips)',
                children: (stats['sortedDrivers'] as List).isEmpty
                    ? [const Text('No data')]
                    : (stats['sortedDrivers'] as List).take(5).map((e) => _buildStatRow(e.key, '${e.value} Trips')).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMetricCard(String title, String value, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.5)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(title, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.grey[700], fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({required String title, required List<Widget> children}) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
            const Divider(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, color: Colors.black87)),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black)),
        ],
      ),
    );
  }
}