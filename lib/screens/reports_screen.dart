import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/vehicle_entry.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Hive.box<VehicleEntry>('vehicle_entries').listenable(),
      builder: (context, Box<VehicleEntry> box, _) {
        final today = DateTime.now();
        final startOfDay = DateTime(today.year, today.month, today.day);

        final allEntries = box.values.where((e) => !e.isDeleted).toList();
        // Sirf aaj ki entries filter karein
        final todayEntries = allEntries.where((e) => e.entryDate.isAfter(startOfDay)).toList();

        // 1. Top Summary
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

        // 2. Gate-wise Summary
        Map<String, int> gateCounts = {};
        for (var e in todayEntries) {
          gateCounts[e.gateNumber] = (gateCounts[e.gateNumber] ?? 0) + 1;
        }

        // 3. Mode-wise Summary
        Map<String, int> modeCounts = {};
        for (var e in todayEntries) {
          for (var b in e.boxes.where((b) => !b.isDeleted)) {
            modeCounts[b.transportMode] = (modeCounts[b.transportMode] ?? 0) + b.receivedBoxes;
          }
        }

        // 4. Company-wise Breakdown
        Map<String, int> companyCounts = {};
        for (var e in todayEntries) {
          for (var b in e.boxes.where((b) => !b.isDeleted)) {
            companyCounts[b.companyName] = (companyCounts[b.companyName] ?? 0) + b.receivedBoxes;
          }
        }
        var sortedCompanies = companyCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

        // 5. Route Analysis
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

        // 6. Top Drivers
        Map<String, int> driverCounts = {};
        for (var e in todayEntries) {
          driverCounts[e.driverName] = (driverCounts[e.driverName] ?? 0) + 1;
        }
        var sortedDrivers = driverCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

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

              // Top Metric Cards
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.5,
                children: [
                  _buildMetricCard('Total Vehicles', totalVehicles.toString(), Colors.blue),
                  _buildMetricCard('Total Boxes', totalBoxes.toString(), Colors.indigo),
                  _buildMetricCard('Shortage', totalShortage.toString(), Colors.red),
                  _buildMetricCard('Extra', totalExtra.toString(), Colors.purple),
                  _buildMetricCard('Damaged', totalDamaged.toString(), Colors.orange),
                  _buildMetricCard('Pending Drafts', pendingDrafts.toString(), Colors.grey),
                ],
              ),
              const SizedBox(height: 24),

              // Stats Row
              _buildSectionCard(
                title: 'Key Statistics',
                children: [
                  _buildStatRow('Loading vs Unloading', '$loadingCount L / $unloadingCount U'),
                  _buildStatRow('Shortage Percentage', '${shortagePercent.toStringAsFixed(1)}%'),
                  _buildStatRow('Avg Boxes / Vehicle', avgBoxes.toStringAsFixed(1)),
                ],
              ),
              const SizedBox(height: 16),

              // Gate-wise
              _buildSectionCard(
                title: 'Gate-wise Summary (Today)',
                children: gateCounts.isEmpty
                    ? [const Text('No data')]
                    : gateCounts.entries.map((e) => _buildStatRow(e.key, '${e.value} Vehicles')).toList(),
              ),
              const SizedBox(height: 16),

              // Mode-wise
              _buildSectionCard(
                title: 'Transport Mode (Boxes)',
                children: modeCounts.isEmpty
                    ? [const Text('No data')]
                    : modeCounts.entries.map((e) => _buildStatRow(e.key, '${e.value} Boxes')).toList(),
              ),
              const SizedBox(height: 16),

              // Company-wise
              _buildSectionCard(
                title: 'Top Companies (Boxes)',
                children: sortedCompanies.isEmpty
                    ? [const Text('No data')]
                    : sortedCompanies.take(5).map((e) => _buildStatRow(e.key, '${e.value} Boxes')).toList(),
              ),
              const SizedBox(height: 16),

              // Route Analysis
              _buildSectionCard(
                title: 'Top Routes (Boxes)',
                children: sortedRoutes.isEmpty
                    ? [const Text('No data')]
                    : sortedRoutes.take(5).map((e) => _buildStatRow(e.key, '${e.value} Boxes')).toList(),
              ),
              const SizedBox(height: 16),

              // Top Drivers
              _buildSectionCard(
                title: 'Top Drivers (Trips)',
                children: sortedDrivers.isEmpty
                    ? [const Text('No data')]
                    : sortedDrivers.take(5).map((e) => _buildStatRow(e.key, '${e.value} Trips')).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  // Helper Widgets
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