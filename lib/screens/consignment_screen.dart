import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'dart:io';
import 'package:screenshot/screenshot.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';
import '../services/google_sync_service.dart';
import '../models/vehicle_entry.dart';
import '../models/box_item.dart';
import '../services/export_service.dart';
import '../services/media_service.dart';
import 'barcode_scanner_screen.dart';
import 'vehicle_entry_screen.dart';
import 'vehicle_media_gallery_screen.dart';

class ConsignmentScreen extends StatefulWidget {
  final VehicleEntry vehicleEntry;

  const ConsignmentScreen({super.key, required this.vehicleEntry});

  @override
  State<ConsignmentScreen> createState() => _ConsignmentScreenState();
}

class _ConsignmentScreenState extends State<ConsignmentScreen> {
  final ScreenshotController _screenshotController = ScreenshotController();
  final ScrollController _listScrollController = ScrollController();
  final _consignmentController = TextEditingController();
  final _companyController = TextEditingController();
  final _expectedController = TextEditingController(text: '0');
  final _receivedController = TextEditingController(text: '0');
  final _damagedCountController = TextEditingController(text: '0');
  final _damageDetailsController = TextEditingController();
  final _boxSearchController = TextEditingController();
  final _sourceLocationController = TextEditingController();
  final _destinationLocationController = TextEditingController();

  // Pro FocusNodes for perfect keyboard navigation
  final FocusNode _companyFocusNode = FocusNode();
  final FocusNode _sourceFocusNode = FocusNode();
  final FocusNode _destFocusNode = FocusNode();
  final FocusNode _expectedFocusNode = FocusNode();
  final FocusNode _receivedFocusNode = FocusNode();

  String _boxSearchQuery = '';
  final FocusNode _boxSearchFocusNode = FocusNode();

  bool _isDamaged = false;
  String _selectedMode = 'Surface';
  List<String> _damagePhotos = [];
  bool _damageCountError = false;

  BoxItem? _editingBox;
  bool _isNewDraft = false;
  int? _editingIndex;

  @override
  void dispose() {
    _consignmentController.dispose();
    _companyController.dispose();
    _expectedController.dispose();
    _receivedController.dispose();
    _damagedCountController.dispose();
    _damageDetailsController.dispose();
    _boxSearchController.dispose();
    _listScrollController.dispose();
    _boxSearchFocusNode.dispose();
    _companyFocusNode.dispose();
    _sourceFocusNode.dispose();
    _destFocusNode.dispose();
    _expectedFocusNode.dispose();
    _receivedFocusNode.dispose();
    _sourceLocationController.dispose();
    _destinationLocationController.dispose();
    super.dispose();
  }

  void _forceSave() {
    if (_editingBox == null) return;

    _editingBox!.consignmentNo = _consignmentController.text.toUpperCase();
    _editingBox!.companyName = _companyController.text.isEmpty ? 'Unknown' : _companyController.text;
    _editingBox!.expectedBoxes = int.tryParse(_expectedController.text) ?? 0;
    _editingBox!.receivedBoxes = int.tryParse(_receivedController.text) ?? 0;
    _editingBox!.isDamaged = _isDamaged;
    _editingBox!.damagedCount = _isDamaged ? (int.tryParse(_damagedCountController.text) ?? 0) : 0;
    _editingBox!.damageDetails = _isDamaged ? _damageDetailsController.text : '';
    _editingBox!.transportMode = _selectedMode;
    _editingBox!.damagePhotos = List<String>.from(_damagePhotos);
    _editingBox!.sourceLocation = _sourceLocationController.text;
    _editingBox!.destinationLocation = _destinationLocationController.text;
    _editingBox!.lastEditedAt = DateTime.now();

    if (_editingIndex != null && _editingIndex! < widget.vehicleEntry.boxes.length) {
      widget.vehicleEntry.boxes[_editingIndex!] = _editingBox!;
    }

    widget.vehicleEntry.lastEditedAt = DateTime.now();
    widget.vehicleEntry.save();

    final box = Hive.box<VehicleEntry>('vehicle_entries');
    box.flush();
  }

  void _saveAndClosePopup(BuildContext sheetContext) {
    if (_consignmentController.text.isEmpty || _receivedController.text.isEmpty) {
      ScaffoldMessenger.of(sheetContext).showSnackBar(
        const SnackBar(content: Text('Consignment No aur Received Box zaruri hai!')),
      );
      return;
    }

    final companyBox = Hive.box<String>('companies');
    if (_editingBox!.companyName.isNotEmpty && _editingBox!.companyName != 'Unknown' && !companyBox.containsKey(_editingBox!.companyName)) {
      companyBox.put(_editingBox!.companyName, _editingBox!.companyName);
    }

    final dBox = Hive.box<String>('damage_details');
    if (_editingBox!.isDamaged && _editingBox!.damageDetails.isNotEmpty && !dBox.containsKey(_editingBox!.damageDetails)) {
      dBox.put(_editingBox!.damageDetails, _editingBox!.damageDetails);
    }

    final locBox = Hive.box<String>('locations');
    if (_editingBox!.sourceLocation.isNotEmpty && !locBox.containsKey(_editingBox!.sourceLocation)) {
      locBox.put(_editingBox!.sourceLocation, _editingBox!.sourceLocation);
    }
    if (_editingBox!.destinationLocation.isNotEmpty && !locBox.containsKey(_editingBox!.destinationLocation)) {
      locBox.put(_editingBox!.destinationLocation, _editingBox!.destinationLocation);
    }

    _forceSave();
    Navigator.pop(sheetContext);
  }

  Future<void> _showBoxPopup({BoxItem? boxToEdit, int? index}) async {
    _boxSearchFocusNode.unfocus();

    _editingBox = boxToEdit;
    _editingIndex = index;
    _isNewDraft = false;

    if (boxToEdit != null) {
      _consignmentController.text = boxToEdit.consignmentNo;
      _companyController.text = boxToEdit.companyName;
      _expectedController.text = boxToEdit.expectedBoxes.toString();
      _receivedController.text = boxToEdit.receivedBoxes.toString();
      _isDamaged = boxToEdit.isDamaged;
      _damagedCountController.text = boxToEdit.damagedCount.toString();
      _damageDetailsController.text = boxToEdit.damageDetails;
      _selectedMode = boxToEdit.transportMode;
      _damagePhotos = List<String>.from(boxToEdit.damagePhotos);
      _sourceLocationController.text = boxToEdit.sourceLocation;
      _destinationLocationController.text = boxToEdit.destinationLocation;
      _damageCountError = false;
    } else {
      _isNewDraft = true;
      _editingBox = BoxItem(
        consignmentNo: '',
        companyName: 'Unknown',
        expectedBoxes: 0,
        receivedBoxes: 0,
        isDamaged: false,
        createdAt: DateTime.now(),
        damagePhotos: [],
      );
      widget.vehicleEntry.boxes.add(_editingBox!);
      _editingIndex = widget.vehicleEntry.boxes.length - 1;
      widget.vehicleEntry.save();

      _consignmentController.clear();
      _companyController.clear();
      _expectedController.text = '0';
      _receivedController.text = '0';
      _damagedCountController.text = '0';
      _damageDetailsController.clear();
      _sourceLocationController.clear();
      _destinationLocationController.clear();
      _isDamaged = false;
      _selectedMode = 'Surface';
      _damagePhotos = [];
      _damageCountError = false;
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isNewDraft ? 'Add New Box' : 'Edit Box Details',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),

                    // 1. Consignment (Next -> Company)
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _consignmentController,
                            textInputAction: TextInputAction.next,
                            onSubmitted: (_) => _companyFocusNode.requestFocus(),
                            decoration: const InputDecoration(
                              labelText: 'Consignment/Product No',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.inventory),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Barcode button (Focus skip)
                        Focus(
                          canRequestFocus: false,
                          child: Container(
                            height: 50,
                            width: 50,
                            decoration: BoxDecoration(
                              color: Colors.blue[800],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
                              onPressed: () async {
                                _boxSearchFocusNode.unfocus();
                                final scannedCode = await Navigator.push<String>(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const BarcodeScannerScreen(),
                                  ),
                                );
                                if (scannedCode != null && scannedCode.isNotEmpty) {
                                  setState(() {
                                    _consignmentController.text = scannedCode;
                                  });
                                  _companyFocusNode.requestFocus();
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // 2. Company Name (Next -> Source)
                    Autocomplete<String>(
                      initialValue: TextEditingValue(text: _companyController.text),
                      fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                        // Apna FocusNode yahan set kiya gaya hai
                        focusNode = _companyFocusNode;
                        return TextField(
                          controller: controller,
                          focusNode: focusNode,
                          textInputAction: TextInputAction.next,
                          onSubmitted: (_) => _sourceFocusNode.requestFocus(),
                          onChanged: (val) {
                            _companyController.text = val;
                          },
                          decoration: const InputDecoration(
                            labelText: 'Company Name',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.business),
                          ),
                        );
                      },
                      optionsBuilder: (TextEditingValue textEditingValue) {
                        if (textEditingValue.text.isEmpty) {
                          return const Iterable<String>.empty();
                        }
                        final companyBox = Hive.box<String>('companies');
                        return companyBox.values.where((company) =>
                            company.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                      },
                      onSelected: (String selection) {
                        _companyController.text = selection;
                        _sourceFocusNode.requestFocus();
                      },
                    ),
                    const SizedBox(height: 10),

                    // 3 & 4. Source & Dest (Next -> Expected)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Autocomplete<String>(
                            initialValue: TextEditingValue(text: _sourceLocationController.text),
                            fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                              focusNode = _sourceFocusNode;
                              return TextField(
                                controller: controller,
                                focusNode: focusNode,
                                textInputAction: TextInputAction.next,
                                onSubmitted: (_) => _destFocusNode.requestFocus(),
                                textCapitalization: TextCapitalization.words,
                                onChanged: (val) {
                                  _sourceLocationController.text = val;
                                },
                                decoration: const InputDecoration(
                                  labelText: 'From (Source)',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.location_on),
                                ),
                              );
                            },
                            optionsBuilder: (TextEditingValue textEditingValue) {
                              if (textEditingValue.text.isEmpty) {
                                return const Iterable<String>.empty();
                              }
                              final locBox = Hive.box<String>('locations');
                              return locBox.values.where((loc) =>
                                  loc.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                            },
                            onSelected: (String selection) {
                              _sourceLocationController.text = selection;
                              _destFocusNode.requestFocus();
                            },
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.only(top: 15.0, left: 5, right: 5),
                          child: Text('To', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                        Expanded(
                          child: Autocomplete<String>(
                            initialValue: TextEditingValue(text: _destinationLocationController.text),
                            fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                              focusNode = _destFocusNode;
                              return TextField(
                                controller: controller,
                                focusNode: focusNode,
                                textInputAction: TextInputAction.next,
                                onSubmitted: (_) => _expectedFocusNode.requestFocus(),
                                textCapitalization: TextCapitalization.words,
                                onChanged: (val) {
                                  _destinationLocationController.text = val;
                                },
                                decoration: const InputDecoration(
                                  labelText: 'To (Dest)',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.flag),
                                ),
                              );
                            },
                            optionsBuilder: (TextEditingValue textEditingValue) {
                              if (textEditingValue.text.isEmpty) {
                                return const Iterable<String>.empty();
                              }
                              final locBox = Hive.box<String>('locations');
                              return locBox.values.where((loc) =>
                                  loc.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                            },
                            onSelected: (String selection) {
                              _destinationLocationController.text = selection;
                              _expectedFocusNode.requestFocus();
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // 5 & 6. Expected & Received (Expected -> Next, Received -> Done/Save)
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _expectedController,
                            focusNode: _expectedFocusNode,
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.next,
                            onSubmitted: (_) => _receivedFocusNode.requestFocus(),
                            decoration: const InputDecoration(labelText: 'Expected', border: OutlineInputBorder()),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _receivedController,
                            focusNode: _receivedFocusNode,
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.done, // Yahan Tick (Done) aayega
                            onSubmitted: (_) => _saveAndClosePopup(sheetContext), // Enter/Done dabate hi save ho jayega
                            decoration: const InputDecoration(labelText: 'Received', border: OutlineInputBorder()),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Baaki ka code (Damage, Mode, Button) waisa hi rahega...
                    SwitchListTile(
                      title: const Text('Damaged Box'),
                      value: _isDamaged,
                      onChanged: (val) {
                        setModalState(() => _isDamaged = val);
                      },
                      activeColor: Colors.red,
                    ),
                    if (_isDamaged) ...[
                      const SizedBox(height: 10),
                      TextField(
                        controller: _damagedCountController,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        onSubmitted: (_) => FocusScope.of(context).nextFocus(),
                        onChanged: (val) {
                          setModalState(() {
                            _damageCountError = val.isEmpty || (int.tryParse(val) ?? 0) <= 0;
                          });
                        },
                        decoration: InputDecoration(
                          labelText: 'Kitne Box Damage Hue?',
                          border: OutlineInputBorder(
                            borderSide: BorderSide(color: _damageCountError ? Colors.red : Colors.grey),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: _damageCountError ? Colors.red : Colors.blue, width: 2),
                          ),
                          prefixIcon: Icon(Icons.broken_image, color: _damageCountError ? Colors.red : null),
                          errorText: _damageCountError ? 'Pehle kitna box damage hai likhein' : null,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Autocomplete<String>(
                        initialValue: TextEditingValue(text: _damageDetailsController.text),
                        fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                          return TextField(
                            controller: controller,
                            focusNode: focusNode,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => FocusScope.of(context).unfocus(),
                            maxLines: 2,
                            onChanged: (val) {
                              _damageDetailsController.text = val;
                            },
                            decoration: const InputDecoration(
                                labelText: 'Damage Details',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.description)
                            ),
                          );
                        },
                        optionsBuilder: (TextEditingValue textEditingValue) {
                          if (textEditingValue.text.isEmpty) {
                            return const Iterable<String>.empty();
                          }
                          final dBox = Hive.box<String>('damage_details');
                          return dBox.values.where((d) =>
                              d.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                        },
                        onSelected: (String selection) {
                          _damageDetailsController.text = selection;
                          FocusScope.of(context).unfocus();
                        },
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.camera_alt, color: Colors.white),
                        label: const Text('Upload Damage Photos', style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red[700]),
                        onPressed: () async {
                          int damageCount = int.tryParse(_damagedCountController.text) ?? 0;

                          if (_damagedCountController.text.isEmpty || damageCount <= 0) {
                            setModalState(() {
                              _damageCountError = true;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Pehle kitne box damage hue ye likhein!'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          final ImagePicker picker = ImagePicker();
                          final XFile? photo = await picker.pickImage(source: ImageSource.camera, imageQuality: 50);
                          if (photo != null) {
                            final permanentPath = await MediaService.saveImagePermanently(photo.path);
                            setModalState(() {
                              final List<String> updatedPhotos = List<String>.from(_damagePhotos);
                              updatedPhotos.add(permanentPath);
                              _damagePhotos = updatedPhotos;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 10),
                      if (_damagePhotos.isNotEmpty)
                        SizedBox(
                          height: 90,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _damagePhotos.length,
                            itemBuilder: (context, index) {
                              return Stack(
                                children: [
                                  Container(
                                    margin: const EdgeInsets.only(right: 8),
                                    child: Image.file(
                                      File(_damagePhotos[index]),
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
                                        setModalState(() {
                                          final List<String> updatedPhotos = List<String>.from(_damagePhotos);
                                          updatedPhotos.removeAt(index);
                                          _damagePhotos = updatedPhotos;
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
                    const SizedBox(height: 15),
                    DropdownButtonFormField<String>(
                      value: _selectedMode,
                      decoration: const InputDecoration(
                        labelText: 'Transport Mode',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.local_shipping),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Surface', child: Text('Surface')),
                        DropdownMenuItem(value: 'Road', child: Text('Road')),
                        DropdownMenuItem(value: 'Air', child: Text('Air')),
                        DropdownMenuItem(value: 'Train', child: Text('Train')),
                      ],
                      onChanged: (val) {
                        setModalState(() {
                          _selectedMode = val!;
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[800], foregroundColor: Colors.white),
                        onPressed: () => _saveAndClosePopup(sheetContext),
                        child: Text(_isNewDraft ? 'Add to Vehicle' : 'Update Box', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      _boxSearchFocusNode.unfocus();

      if (_isNewDraft && _editingBox != null && _editingBox!.consignmentNo.isEmpty) {
        widget.vehicleEntry.boxes.remove(_editingBox);
        widget.vehicleEntry.save();
        final box = Hive.box<VehicleEntry>('vehicle_entries');
        box.flush();
      }
      _editingBox = null;
      _editingIndex = null;

      if (mounted) {
        setState(() {});
      }
    });
  }

  // Naya: Complete Process Popup (End Photos)
  Future<void> _showCompleteProcessPopup() async {
    _boxSearchFocusNode.unfocus();

    int requiredEndPhotos = widget.vehicleEntry.vehicleStatus == 'Unloading' ? 1 : 2;
    bool skippedEndPhotos = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            bool canComplete = widget.vehicleEntry.endPhotos.length >= requiredEndPhotos || skippedEndPhotos;

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Complete Process', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text(
                    widget.vehicleEntry.vehicleStatus == 'Unloading'
                        ? '1. Empty Vehicle Photo'
                        : '1. Sealed Vehicle Photo\n2. Meter/KM Reading Photo',
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 15),

                  ElevatedButton.icon(
                    icon: const Icon(Icons.camera_alt, color: Colors.white),
                    label: Text(
                      widget.vehicleEntry.endPhotos.isEmpty ? 'Take End Photos' : 'Add More Photo',
                      style: const TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700]),
                    onPressed: () async {
                      final ImagePicker picker = ImagePicker();
                      final XFile? photo = await picker.pickImage(source: ImageSource.camera, imageQuality: 70);
                      if (photo != null) {
                        final permanentPath = await MediaService.saveImagePermanently(photo.path);
                        setModalState(() {
                          final List<String> updatedPhotos = List<String>.from(widget.vehicleEntry.endPhotos);
                          updatedPhotos.add(permanentPath);
                          widget.vehicleEntry.endPhotos = updatedPhotos;
                          widget.vehicleEntry.save();
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 10),

                  if (widget.vehicleEntry.endPhotos.isNotEmpty)
                    SizedBox(
                      height: 90,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: widget.vehicleEntry.endPhotos.length,
                        itemBuilder: (context, index) {
                          return Stack(
                            children: [
                              Container(
                                margin: const EdgeInsets.only(right: 8),
                                child: Image.file(
                                  File(widget.vehicleEntry.endPhotos[index]),
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
                                    setModalState(() {
                                      final List<String> updatedPhotos = List<String>.from(widget.vehicleEntry.endPhotos);
                                      updatedPhotos.removeAt(index);
                                      widget.vehicleEntry.endPhotos = updatedPhotos;
                                      widget.vehicleEntry.save();
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

                  const SizedBox(height: 20),
                  if (!canComplete)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          setModalState(() {
                            skippedEndPhotos = true;
                          });
                        },
                        child: const Text('Skip', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: canComplete ? Colors.green[800] : Colors.grey,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: canComplete ? () async {
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (BuildContext context) {
                            return const AlertDialog(
                              content: Row(
                                children: [
                                  CircularProgressIndicator(),
                                  SizedBox(width: 20),
                                  Text("Syncing to Google..."),
                                ],
                              ),
                            );
                          },
                        );

                        bool isSynced = await GoogleSyncService.syncToSheet(widget.vehicleEntry);

                        if (context.mounted) Navigator.pop(context);

                        widget.vehicleEntry.isCompleted = true;
                        widget.vehicleEntry.save();
                        final hiveBox = Hive.box<VehicleEntry>('vehicle_entries');
                        hiveBox.flush();

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(isSynced
                                  ? 'Process Complete & Synced to Google Sheet!'
                                  : 'Saved locally. Sync failed (No internet).'),
                              backgroundColor: isSynced ? Colors.green : Colors.orange,
                            ),
                          );
                        }

                        if (context.mounted) {
                          Navigator.pop(context);
                          Navigator.pop(context);
                        }
                      } : null,
                      child: const Text('Submit & Complete', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  if (!canComplete)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0, bottom: 10),
                      child: Text(
                        'Complete button lock hai. Pehle End Photos khinchye ya Skip dabayein.',
                        style: TextStyle(fontSize: 12, color: Colors.red[700]),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showTrashForThisVehicle() {
    _boxSearchFocusNode.unfocus();

    showModalBottomSheet(
      context: context,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final deletedBoxes = widget.vehicleEntry.boxes.where((b) => b.isDeleted).toList();

            return Container(
              padding: const EdgeInsets.all(16),
              height: MediaQuery.of(context).size.height * 0.6,
              child: Column(
                children: [
                  const Text('Trash (Deleted Boxes)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Divider(),
                  if (deletedBoxes.isEmpty)
                    const Expanded(
                      child: Center(
                        child: Text('Trash khaali hai.\nKoi box delete nahi hua.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.builder(
                        itemCount: deletedBoxes.length,
                        itemBuilder: (context, index) {
                          final box = deletedBoxes[index];
                          return ListTile(
                            title: Text(box.consignmentNo, style: const TextStyle(decoration: TextDecoration.lineThrough, color: Colors.grey)),
                            subtitle: Text(box.companyName),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.restore, color: Colors.green),
                                  tooltip: 'Restore',
                                  onPressed: () {
                                    setModalState(() {
                                      box.isDeleted = false;
                                      final idx = widget.vehicleEntry.boxes.indexOf(box);
                                      if (idx != -1) {
                                        widget.vehicleEntry.boxes[idx] = box;
                                      }
                                      widget.vehicleEntry.lastEditedAt = DateTime.now();
                                      widget.vehicleEntry.save();
                                      final hiveBox = Hive.box<VehicleEntry>('vehicle_entries');
                                      hiveBox.flush();
                                      deletedBoxes.removeAt(index);
                                    });
                                    setState(() {});
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('${box.consignmentNo} successfully restored!')),
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_forever, color: Colors.red),
                                  tooltip: 'Delete Permanently',
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (dialogContext) => AlertDialog(
                                        title: const Text('Delete Permanently?'),
                                        content: Text('Are you sure? ${box.consignmentNo} permanently delete ho jayega.'),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(dialogContext),
                                            child: const Text('Cancel'),
                                          ),
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                            onPressed: () {
                                              setModalState(() {
                                                widget.vehicleEntry.boxes.remove(box);
                                                widget.vehicleEntry.save();
                                                final hiveBox = Hive.box<VehicleEntry>('vehicle_entries');
                                                hiveBox.flush();
                                                deletedBoxes.removeAt(index);
                                              });
                                              setState(() {});
                                              Navigator.pop(dialogContext);
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text('${box.consignmentNo} permanently deleted!')),
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
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showExportMenu() {
    _boxSearchFocusNode.unfocus();

    final entry = widget.vehicleEntry;
    final activeBoxes = entry.boxes.where((b) => !b.isDeleted && b.consignmentNo.isNotEmpty).toList();

    final parentContext = context;
    final messenger = ScaffoldMessenger.of(parentContext);

    showModalBottomSheet(
      context: parentContext,
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Export & Share', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ListTile(
                  leading: const Icon(Icons.chat, color: Colors.green),
                  title: const Text('Export to WhatsApp'),
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    await ExportService.exportToWhatsApp(entry);
                  }
              ),
              ListTile(
                  leading: const Icon(Icons.photo, color: Colors.blue),
                  title: const Text('Export as Image (PNG)'),
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    try {
                      final slipWidget = _buildDigitalSlip(entry, activeBoxes);
                      final imageBytes = await _screenshotController.captureFromWidget(
                        slipWidget,
                        pixelRatio: 2.0,
                        context: parentContext,
                      );

                      final directory = await getApplicationDocumentsDirectory();
                      final file = await File('${directory.path}/LT_Operations_Slip.png').writeAsBytes(imageBytes);
                      await ExportService.shareImage(file, entry.vehicleNumber);
                    } catch (e) {
                      messenger.showSnackBar(
                        SnackBar(content: Text('Image export failed: $e')),
                      );
                    }
                  }
              ),
              ListTile(
                  leading: const Icon(Icons.table_view, color: Colors.orange),
                  title: const Text('Export to Excel'),
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    await ExportService.exportToExcel(entry);
                  }
              ),
              ListTile(
                  leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                  title: const Text('Export to PDF (High Quality)'),
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    try {
                      await ExportService.exportToPdf(entry);
                    } catch (e) {
                      messenger.showSnackBar(
                        SnackBar(content: Text('PDF export failed: $e')),
                      );
                    }
                  }
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDigitalSlip(VehicleEntry entry, List<BoxItem> activeBoxes) {
    bool hasDamagePhotos = activeBoxes.any((b) => b.isDamaged && b.damagePhotos.isNotEmpty);

    return Material(
      color: Colors.white,
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              color: Colors.blue[800],
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text('LT Operations', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                      Icon(Icons.local_shipping, color: Colors.white, size: 30),
                    ],
                  ),
                  const Text('Transport Supervisor Report', style: TextStyle(color: Colors.white70, fontSize: 14)),
                  const SizedBox(height: 10),
                  Text(
                    'Generated: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}  ${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(entry.vehicleNumber, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text('Driver: ${entry.driverName}', style: const TextStyle(fontSize: 14, color: Colors.black87)),
                            Text('Mobile: ${entry.driverMobile}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: entry.vehicleStatus == 'Loading' ? Colors.blue[100] : Colors.orange[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${entry.vehicleStatus} | ${entry.gateNumber}',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: entry.vehicleStatus == 'Loading' ? Colors.blue[800] : Colors.orange[800]
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      _buildMetricBox('Total Boxes', entry.totalReceivedBoxes.toString(), Colors.blue),
                      const SizedBox(width: 10),
                      _buildMetricBox('Shortage', entry.totalShortage.toString(), entry.totalShortage > 0 ? Colors.red : Colors.green),
                      const SizedBox(width: 10),
                      _buildMetricBox('Damaged', activeBoxes.fold(0, (sum, b) => sum + b.damagedCount).toString(), activeBoxes.any((b) => b.isDamaged) ? Colors.orange : Colors.green),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                    decoration: BoxDecoration(color: Colors.grey[200], borderRadius: const BorderRadius.vertical(top: Radius.circular(8))),
                    child: Row(
                      children: const [
                        Expanded(flex: 3, child: Text('Consignment', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                        Expanded(flex: 2, child: Text('Company', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                        Expanded(flex: 2, child: Text('Route', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                        Expanded(flex: 1, child: Text('Exp', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.center)),
                        Expanded(flex: 1, child: Text('Recv', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.center)),
                        Expanded(flex: 1, child: Text('Short', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.center)),
                        Expanded(flex: 1, child: Text('Mode', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.center)),
                      ],
                    ),
                  ),
                  ...activeBoxes.map((box) {
                    final shortage = box.shortage;
                    return Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                      decoration: BoxDecoration(
                        color: box.isDamaged ? Colors.red[50] : Colors.transparent,
                        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
                      ),
                      child: Row(
                        children: [
                          Expanded(flex: 3, child: Text(box.consignmentNo, style: const TextStyle(fontSize: 12))),
                          Expanded(flex: 2, child: Text(box.companyName, style: const TextStyle(fontSize: 12))),
                          Expanded(
                              flex: 2,
                              child: Text(
                                '${box.sourceLocation} To ${box.destinationLocation}',
                                style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic),
                                overflow: TextOverflow.ellipsis,
                              )
                          ),
                          Expanded(flex: 1, child: Text(box.expectedBoxes.toString(), style: const TextStyle(fontSize: 12), textAlign: TextAlign.center)),
                          Expanded(flex: 1, child: Text(box.receivedBoxes.toString(), style: const TextStyle(fontSize: 12), textAlign: TextAlign.center)),
                          Expanded(
                              flex: 1,
                              child: Text(
                                  shortage == 0 ? '0' : (shortage > 0 ? 'S:$shortage' : 'E:${-shortage}'),
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: shortage > 0 ? Colors.red : (shortage < 0 ? Colors.blue : Colors.black),
                                      fontWeight: FontWeight.bold
                                  ),
                                  textAlign: TextAlign.center
                              )
                          ),
                          Expanded(flex: 1, child: Text(box.transportMode, style: const TextStyle(fontSize: 10), textAlign: TextAlign.center)),
                        ],
                      ),
                    );
                  }).toList(),

                  if (hasDamagePhotos) ...[
                    const SizedBox(height: 20),
                    const Text('Damage Proof Photos', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red)),
                    const SizedBox(height: 10),
                    ...activeBoxes.where((b) => b.isDamaged && b.damagePhotos.isNotEmpty).map((box) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Consignment: ${box.consignmentNo}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: box.damagePhotos.map((path) {
                              return Image.file(
                                File(path),
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 10),
                        ],
                      );
                    }).toList(),
                  ],

                  const SizedBox(height: 30),
                  Row(
                    children: List.generate(
                        50,
                            (index) => Expanded(child: Container(height: 1, color: Colors.grey[400], margin: const EdgeInsets.symmetric(horizontal: 2)))
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Center(
                    child: Text(
                      'This is a computer-generated report from LT Operations App.',
                      style: TextStyle(fontSize: 10, color: Colors.grey, fontStyle: FontStyle.italic),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildMetricBox(String title, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.5))
        ),
        child: Column(
          children: [
            Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[700], fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.vehicleEntry;
    final allActiveBoxes = entry.boxes.where((b) => !b.isDeleted && b.consignmentNo.isNotEmpty).toList();

    final activeBoxes = _boxSearchQuery.isEmpty
        ? allActiveBoxes
        : allActiveBoxes.where((b) {
      final matchesConsignment = b.consignmentNo.toLowerCase().contains(_boxSearchQuery);
      final matchesCompany = b.companyName.toLowerCase().contains(_boxSearchQuery);
      final matchesExpected = b.expectedBoxes.toString().contains(_boxSearchQuery);
      final matchesReceived = b.receivedBoxes.toString().contains(_boxSearchQuery);
      final matchesMode = b.transportMode.toLowerCase().contains(_boxSearchQuery);
      final matchesSource = b.sourceLocation.toLowerCase().contains(_boxSearchQuery);
      final matchesDest = b.destinationLocation.toLowerCase().contains(_boxSearchQuery);
      return matchesConsignment || matchesCompany || matchesExpected || matchesReceived || matchesMode || matchesSource || matchesDest;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Box Counting', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share, color: Colors.white),
            tooltip: 'Export & Share',
            onPressed: _showExportMenu,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              _boxSearchFocusNode.unfocus();
              if (value == 'done') {
                if (!entry.isCompleted) {
                  _showCompleteProcessPopup();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('This vehicle process is already completed.')),
                  );
                }
              } else if (value == 'gallery') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => VehicleMediaGalleryScreen(vehicleEntry: widget.vehicleEntry),
                  ),
                ).then((_) {
                  if (mounted) setState(() {});
                });
              } else if (value == 'edit') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => VehicleEntryScreen(existingEntry: widget.vehicleEntry),
                  ),
                ).then((_) {
                  if (mounted) setState(() {});
                });
              } else if (value == 'trash') {
                _showTrashForThisVehicle();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'done',
                child: ListTile(
                  leading: Icon(
                      Icons.check_circle,
                      color: entry.isCompleted ? Colors.green : Colors.blue[800]
                  ),
                  title: Text(
                    entry.isCompleted ? 'Process Completed' : 'Complete Process',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: entry.isCompleted ? Colors.green : Colors.black87
                    ),
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'edit',
                child: ListTile(
                  leading: Icon(Icons.edit_document, color: Colors.blue),
                  title: Text('Edit Vehicle Details'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'gallery',
                child: ListTile(
                  leading: Icon(Icons.photo_library, color: Colors.purple),
                  title: Text('Media Gallery'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'trash',
                child: ListTile(
                  leading: Icon(Icons.delete_outline, color: Colors.red),
                  title: Text('Deleted Boxes'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () {
          FocusManager.instance.primaryFocus?.unfocus();
        },
        behavior: HitTestBehavior.opaque,
        child: Column(
          children: [
            Container(
              width: double.infinity,
              color: Colors.grey[200],
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(entry.vehicleNumber, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      Text(entry.driverName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(entry.driverMobile, style: const TextStyle(fontSize: 14, color: Colors.grey)),
                  const Divider(thickness: 1, height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total Boxes: ${entry.totalReceivedBoxes}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      Flexible(
                        child: Text(
                              () {
                            String status = '';
                            if (entry.totalShortage > 0) status += 'Short: ${entry.totalShortage}  ';
                            if (entry.totalExtra > 0) status += 'Extra: ${entry.totalExtra}  ';
                            if (entry.totalDamaged > 0) status += 'Damaged: ${entry.totalDamaged}';
                            if (status.isEmpty) status = 'All Perfect';
                            return status.trim();
                          }(),
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: (entry.totalShortage > 0 || entry.totalDamaged > 0) ? Colors.red : (entry.totalExtra > 0 ? Colors.blue : Colors.green)
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Total Consignment Entries: ${allActiveBoxes.length}',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black54),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
              child: TextField(
                controller: _boxSearchController,
                focusNode: _boxSearchFocusNode,
                onChanged: (val) {
                  setState(() {
                    _boxSearchQuery = val.toLowerCase();
                  });
                },
                decoration: InputDecoration(
                  labelText: 'Search Consignment, Company, Mode, Location...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _boxSearchQuery.isNotEmpty
                      ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _boxSearchController.clear();
                      setState(() {
                        _boxSearchQuery = '';
                      });
                    },
                  )
                      : null,
                ),
              ),
            ),
            if (_boxSearchQuery.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 2.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${activeBoxes.length} consignments found',
                    style: const TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic),
                  ),
                ),
              ),
            Expanded(
              child: activeBoxes.isEmpty
                  ? Center(
                child: Text(
                  _boxSearchQuery.isEmpty
                      ? 'Koi box add nahi hua. \n+ dabakar box add karein.'
                      : 'Koi box is search se match nahi hua.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
              )
                  : ListView.builder(
                controller: _listScrollController,
                padding: const EdgeInsets.all(12),
                itemCount: activeBoxes.length,
                itemBuilder: (context, index) {
                  final box = activeBoxes[index];
                  final shortage = box.shortage;
                  final originalIndex = entry.boxes.indexOf(box);

                  return Card(
                    color: box.isDamaged ? Colors.red[50] : Colors.white,
                    shape: RoundedRectangleBorder(
                      side: BorderSide(
                        color: box.isDamaged
                            ? Colors.red
                            : (shortage > 0 ? Colors.orange : (shortage < 0 ? Colors.blue : Colors.transparent)),
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(box.consignmentNo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                const SizedBox(height: 2),
                                Text(box.companyName, style: TextStyle(color: Colors.grey[700], fontSize: 13)),
                                const SizedBox(height: 4),
                                if (box.sourceLocation.isNotEmpty || box.destinationLocation.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 4.0),
                                    child: Text(
                                      'Route: ${box.sourceLocation} To ${box.destinationLocation}',
                                      style: TextStyle(fontSize: 12, color: Colors.teal[700], fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                Row(
                                  children: [
                                    Text(
                                      'Exp: ${box.expectedBoxes} | Recv: ${box.receivedBoxes} ',
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                                    ),
                                    if (shortage == 0)
                                      const Icon(Icons.check_circle, color: Colors.green, size: 16)
                                    else if (shortage > 0)
                                      Text(' (Short: $shortage)', style: const TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.bold))
                                    else if (shortage < 0)
                                        Text(' (Extra: ${-shortage})', style: const TextStyle(color: Colors.blue, fontSize: 13, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                Text(
                                  'Mode: ${box.transportMode}',
                                  style: TextStyle(fontSize: 13, color: Colors.purple[700], fontWeight: FontWeight.w500),
                                ),
                                if (box.isDamaged)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2.0),
                                    child: Text(
                                      'Damaged: ${box.damagedCount}',
                                      style: TextStyle(fontSize: 13, color: Colors.red[700], fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                if (box.createdAt != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4.0),
                                    child: Text(
                                      'Added at ${box.createdAt!.hour.toString().padLeft(2, '0')}:${box.createdAt!.minute.toString().padLeft(2, '0')} Date: ${box.createdAt!.day}/${box.createdAt!.month}/${box.createdAt!.year}',
                                      style: const TextStyle(fontSize: 10, color: Colors.grey, fontStyle: FontStyle.italic),
                                    ),
                                  ),
                                if (box.lastEditedAt != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2.0),
                                    child: Text(
                                      'Edited at ${box.lastEditedAt!.hour.toString().padLeft(2, '0')}:${box.lastEditedAt!.minute.toString().padLeft(2, '0')} Date: ${box.lastEditedAt!.day}/${box.lastEditedAt!.month}/${box.lastEditedAt!.year}',
                                      style: const TextStyle(fontSize: 10, color: Colors.blueGrey, fontStyle: FontStyle.italic),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Column(
                            children: [
                              IconButton(
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                                onPressed: () => _showBoxPopup(boxToEdit: box, index: originalIndex),
                              ),
                              const SizedBox(height: 16),
                              IconButton(
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                onPressed: () {
                                  setState(() {
                                    box.isDeleted = true;
                                    final idx = widget.vehicleEntry.boxes.indexOf(box);
                                    if (idx != -1) {
                                      widget.vehicleEntry.boxes[idx] = box;
                                    }
                                    widget.vehicleEntry.lastEditedAt = DateTime.now();
                                    widget.vehicleEntry.save();
                                    final hiveBox = Hive.box<VehicleEntry>('vehicle_entries');
                                    hiveBox.flush();
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('${box.consignmentNo} Trash me bhej diya gaya!')),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
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
        onPressed: () {
          _boxSearchFocusNode.unfocus();
          _showBoxPopup();
        },
        backgroundColor: Colors.blue[800],
        icon: const Icon(Icons.add, color: Colors.white, size: 32),
        label: const Text(
            'Add Box',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)
        ),
      ),
    );
  }
}