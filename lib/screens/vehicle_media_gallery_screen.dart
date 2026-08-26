import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../models/vehicle_entry.dart';
import '../models/box_item.dart';
import '../services/media_service.dart'; // Naya Import

class VehicleMediaGalleryScreen extends StatefulWidget {
  final VehicleEntry vehicleEntry;

  const VehicleMediaGalleryScreen({super.key, required this.vehicleEntry});

  @override
  State<VehicleMediaGalleryScreen> createState() => _VehicleMediaGalleryScreenState();
}

class _VehicleMediaGalleryScreenState extends State<VehicleMediaGalleryScreen> {
  late VehicleEntry _entry;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _entry = widget.vehicleEntry;
  }

  // Full Screen View (Zoomable)
  void _viewPhoto(String path) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        child: InteractiveViewer(
          panEnabled: true,
          minScale: 0.5,
          maxScale: 4.0,
          child: Image.file(File(path)),
        ),
      ),
    );
  }

  // Photo Delete Logic (Null-Safe)
  void _deletePhoto(String category, int index, BoxItem? boxItem) {
    setState(() {
      if (category == 'Start') {
        final list = List<String>.from(_entry.startPhotos);
        list.removeAt(index);
        _entry.startPhotos = list;
        _entry.save();
      } else if (category == 'End') {
        final list = List<String>.from(_entry.endPhotos);
        list.removeAt(index);
        _entry.endPhotos = list;
        _entry.save();
      } else if (category == 'Damage' && boxItem != null) {
        final list = List<String>.from(boxItem.damagePhotos);
        list.removeAt(index);
        boxItem.damagePhotos = list;
        boxItem.save();
      }
    });
  }

  // Photo Replace Logic (Null-Safe)
  Future<void> _replacePhoto(String category, int index, BoxItem? boxItem) async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera, imageQuality: 70);
    if (photo == null) return;

    // MediaService ka use kiya gaya hai
    final newPath = await MediaService.saveImagePermanently(photo.path);

    setState(() {
      if (category == 'Start') {
        final list = List<String>.from(_entry.startPhotos);
        list[index] = newPath;
        _entry.startPhotos = list;
        _entry.save();
      } else if (category == 'End') {
        final list = List<String>.from(_entry.endPhotos);
        list[index] = newPath;
        _entry.endPhotos = list;
        _entry.save();
      } else if (category == 'Damage' && boxItem != null) {
        final list = List<String>.from(boxItem.damagePhotos);
        list[index] = newPath;
        boxItem.damagePhotos = list;
        boxItem.save();
      }
    });
  }

  // Add Photo Logic
  Future<void> _addPhoto(String category) async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera, imageQuality: 70);
    if (photo == null) return;

    // MediaService ka use kiya gaya hai
    final newPath = await MediaService.saveImagePermanently(photo.path);

    setState(() {
      if (category == 'Start') {
        final list = List<String>.from(_entry.startPhotos);
        list.add(newPath);
        _entry.startPhotos = list;
        _entry.save();
      } else if (category == 'End') {
        final list = List<String>.from(_entry.endPhotos);
        list.add(newPath);
        _entry.endPhotos = list;
        _entry.save();
      } else if (category == 'Damage') {
        _showAddDamagePhotoDialog(newPath);
      }
    });
  }

  // Damage photo add karne ke liye consignment select karne ka dialog
  void _showAddDamagePhotoDialog(String newPath) {
    final activeBoxes = _entry.boxes.where((b) => !b.isDeleted && b.consignmentNo.isNotEmpty).toList();
    if (activeBoxes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pehle Box Counting page par koi consignment add karein!'), backgroundColor: Colors.red),
      );
      return;
    }

    BoxItem? selectedBox = activeBoxes.first;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            title: const Text('Select Consignment'),
            content: DropdownButton<BoxItem>(
              value: selectedBox,
              isExpanded: true,
              items: activeBoxes.map((b) => DropdownMenuItem(value: b, child: Text(b.consignmentNo))).toList(),
              onChanged: (val) => setModalState(() => selectedBox = val),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () {
                  if (selectedBox != null) {
                    setState(() {
                      final list = List<String>.from(selectedBox!.damagePhotos);
                      list.add(newPath);
                      selectedBox!.damagePhotos = list;
                      selectedBox!.save();
                    });
                    Navigator.pop(context);
                  }
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeBoxes = _entry.boxes.where((b) => !b.isDeleted && b.consignmentNo.isNotEmpty).toList();

    // Calculate total damage photos safely
    int totalDamagePhotos = 0;
    for (var b in activeBoxes) {
      totalDamagePhotos += b.damagePhotos.length;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vehicle Media Gallery', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection('Start Photos', _entry.startPhotos, 'Start'),
          const SizedBox(height: 24),
          _buildSection('End Photos', _entry.endPhotos, 'End'),
          const SizedBox(height: 24),
          _buildDamageSection('Damage Photos', activeBoxes, totalDamagePhotos),
        ],
      ),
    );
  }

  // Section Builder (Start & End)
  Widget _buildSection(String title, List<String> photos, String category) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
            ElevatedButton.icon(
              onPressed: () => _addPhoto(category),
              icon: const Icon(Icons.add_a_photo, size: 18),
              label: const Text('Add'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[800], foregroundColor: Colors.white),
            ),
          ],
        ),
        const SizedBox(height: 12),
        photos.isEmpty
            ? Container(
          height: 100,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
          child: const Text('No photos added', style: TextStyle(color: Colors.grey)),
        )
            : GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: photos.length,
          itemBuilder: (context, index) {
            return _buildPhotoTile(photos[index], category, index, null);
          },
        ),
      ],
    );
  }

  // Damage Section Builder
  Widget _buildDamageSection(String title, List<BoxItem> activeBoxes, int totalPhotos) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
            ElevatedButton.icon(
              onPressed: () => _addPhoto('Damage'),
              icon: const Icon(Icons.add_a_photo, size: 18),
              label: const Text('Add'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red[700], foregroundColor: Colors.white),
            ),
          ],
        ),
        const SizedBox(height: 12),
        totalPhotos == 0
            ? Container(
          height: 100,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
          child: const Text('No damage photos added', style: TextStyle(color: Colors.grey)),
        )
            : GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 0.8,
          ),
          itemCount: totalPhotos,
          itemBuilder: (context, index) {
            int count = 0;
            for (var box in activeBoxes) {
              if (count + box.damagePhotos.length > index) {
                final photoIndex = index - count;
                return _buildPhotoTile(box.damagePhotos[photoIndex], 'Damage', photoIndex, box, consignmentNo: box.consignmentNo);
              }
              count += box.damagePhotos.length;
            }
            return const SizedBox();
          },
        ),
      ],
    );
  }

  // Photo Tile Widget
  Widget _buildPhotoTile(String path, String category, int index, BoxItem? boxItem, {String? consignmentNo}) {
    return Stack(
      children: [
        GestureDetector(
          onTap: () => _viewPhoto(path),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              File(path),
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
        ),
        if (consignmentNo != null)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
              color: Colors.black54,
              child: Text(
                consignmentNo,
                style: const TextStyle(color: Colors.white, fontSize: 10),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        Positioned(
          top: 4,
          right: 4,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              shape: BoxShape.circle,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () => _replacePhoto(category, index, boxItem),
                  child: const Padding(
                    padding: EdgeInsets.all(4.0),
                    child: Icon(Icons.refresh, color: Colors.white, size: 16),
                  ),
                ),
                GestureDetector(
                  onTap: () => _deletePhoto(category, index, boxItem),
                  child: const Padding(
                    padding: EdgeInsets.all(4.0),
                    child: Icon(Icons.close, color: Colors.redAccent, size: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}