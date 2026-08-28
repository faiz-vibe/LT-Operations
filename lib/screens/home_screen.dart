import 'dart:async'; // Naya Import for Timer
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/vehicle_entry.dart';
import '../models/box_item.dart';
import 'vehicle_entry_screen.dart';
import 'consignment_screen.dart';
import 'barcode_scanner_screen.dart';
import 'trash_screen.dart';
import 'manage_suggestions_screen.dart';
import 'reports_screen.dart';
import 'sticker_generator_screen.dart';
import '../services/backup_service.dart';

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

  // PRO FEATURE: Timer for Live TAT update
  Timer? _tatTimer;

  @override
  void initState() {
    super.initState();
    // Har 60 second me screen refresh karo taaki timer update ho
    _tatTimer = Timer.periodic(const Duration(seconds: 60), (Timer t) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tatTimer?.cancel(); // Timer band kar do screen chhodte time
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  // PRO FEATURE: Duration calculate karne ka logic
  String _getTatDuration(DateTime entryDate) {
    final duration = DateTime.now().difference(entryDate);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours > 0) {
      return "${hours}h ${minutes}m";
    } else {
      return "${minutes}m";
    }
  }

  Future<void> _navigateToEntry({VehicleEntry? existingEntry}) async {
    _searchFocusNode.unfocus();
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VehicleEntryScreen(existingEntry: existingEntry),
      ),
    );
    if (mounted) {
      _searchFocusNode.unfocus();
      setState(() {});
    }
  }

  Future<void> _navigateToConsignment(VehicleEntry entry) async {
    _searchFocusNode.unfocus();
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ConsignmentScreen(vehicleEntry: entry),
      ),
    );
    if (mounted) {
      _searchFocusNode.unfocus();
      setState(() {});
    }
  }

  Future<void> _scanAndFindParcel() async {
    _searchFocusNode.unfocus();
    final scannedCode = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const BarcodeScannerScreen()),
    );

    if (scannedCode == null || scannedCode.isEmpty) return;

    final box = Hive.box<VehicleEntry>('vehicle_entries');
    VehicleEntry? foundEntry;
    BoxItem? foundBox;

    for (var entry in box.values) {
      if (entry.isDeleted) continue;
      for (var b in entry.boxes) {
        if (b.consignmentNo.toUpperCase() == scannedCode.toUpperCase()) {
          foundEntry = entry;
          foundBox = b;
          break;
        }
      }
      if (foundEntry != null) break;
    }

    if (foundEntry != null && foundBox != null) {
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Parcel Found!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Consignment: ${foundBox!.consignmentNo}', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Company: ${foundBox.companyName}'),
              Text('Vehicle: ${foundEntry!.vehicleNumber}'),
              Text('Driver: ${foundEntry.driverName}'),
              const SizedBox(height: 8),
              Text(
                  'Received: ${foundBox.receivedBoxes} | Expected: ${foundBox.expectedBoxes}',
                  style: TextStyle(
                      color: foundBox.shortage > 0 ? Colors.red : Colors.green,
                      fontWeight: FontWeight.bold
                  )
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _navigateToConsignment(foundEntry!);
              },
              child: const Text('Open Vehicle'),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Parcel $scannedCode kisi bhi vehicle me nahi mila!'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Hive.box<VehicleEntry>('vehicle_entries').listenable(),
      builder: (context, Box<VehicleEntry> box, _) {
        final allEntries = box.values.where((e) => !e.isDeleted).toList().reversed.toList();

        final loadingCount = allEntries.where((e) => e.vehicleStatus == 'Loading').length;
        final unloadingCount = allEntries.where((e) => e.vehicleStatus == 'Unloading').length;

        final entries = _searchQuery.isEmpty
            ? allEntries
            : allEntries.where((entry) {
          final query = _searchQuery.toLowerCase();

          final vehicleNo = entry.vehicleNumber.toLowerCase();
          final driverName = entry.driverName.toLowerCase();
          final driverMob = entry.driverMobile.toLowerCase();

          final hasConsignment = entry.boxes.any((b) => b.consignmentNo.toLowerCase().contains(query));
          final hasCompany = entry.boxes.any((b) => b.companyName.toLowerCase().contains(query));
          final hasMode = entry.boxes.any((b) => b.transportMode.toLowerCase().contains(query));

          return vehicleNo.contains(query) ||
              driverName.contains(query) ||
              driverMob.contains(query) ||
              hasConsignment ||
              hasCompany ||
              hasMode;
        }).toList();

        final trashCount = box.values.where((e) => e.isDeleted).length;

        final draftEntry = box.values.cast<VehicleEntry?>().firstWhere(
              (entry) => entry != null && !entry.isCompleted && !entry.isDeleted,
          orElse: () => null,
        );

        return Scaffold(
          key: _scaffoldKey,
          appBar: AppBar(
            title: const Text('Transport Supervisor', style: TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: Colors.blue[800],
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
                tooltip: 'Scan & Find Parcel',
                onPressed: _scanAndFindParcel,
              ),
            ],
          ),
          drawer: Drawer(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                DrawerHeader(
                  decoration: BoxDecoration(color: Colors.blue[800]),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Icon(Icons.local_shipping, color: Colors.white, size: 40),
                      SizedBox(height: 10),
                      Text('Transport App', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                      Text('Supervisor Menu', style: TextStyle(color: Colors.white70, fontSize: 14)),
                    ],
                  ),
                ),
                ListTile(
                  leading: Icon(Icons.save_outlined, color: Colors.blue[800]),
                  title: const Text('Export Backup'),
                  subtitle: const Text('Data file save/share karein'),
                  onTap: () async {
                    Navigator.pop(context);
                    try {
                      final backup = BackupService();
                      await backup.exportData();
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Backup failed: $e')));
                    }
                  },
                ),
                ListTile(
                  leading: Icon(Icons.folder_open_outlined, color: Colors.orange[800]),
                  title: const Text('Import Backup'),
                  subtitle: const Text('Purana data wapas layein'),
                  onTap: () async {
                    Navigator.pop(context);
                    final backup = BackupService();
                    await backup.importData(context);
                    if (mounted) setState(() {});
                  },
                ),
                const Divider(),
                ListTile(
                  leading: Icon(Icons.delete_outline, color: Colors.red[800]),
                  title: const Text('Trash (Recycle Bin)'),
                  subtitle: const Text('Deleted items restore/delete karein'),
                  trailing: trashCount > 0
                      ? Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    child: Text(trashCount.toString(), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  )
                      : null,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const TrashScreen()));
                  },
                ),
                ListTile(
                  leading: Icon(Icons.menu_book, color: Colors.purple[800]),
                  title: const Text('Manage Dictionary'),
                  subtitle: const Text('Auto-complete words add/edit karein'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const ManageSuggestionsScreen()));
                  },
                ),
                ListTile(
                  leading: Icon(Icons.bar_chart, color: Colors.green[800]),
                  title: const Text('Reports & Analytics'),
                  subtitle: const Text('Aaj ka summary aur stats dekhein'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const ReportsScreen()));
                  },
                ),
                ListTile(
                  leading: Icon(Icons.qr_code_2, color: Colors.teal[800]),
                  title: const Text('Generate Stickers'),
                  subtitle: const Text('Print barcode stickers for boxes'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const StickerGeneratorScreen()));
                  },
                ),
              ],
            ),
          ),
          body: GestureDetector(
            onTap: () {
              FocusManager.instance.primaryFocus?.unfocus();
            },
            behavior: HitTestBehavior.opaque,
            onHorizontalDragEnd: (details) {
              if (details.primaryVelocity != null && details.primaryVelocity! > 100) {
                _scaffoldKey.currentState?.openDrawer();
              }
            },
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val;
                      });
                    },
                    decoration: InputDecoration(
                      labelText: 'Search Vehicle, Driver, Company, Mode...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                          : null,
                    ),
                  ),
                ),
                if (_searchQuery.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 2.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '${entries.length} vehicles found',
                        style: const TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                          decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(8)),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.local_shipping, size: 16, color: Colors.blue[800]),
                              const SizedBox(width: 6),
                              Text('Loading: ', style: TextStyle(fontSize: 13, color: Colors.blue[800], fontWeight: FontWeight.w500)),
                              Text('$loadingCount', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue[800])),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                          decoration: BoxDecoration(color: Colors.orange[50], borderRadius: BorderRadius.circular(8)),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.archive, size: 16, color: Colors.orange[800]),
                              const SizedBox(width: 6),
                              Text('Unloading: ', style: TextStyle(fontSize: 13, color: Colors.orange[800], fontWeight: FontWeight.w500)),
                              Text('$unloadingCount', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.orange[800])),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: entries.isEmpty
                      ? Center(
                    child: Text(
                      _searchQuery.isEmpty
                          ? 'Abhi koi entry nahi hai.\nNaye Vehicle ke liye + dabayein.'
                          : 'Koi result nahi mila.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  )
                      : ListView.builder(
                    padding: const EdgeInsets.only(left: 12, right: 12, bottom: 80, top: 4),
                    itemCount: entries.length,
                    itemBuilder: (context, index) {
                      final entry = entries[index];

                      // PRO FEATURE: TAT Logic
                      final isTatExceeded = !entry.isCompleted && DateTime.now().difference(entry.entryDate).inHours >= 2;
                      final tatDuration = _getTatDuration(entry.entryDate);

                      return Dismissible(
                        key: Key(entry.key.toString()),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10)),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (direction) {
                          entry.isDeleted = true;
                          entry.save();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('${entry.vehicleNumber} Trash me bhej diya gaya!')),
                          );
                        },
                        child: Card(
                          elevation: 2,
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(
                              // PRO FEATURE: Agar TAT exceed hua to card border Red
                              color: entry.isCompleted ? Colors.transparent : (isTatExceeded ? Colors.red : Colors.orange),
                              width: 1.5,
                            ),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            title: Text(entry.vehicleNumber, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Driver: ${entry.driverName}'),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: entry.vehicleStatus == 'Loading' ? Colors.blue[100] : Colors.orange[100],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '${entry.vehicleStatus} | ${entry.gateNumber}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: entry.vehicleStatus == 'Loading' ? Colors.blue[800] : Colors.orange[800],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Total Boxes: ${entry.totalReceivedBoxes}',
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                ),
                                Text(
                                      () {
                                    String status = '';
                                    if (entry.totalShortage > 0) status += 'Short: ${entry.totalShortage}  ';
                                    if (entry.totalExtra > 0) status += 'Extra: ${entry.totalExtra}  ';
                                    if (entry.totalDamaged > 0) status += 'Damaged: ${entry.totalDamaged}';
                                    if (status.isEmpty) status = 'All Perfect';
                                    return status.trim();
                                  }(),
                                  style: TextStyle(
                                      color: (entry.totalShortage > 0 || entry.totalDamaged > 0) ? Colors.red : (entry.totalExtra > 0 ? Colors.blue : Colors.green),
                                      fontWeight: FontWeight.w500
                                  ),
                                ),
                                // PRO FEATURE: TAT Display UI
                                Row(
                                  children: [
                                    Icon(Icons.timer, size: 14, color: isTatExceeded ? Colors.red : Colors.grey),
                                    const SizedBox(width: 4),
                                    Text(
                                      'TAT: $tatDuration',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isTatExceeded ? Colors.red : Colors.grey,
                                        fontWeight: isTatExceeded ? FontWeight.bold : FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  'Created: ${entry.entryDate.day}/${entry.entryDate.month}/${entry.entryDate.year}  ${entry.entryDate.hour.toString().padLeft(2, '0')}:${entry.entryDate.minute.toString().padLeft(2, '0')}',
                                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                                ),
                                if (entry.lastEditedAt != null)
                                  Text(
                                    'Edited: ${entry.lastEditedAt!.day}/${entry.lastEditedAt!.month}/${entry.lastEditedAt!.year}  ${entry.lastEditedAt!.hour.toString().padLeft(2, '0')}:${entry.lastEditedAt!.minute.toString().padLeft(2, '0')}',
                                    style: const TextStyle(fontSize: 10, color: Colors.blueGrey, fontStyle: FontStyle.italic),
                                  ),
                              ],
                            ),
                            trailing: IconButton(
                              icon: Icon(
                                entry.isCompleted ? Icons.check_circle : Icons.edit_note,
                                color: entry.isCompleted ? Colors.green : Colors.orange,
                                size: 28,
                              ),
                              onPressed: () => _navigateToEntry(existingEntry: entry),
                            ),
                            onTap: () => _navigateToConsignment(entry),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          floatingActionButton: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (draftEntry != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: FloatingActionButton.extended(
                    heroTag: 'draft_btn',
                    onPressed: () {
                      _searchFocusNode.unfocus();
                      _navigateToEntry(existingEntry: draftEntry);
                    },
                    backgroundColor: Colors.orange[600],
                    icon: const Icon(Icons.edit_note, color: Colors.white),
                    label: const Text(
                      'Resume Draft',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 14),
                    ),
                  ),
                ),

              FloatingActionButton.extended(
                heroTag: 'new_vehicle_btn',
                onPressed: () {
                  _searchFocusNode.unfocus();
                  _navigateToEntry();
                },
                backgroundColor: Colors.blue[800],
                icon: const Icon(Icons.add, color: Colors.white, size: 32),
                label: const Text(
                  'New Vehicle',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}