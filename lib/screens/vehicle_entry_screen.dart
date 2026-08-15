import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/vehicle_entry.dart';
import 'consignment_screen.dart';

class VehicleEntryScreen extends StatefulWidget {
  final VehicleEntry? existingEntry;

  const VehicleEntryScreen({super.key, this.existingEntry});

  @override
  State<VehicleEntryScreen> createState() => _VehicleEntryScreenState();
}

class _VehicleEntryScreenState extends State<VehicleEntryScreen> {
  late VehicleEntry _currentEntry;
  bool _isNewEntry = false;

  @override
  void initState() {
    super.initState();

    if (widget.existingEntry != null) {
      _currentEntry = widget.existingEntry!;
      _isNewEntry = false;
    } else {
      _currentEntry = VehicleEntry(
        vehicleNumber: '',
        driverName: '',
        driverMobile: '',
        boxes: [],
        entryDate: DateTime.now(),
        isCompleted: false,
        lastEditedAt: DateTime.now(),
      );
      _isNewEntry = true;
      final box = Hive.box<VehicleEntry>('vehicle_entries');
      box.add(_currentEntry);
    }
  }

  @override
  void dispose() {
    // Agar naye entry me kuch bhi type nahi hua hai, toh use delete kar do
    if (_isNewEntry) {
      // Check karein ki kisi bhi field me ek bhi alphabet ya number to nahi hai
      bool isEmpty = _currentEntry.vehicleNumber.trim().isEmpty &&
          _currentEntry.driverName.trim().isEmpty &&
          _currentEntry.driverMobile.trim().isEmpty &&
          _currentEntry.boxes.where((b) => !b.isDeleted && b.consignmentNo.isNotEmpty).isEmpty;

      if (isEmpty) {
        // Agar poori entry khaali hai, toh Trash me bhejne ke bajaye direct DB se delete kar do
        _currentEntry.delete();
      }
    }
    super.dispose();
  }

  void _proceedOrSave() {
    if (_currentEntry.vehicleNumber.isEmpty || _currentEntry.driverName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kripya Vehicle No aur Driver Name dalein!')),
      );
      return;
    }

    // Auto-complete Dictionary me save karein
    final vBox = Hive.box<String>('vehicles');
    if (_currentEntry.vehicleNumber.isNotEmpty && !vBox.containsKey(_currentEntry.vehicleNumber)) {
      vBox.put(_currentEntry.vehicleNumber, _currentEntry.vehicleNumber);
    }

    final dBox = Hive.box<String>('drivers');
    if (_currentEntry.driverName.isNotEmpty && !dBox.containsKey(_currentEntry.driverName)) {
      dBox.put(_currentEntry.driverName, _currentEntry.driverName);
    }

    // Naya: Driver Mobile Number ko save karein
    final mBox = Hive.box<String>('driver_mobiles');
    if (_currentEntry.driverMobile.isNotEmpty && !mBox.containsKey(_currentEntry.driverMobile)) {
      mBox.put(_currentEntry.driverMobile, _currentEntry.driverMobile);
    }

    if (widget.existingEntry == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ConsignmentScreen(vehicleEntry: _currentEntry),
        ),
      );
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vehicle & Driver Details', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Auto-save is ON',
              style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Vehicle Number (Auto-complete)
            Autocomplete<String>(
              initialValue: TextEditingValue(text: _currentEntry.vehicleNumber),
              fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                controller.addListener(() {
                  _currentEntry.vehicleNumber = controller.text.toUpperCase();
                  _currentEntry.save();
                });
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  onEditingComplete: onEditingComplete,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'Vehicle Number',
                    hintText: 'Write Vehicle Number',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.local_shipping),
                  ),
                );
              },
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text.isEmpty) return const Iterable<String>.empty();
                final box = Hive.box<String>('vehicles');
                return box.values.where((v) => v.toLowerCase().contains(textEditingValue.text.toLowerCase()));
              },
              onSelected: (String selection) {
                _currentEntry.vehicleNumber = selection.toUpperCase();
                _currentEntry.save();
              },
            ),
            const SizedBox(height: 16),

            // Driver Name (Auto-complete)
            Autocomplete<String>(
              initialValue: TextEditingValue(text: _currentEntry.driverName),
              fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                controller.addListener(() {
                  _currentEntry.driverName = controller.text;
                  _currentEntry.save();
                });
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  onEditingComplete: onEditingComplete,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Driver Name',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                );
              },
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text.isEmpty) return const Iterable<String>.empty();
                final box = Hive.box<String>('drivers');
                return box.values.where((d) => d.toLowerCase().contains(textEditingValue.text.toLowerCase()));
              },
              onSelected: (String selection) {
                _currentEntry.driverName = selection;
                _currentEntry.save();
              },
            ),
            const SizedBox(height: 16),

            // Driver Mobile (Auto-complete)
            Autocomplete<String>(
              initialValue: TextEditingValue(text: _currentEntry.driverMobile),
              fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                controller.addListener(() {
                  _currentEntry.driverMobile = controller.text;
                  _currentEntry.save();
                });
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  onEditingComplete: onEditingComplete,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Driver Mobile Number',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone),
                  ),
                );
              },
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text.isEmpty) return const Iterable<String>.empty();
                final box = Hive.box<String>('driver_mobiles');
                return box.values.where((m) => m.toLowerCase().contains(textEditingValue.text.toLowerCase()));
              },
              onSelected: (String selection) {
                _currentEntry.driverMobile = selection;
                _currentEntry.save();
              },
            ),
            const SizedBox(height: 16),

            // Load / Unload Dropdown
            DropdownButtonFormField<String>(
              value: _currentEntry.vehicleStatus,
              decoration: const InputDecoration(
                labelText: 'Loading / Unloading',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.sync_alt),
              ),
              items: const [
                DropdownMenuItem(value: 'Loading', child: Text('Loading')),
                DropdownMenuItem(value: 'Unloading', child: Text('Unloading')),
              ],
              onChanged: (val) {
                setState(() {
                  _currentEntry.vehicleStatus = val!;
                  _currentEntry.save();
                });
              },
            ),
            const SizedBox(height: 16),

            // Gate Number Dropdown (1 to 4)
            DropdownButtonFormField<String>(
              value: _currentEntry.gateNumber,
              decoration: const InputDecoration(
                labelText: 'Select Dock/Gate Number',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.door_front_door),
              ),
              items: const [
                DropdownMenuItem(value: 'Gate 1', child: Text('Gate 1')),
                DropdownMenuItem(value: 'Gate 2', child: Text('Gate 2')),
                DropdownMenuItem(value: 'Gate 3', child: Text('Gate 3')),
                DropdownMenuItem(value: 'Gate 4', child: Text('Gate 4')),
              ],
              onChanged: (val) {
                setState(() {
                  _currentEntry.gateNumber = val!;
                  _currentEntry.save();
                });
              },
            ),
            const SizedBox(height: 30),

            // Next / Update Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[800],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: _proceedOrSave,
                child: Text(
                    widget.existingEntry == null ? 'Next: Scan Boxes' : 'Update Details',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}