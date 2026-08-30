import 'location_audit_screen.dart';
import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/vehicle_entry.dart';
import '../models/box_item.dart';
import 'vehicle_entry_screen.dart';
import 'consignment_screen.dart';
import 'barcode_scanner_screen.dart';
import 'trash_screen.dart';
import 'archive_screen.dart';
import 'sticker_generator_screen.dart';
import 'manage_suggestions_screen.dart';
import 'reports_screen.dart';
import '../services/backup_service.dart';
import '../services/export_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final FocusNode _searchFocusNode = FocusNode();
  Timer? _tatTimer;

  @override
  void initState() {
    super.initState();
    _tatTimer = Timer.periodic(const Duration(seconds: 60), (Timer t) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tatTimer?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  String _getTatDuration(DateTime entryDate) {
    final duration = DateTime.now().difference(entryDate);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return hours > 0 ? "${hours}h ${minutes}m" : "${minutes}m";
  }

  Future<void> _navigateToEntry({VehicleEntry? existingEntry}) async {
    _searchFocusNode.unfocus();
    await Navigator.push(context, MaterialPageRoute(builder: (context) => VehicleEntryScreen(existingEntry: existingEntry)));
    if (mounted) { _searchFocusNode.unfocus(); setState(() {}); }
  }

  Future<void> _navigateToConsignment(VehicleEntry entry) async {
    _searchFocusNode.unfocus();
    await Navigator.push(context, MaterialPageRoute(builder: (context) => ConsignmentScreen(vehicleEntry: entry)));
    if (mounted) { _searchFocusNode.unfocus(); setState(() {}); }
  }

  Future<void> _scanAndFindParcel() async {
    _searchFocusNode.unfocus();
    final scannedCode = await Navigator.push<String>(context, MaterialPageRoute(builder: (context) => const BarcodeScannerScreen()));
    if (scannedCode == null || scannedCode.isEmpty) return;

    final box = Hive.box<VehicleEntry>('vehicle_entries');
    VehicleEntry? foundEntry; BoxItem? foundBox;

    for (var entry in box.values) {
      if (entry.isDeleted) continue;
      for (var b in entry.boxes) {
        if (b.consignmentNo.toUpperCase() == scannedCode.toUpperCase()) { foundEntry = entry; foundBox = b; break; }
      }
      if (foundEntry != null) break;
    }

    if (foundEntry != null && foundBox != null) {
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Parcel Found!', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Consignment: ${foundBox!.consignmentNo}', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8), Text('Company: ${foundBox.companyName}'),
              Text('Vehicle: ${foundEntry!.vehicleNumber}'), Text('Driver: ${foundEntry.driverName}'),
              const SizedBox(height: 8),
              Text('Received: ${foundBox.receivedBoxes} | Expected: ${foundBox.expectedBoxes}', style: TextStyle(color: foundBox.shortage > 0 ? Colors.red : Colors.green, fontWeight: FontWeight.bold))
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Close')),
            ElevatedButton(onPressed: () { Navigator.pop(dialogContext); _navigateToConsignment(foundEntry!); }, child: const Text('Open Vehicle')),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Parcel $scannedCode nahi mila!'), backgroundColor: Colors.red));
    }
  }

  void _showQuickActionsSheet(VehicleEntry entry) {
    final archiveBox = Hive.box<String>('archive_box');

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.95),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24.0)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(child: Container(margin: const EdgeInsets.only(top: 12, bottom: 12), width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(10)))),
                Text(entry.vehicleNumber, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Divider(height: 24),
                ListTile(
                  leading: const Icon(Icons.edit, color: Colors.blue),
                  title: const Text('Edit Details'),
                  onTap: () { Navigator.pop(context); _navigateToEntry(existingEntry: entry); },
                ),
                ListTile(
                  leading: const Icon(Icons.archive, color: const Color(0xFFD84315)),
                  title: const Text('Archive Vehicle'),
                  onTap: () {
                    archiveBox.put(entry.key.toString(), 'archived');
                    setState(() {});
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${entry.vehicleNumber} Archived!')));
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.share, color: Colors.green),
                  title: const Text('Share via WhatsApp'),
                  onTap: () async { Navigator.pop(context); await ExportService.exportToWhatsApp(entry); },
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Hive.box<VehicleEntry>('vehicle_entries').listenable(),
      builder: (context, Box<VehicleEntry> box, _) {
        final archiveBox = Hive.box<String>('archive_box');
        final allEntries = box.values.where((e) => !e.isDeleted && !archiveBox.containsKey(e.key.toString())).toList().reversed.toList();
        final loadingCount = allEntries.where((e) => e.vehicleStatus == 'Loading').length;
        final unloadingCount = allEntries.where((e) => e.vehicleStatus == 'Unloading').length;

        final entries = _searchQuery.isEmpty ? allEntries : allEntries.where((entry) {
          final query = _searchQuery.toLowerCase();
          return entry.vehicleNumber.toLowerCase().contains(query) || entry.driverName.toLowerCase().contains(query) || entry.driverMobile.toLowerCase().contains(query) || entry.boxes.any((b) => b.consignmentNo.toLowerCase().contains(query) || b.companyName.toLowerCase().contains(query));
        }).toList();

        final trashCount = box.values.where((e) => e.isDeleted).length;

        return Scaffold(
          key: _scaffoldKey,
          appBar: AppBar(
            title: const Text('LT Operations', style: TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: const Color(0xFFD84315),
            foregroundColor: Colors.white,
            elevation: 0,
            actions: [
              IconButton(icon: const Icon(Icons.qr_code_scanner), tooltip: 'Find Parcel', onPressed: _scanAndFindParcel),
            ],
          ),
          drawer: Drawer(
            backgroundColor: Colors.transparent,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
              child: Container(
                color: Colors.white.withOpacity(0.9),
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    Container(
                      padding: const EdgeInsets.only(top: 40, bottom: 20, left: 20),
                      decoration: const BoxDecoration(color: Color(0xFFD84315), borderRadius: BorderRadius.only(bottomRight: Radius.circular(30))),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Image.asset('assets/letstransport_logo.png', height: 60, width: 60, fit: BoxFit.cover),
                          const SizedBox(height: 15),
                          const Text('Let\'s Transport', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                          const Text('Supervisor Menu', style: TextStyle(color: Colors.white70, fontSize: 14)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildDrawerItem(Icons.save_outlined, 'Export Backup', 'Data file save karein', Colors.orange, () async { Navigator.pop(context); final backup = BackupService(); await backup.exportData(); }),
                    _buildDrawerItem(Icons.folder_open_outlined, 'Import Backup', 'Purana data layein', Colors.blue, () async { Navigator.pop(context); final backup = BackupService(); await backup.importData(context); if (mounted) setState(() {}); }),
                    const Divider(indent: 20, endIndent: 20),
                    _buildDrawerItem(Icons.grid_view, 'Location and Audit', 'Zone wise tracking', Colors.indigo, () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (context) => const LocationAuditScreen())); }),
                    _buildDrawerItem(Icons.archive_outlined, 'Archived Vehicles', 'Old completed entries', Colors.deepOrange, () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (context) => const ArchiveScreen())); }),
                    _buildDrawerItem(Icons.delete_outline, 'Trash', 'Deleted items', Colors.red, () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (context) => const TrashScreen())); }, trailing: trashCount > 0 ? Container(padding: const EdgeInsets.all(6), decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle), child: Text(trashCount.toString(), style: const TextStyle(color: Colors.white, fontSize: 12))) : null),
                    const Divider(indent: 20, endIndent: 20),
                    _buildDrawerItem(Icons.qr_code_2, 'Generate Stickers', 'Print barcode stickers', Colors.teal, () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (context) => const StickerGeneratorScreen())); }),
                    _buildDrawerItem(Icons.menu_book, 'Manage Dictionary', 'Auto-complete words', Colors.purple, () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (context) => const ManageSuggestionsScreen())); }),
                    _buildDrawerItem(Icons.bar_chart, 'Reports & Analytics', 'Aaj ka stats dekhein', Colors.green, () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (context) => const ReportsScreen())); }),
                  ],
                ),
              ),
            ),
          ),
          body: GestureDetector(
            onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
            behavior: HitTestBehavior.opaque,
            onHorizontalDragEnd: (details) { if (details.primaryVelocity != null && details.primaryVelocity! > 100) _scaffoldKey.currentState?.openDrawer(); },
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: TextField(
                    controller: _searchController, focusNode: _searchFocusNode,
                    onChanged: (val) => setState(() => _searchQuery = val),
                    decoration: InputDecoration(
                      labelText: 'Search Vehicle, Driver, Parcel...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchQuery.isNotEmpty ? IconButton(icon: const Icon(Icons.clear), onPressed: () { _searchController.clear(); setState(() => _searchQuery = ''); }) : null,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(child: _buildMetricCard('Loading', loadingCount, const Color(0xFFD84315))),
                      const SizedBox(width: 12),
                      Expanded(child: _buildMetricCard('Unloading', unloadingCount, const Color(0xFFFFA000))),
                    ],
                  ),
                ),
                Expanded(
                  child: entries.isEmpty
                      ? const Center(child: Text('Abhi koi entry nahi hai.\nNaye Vehicle ke liye + dabayein.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)))
                      : ListView.builder(
                    padding: const EdgeInsets.only(left: 16, right: 16, bottom: 80, top: 8),
                    itemCount: entries.length,
                    itemBuilder: (context, index) {
                      final entry = entries[index];
                      final isTatExceeded = !entry.isCompleted && DateTime.now().difference(entry.entryDate).inHours >= 2;
                      final tatDuration = _getTatDuration(entry.entryDate);

                      return Dismissible(
                        key: Key(entry.key.toString()),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(16)),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (direction) {
                          entry.isDeleted = true;
                          entry.save();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('${entry.vehicleNumber} Trash me bhej diya gaya!')),
                          );
                        },
                        child: GestureDetector(
                          onTap: () {
                            _searchFocusNode.unfocus();
                            _navigateToConsignment(entry);
                          },
                          onLongPress: () => _showQuickActionsSheet(entry),
                          child: Card(
                            elevation: 3,
                            margin: const EdgeInsets.only(bottom: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(color: entry.isCompleted ? Colors.transparent : (isTatExceeded ? Colors.red.shade200 : Colors.orange.shade200), width: 1.5),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(child: Text(entry.vehicleNumber, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: entry.vehicleStatus == 'Loading' ? const Color(0xFFD84315).withOpacity(0.1) : const Color(0xFFFFA000).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text('${entry.vehicleStatus} | ${entry.gateNumber}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: entry.vehicleStatus == 'Loading' ? const Color(0xFFD84315) : const Color(0xFFFFA000))),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Text('Driver: ${entry.driverName} (${entry.driverMobile})', style: TextStyle(color: Colors.grey[600])),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Icon(Icons.timer, size: 16, color: isTatExceeded ? Colors.red : Colors.grey),
                                      const SizedBox(width: 4),
                                      Text('TAT: $tatDuration', style: TextStyle(fontSize: 12, color: isTatExceeded ? Colors.red : Colors.grey, fontWeight: FontWeight.bold)),
                                      const Spacer(),
                                      Text('Boxes: ${entry.totalReceivedBoxes}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                      const SizedBox(width: 10),
                                      Text(
                                            () { String status = ''; if (entry.totalShortage > 0) status += 'Short: ${entry.totalShortage}  '; if (entry.totalDamaged > 0) status += 'Dmg: ${entry.totalDamaged}'; if (status.isEmpty) status = 'Perfect'; return status.trim(); }(),
                                        style: TextStyle(fontSize: 12, color: (entry.totalShortage > 0 || entry.totalDamaged > 0) ? Colors.red : Colors.green, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            heroTag: 'new_vehicle_btn',
            onPressed: () { _searchFocusNode.unfocus(); _navigateToEntry(); },
            backgroundColor: const Color(0xFFD84315),
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add),
            label: const Text('New Vehicle'),
          ),
        );
      },
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, String subtitle, Color color, VoidCallback onTap, {Widget? trailing}) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: color),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: trailing,
      onTap: onTap,
    );
  }

  Widget _buildMetricCard(String title, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(title == 'Loading' ? Icons.local_shipping : Icons.archive, size: 18, color: color),
          const SizedBox(width: 8),
          Text('$title: ', style: TextStyle(fontSize: 14, color: color, fontWeight: FontWeight.w500)),
          Text('$count', style: TextStyle(fontSize: 18, color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}