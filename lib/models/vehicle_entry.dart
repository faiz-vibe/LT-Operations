import 'package:hive/hive.dart';
import 'box_item.dart';

part 'vehicle_entry.g.dart';

@HiveType(typeId: 0)
class VehicleEntry extends HiveObject {
  @HiveField(0)
  String vehicleNumber;

  @HiveField(1)
  String driverName;

  @HiveField(2)
  String driverMobile;

  @HiveField(3)
  List<BoxItem> boxes;

  @HiveField(4)
  DateTime entryDate;

  @HiveField(5)
  bool isCompleted;

  @HiveField(6)
  String? signaturePath;

  @HiveField(7)
  String vehicleStatus;

  @HiveField(8)
  bool isDeleted;

  @HiveField(9)
  String gateNumber;

  @HiveField(10)
  DateTime? lastEditedAt;

  @HiveField(11) // Naya field
  List<String> startPhotos;

  @HiveField(12) // Naya field
  List<String> endPhotos;

  VehicleEntry({
    required this.vehicleNumber,
    required this.driverName,
    required this.driverMobile,
    required this.boxes,
    required this.entryDate,
    this.isCompleted = false,
    this.signaturePath,
    this.vehicleStatus = 'Unloading',
    this.isDeleted = false,
    this.gateNumber = 'Gate 1',
    this.lastEditedAt,
    this.startPhotos = const [],
    this.endPhotos = const [],
  });

  int get totalReceivedBoxes => boxes.where((b) => !b.isDeleted).fold(0, (sum, item) => sum + item.receivedBoxes);

  // Naya Logic: Shortage aur Extra alag alag calculate honge
  int get totalShortage => boxes.where((b) => !b.isDeleted).fold(0, (sum, item) => sum + (item.shortage > 0 ? item.shortage : 0));
  int get totalExtra => boxes.where((b) => !b.isDeleted).fold(0, (sum, item) => sum + (item.shortage < 0 ? -item.shortage : 0));
  int get totalDamaged => boxes.where((b) => !b.isDeleted).fold(0, (sum, item) => sum + item.damagedCount);

  Map<String, dynamic> toJson() => {
    'vehicleNumber': vehicleNumber,
    'driverName': driverName,
    'driverMobile': driverMobile,
    'boxes': boxes.map((b) => b.toJson()).toList(),
    'entryDate': entryDate.toIso8601String(),
    'isCompleted': isCompleted,
    'vehicleStatus': vehicleStatus,
    'isDeleted': isDeleted,
    'gateNumber': gateNumber,
    'lastEditedAt': lastEditedAt?.toIso8601String(),
    'startPhotos': startPhotos,
    'endPhotos': endPhotos,
  };

  factory VehicleEntry.fromJson(Map<String, dynamic> json) {
    return VehicleEntry(
      vehicleNumber: json['vehicleNumber'] as String,
      driverName: json['driverName'] as String,
      driverMobile: json['driverMobile'] as String,
      boxes: (json['boxes'] as List).map((b) => BoxItem.fromJson(b as Map<String, dynamic>)).toList(),
      entryDate: DateTime.parse(json['entryDate'] as String),
      isCompleted: json['isCompleted'] as bool,
      vehicleStatus: json['vehicleStatus'] as String,
      isDeleted: json['isDeleted'] as bool,
      gateNumber: json['gateNumber'] as String,
      lastEditedAt: json['lastEditedAt'] != null ? DateTime.parse(json['lastEditedAt'] as String) : null,
      startPhotos: List<String>.from(json['startPhotos'] as List? ?? []),
      endPhotos: List<String>.from(json['endPhotos'] as List? ?? []),
    );
  }
}