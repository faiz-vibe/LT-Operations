import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../models/vehicle_entry.dart';
import '../services/media_service.dart';
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
  bool _skippedStartPhotos = false;
  late String _selectedStatus;

  // Pro FocusNodes for perfect keyboard navigation
  final FocusNode _driverNameFocusNode = FocusNode();
  final FocusNode _driverMobileFocusNode = FocusNode();

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
        startPhotos: [],
        endPhotos: [],
      );
      _isNewEntry = true;
      final box = Hive.box<VehicleEntry>('vehicle_entries');
      box.add(_currentEntry);
    }
    _selectedStatus = _currentEntry.vehicleStatus;
  }

  @override
  void dispose() {
    _driverNameFocusNode.dispose();
    _driverMobileFocusNode.dispose();

    if (_isNewEntry) {
      bool isEmpty = _currentEntry.vehicleNumber.trim().isEmpty &&
          _currentEntry.driverName.trim().isEmpty &&
          _currentEntry.driverMobile.trim().isEmpty &&
          _currentEntry.boxes.where((b) => !b.isDeleted && b.consignmentNo.isNotEmpty).isEmpty;

      if (isEmpty) {
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

    int requiredStartPhotos = _selectedStatus == 'Unloading' ? 2 : 1;
    if (_currentEntry.startPhotos.length < requiredStartPhotos && !_skippedStartPhotos) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pehle Start Photos khinchye ya Skip dabayein! (Required: $requiredStartPhotos)'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final vBox = Hive.box<String>('vehicles');
    if (_currentEntry.vehicleNumber.isNotEmpty && !vBox.containsKey(_currentEntry.vehicleNumber)) {
      vBox.put(_currentEntry.vehicleNumber, _currentEntry.vehicleNumber);
    }

    final dBox = Hive.box<String>('drivers');
    if (_currentEntry.driverName.isNotEmpty && !dBox.containsKey(_currentEntry.driverName)) {
      dBox.put(_currentEntry.driverName, _currentEntry.driverName);
    }

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

  Future<void> _takeStartPhoto() async {
    final ImagePicker picker = ImagePicker();
    final XFile? photo = await picker.pickImage(source: ImageSource.camera, imageQuality: 70);

    if (photo != null && mounted) {
      final permanentPath = await MediaService.saveImagePermanently(photo.path);

      final List<String> updatedPhotos = List<String>.from(_currentEntry.startPhotos);
      updatedPhotos.add(permanentPath);

      setState(() {
        _currentEntry.startPhotos = updatedPhotos;
        _currentEntry.save();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    int requiredStartPhotos = _selectedStatus == 'Unloading' ? 2 : 1;
    bool hasStartPhotos = _currentEntry.startPhotos.length >= requiredStartPhotos;
    bool canProceed = hasStartPhotos || _skippedStartPhotos;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vehicle & Driver Details', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
      ),
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        behavior: HitTestBehavior.opaque,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Auto-save is ON',
                style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // 1. Vehicle Number (Next -> Driver Name)
              Autocomplete<String>(
                initialValue: TextEditingValue(text: _currentEntry.vehicleNumber),
                fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                  return TextField(
                    controller: controller,
                    focusNode: focusNode,
                    onEditingComplete: onEditingComplete,
                    textCapitalization: TextCapitalization.characters,
                    textInputAction: TextInputAction.next,
                    onSubmitted: (_) => _driverNameFocusNode.requestFocus(),
                    onChanged: (val) {
                      _currentEntry.vehicleNumber = val.toUpperCase();
                      _currentEntry.save();
                    },
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
                  _driverNameFocusNode.requestFocus();
                },
              ),
              const SizedBox(height: 16),

              // 2. Driver Name (Next -> Driver Mobile)
              Autocomplete<String>(
                initialValue: TextEditingValue(text: _currentEntry.driverName),
                fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                  // Apna FocusNode set kiya gaya hai
                  focusNode = _driverNameFocusNode;
                  return TextField(
                    controller: controller,
                    focusNode: focusNode,
                    onEditingComplete: onEditingComplete,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    onSubmitted: (_) => _driverMobileFocusNode.requestFocus(),
                    onChanged: (val) {
                      _currentEntry.driverName = val;
                      _currentEntry.save();
                    },
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
                  _driverMobileFocusNode.requestFocus();
                },
              ),
              const SizedBox(height: 16),

              // 3. Driver Mobile (Done/Tick -> Auto Proceed/Save)
              Autocomplete<String>(
                initialValue: TextEditingValue(text: _currentEntry.driverMobile),
                fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                  focusNode = _driverMobileFocusNode;
                  return TextField(
                    controller: controller,
                    focusNode: focusNode,
                    onEditingComplete: onEditingComplete,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.done, // Yahan Tick (Done) aayega
                    onSubmitted: (_) {
                      FocusScope.of(context).unfocus();
                      _proceedOrSave(); // Tick dabate hi save/proceed ho jayega
                    },
                    onChanged: (val) {
                      _currentEntry.driverMobile = val;
                      _currentEntry.save();
                    },
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
                  FocusScope.of(context).unfocus();
                },
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _selectedStatus,
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
                  FocusScope.of(context).unfocus();
                  setState(() {
                    _selectedStatus = val!;
                    _currentEntry.vehicleStatus = val;
                    _currentEntry.startPhotos = [];
                    _skippedStartPhotos = false;
                    _currentEntry.save();
                  });
                },
              ),
              const SizedBox(height: 16),

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
                  FocusScope.of(context).unfocus();
                  setState(() {
                    _currentEntry.gateNumber = val!;
                    _currentEntry.save();
                  });
                },
              ),
              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: canProceed ? Colors.green : Colors.red, width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Start Photos (Zaruri)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        if (!canProceed)
                          TextButton(
                            onPressed: () {
                              FocusScope.of(context).unfocus();
                              setState(() {
                                _skippedStartPhotos = true;
                              });
                            },
                            child: const Text('Skip', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                          ),
                        if (canProceed)
                          const Padding(
                            padding: EdgeInsets.only(right: 8.0),
                            child: Icon(Icons.check_circle, color: Colors.green),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _selectedStatus == 'Unloading'
                          ? '1. Seal Photo\n2. Gate Open Photo'
                          : '1. Empty Vehicle Photo',
                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 10),

                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.camera_alt, color: Colors.white),
                            label: Text(
                              _currentEntry.startPhotos.isEmpty ? 'Take Photo' : 'Add More',
                              style: const TextStyle(color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[800]),
                            onPressed: _takeStartPhoto,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    if (_currentEntry.startPhotos.isNotEmpty)
                      SizedBox(
                        height: 90,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _currentEntry.startPhotos.length,
                          itemBuilder: (context, index) {
                            return Stack(
                              children: [
                                Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  child: Image.file(
                                    File(_currentEntry.startPhotos[index]),
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned(
                                  right: 0,
                                  top: 0,
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        final List<String> updatedPhotos = List<String>.from(_currentEntry.startPhotos);
                                        updatedPhotos.removeAt(index);
                                        _currentEntry.startPhotos = updatedPhotos;
                                        _currentEntry.save();
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                      child: const Icon(Icons.close, size: 14, color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: canProceed ? Colors.blue[800] : Colors.grey,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: canProceed ? _proceedOrSave : null,
                  child: Text(
                      widget.existingEntry == null ? 'Next: Scan Boxes' : 'Update Details',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
                  ),
                ),
              ),
              if (!canProceed)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    'Next button lock hai. Pehle Photos khinchye ya Skip dabayein.',
                    style: TextStyle(fontSize: 12, color: Colors.red[700]),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}