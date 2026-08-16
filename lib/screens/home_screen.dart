import 'package:flutter/material.dart' show Align, Alignment, AppBar, BorderRadius, BorderSide, BoxDecoration, BoxShape, BuildContext, Card, Center, Colors, Column, Container, CrossAxisAlignment, DismissDirection, Dismissible, Divider, Drawer, DrawerHeader, EdgeInsets, Expanded, FloatingActionButton, FocusManager, FocusNode, FontStyle, FontWeight, GestureDetector, GlobalKey, HitTestBehavior, Icon, IconButton, Icons, InputDecoration, Key, ListTile, ListView, MainAxisAlignment, MaterialPageRoute, Navigator, OutlineInputBorder, Padding, RoundedRectangleBorder, Row, Scaffold, ScaffoldMessenger, ScaffoldState, SizedBox, SnackBar, State, StatefulWidget, Text, TextAlign, TextEditingController, TextField, TextStyle, ValueListenableBuilder, Widget;
import 'package:hive_flutter/hive_flutter.dart';
import '../models/vehicle_entry.dart';
import 'vehicle_entry_screen.dart';
import 'consignment_screen.dart';
import 'trash_screen.dart';
import 'manage_suggestions_screen.dart';
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

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
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

        // Check karein ki koi incomplete entry (draft) hai ya nahi
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
                              color: entry.isCompleted ? Colors.transparent : Colors.orange,
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
                                  'Total Boxes: ${entry.totalReceivedBoxes} | Shortage: ${entry.totalShortage}',
                                  style: TextStyle(color: entry.totalShortage > 0 ? Colors.red : Colors.green, fontWeight: FontWeight.w500),
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
              // Draft Button (Sirf tabhi dikhega jab koi incomplete entry hogi)
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

              // New Vehicle Button (Hamesha dikhega aur bada hoga)
              FloatingActionButton.extended(
                heroTag: 'new_vehicle_btn',
                onPressed: () {
                  _searchFocusNode.unfocus();
                  _navigateToEntry(); // Hamesha nayi entry kholega
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