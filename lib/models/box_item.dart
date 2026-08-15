import 'package:hive/hive.dart';

part 'box_item.g.dart';

@HiveType(typeId: 1)
class BoxItem extends HiveObject {
  @HiveField(0)
  String consignmentNo;

  @HiveField(1)
  String companyName;

  @HiveField(2)
  int expectedBoxes;

  @HiveField(3)
  int receivedBoxes;

  @HiveField(4)
  bool isDamaged;

  @HiveField(5)
  bool isDeleted;

  @HiveField(6)
  int damagedCount;

  @HiveField(7)
  String damageDetails;

  @HiveField(8)
  List<String> damagePhotos;

  @HiveField(9)
  DateTime? lastEditedAt;

  @HiveField(10)
  DateTime? createdAt;

  @HiveField(11)
  String transportMode;

  @HiveField(12) // Naya field
  String sourceLocation;

  @HiveField(13) // Naya field
  String destinationLocation;

  BoxItem({
    required this.consignmentNo,
    required this.companyName,
    required this.expectedBoxes,
    required this.receivedBoxes,
    this.isDamaged = false,
    this.isDeleted = false,
    this.damagedCount = 0,
    this.damageDetails = '',
    this.damagePhotos = const [],
    this.lastEditedAt,
    this.createdAt,
    this.transportMode = 'Surface',
    this.sourceLocation = '',
    this.destinationLocation = '',
  });

  int get shortage => expectedBoxes - receivedBoxes;

  Map<String, dynamic> toJson() => {
    'consignmentNo': consignmentNo,
    'companyName': companyName,
    'expectedBoxes': expectedBoxes,
    'receivedBoxes': receivedBoxes,
    'isDamaged': isDamaged,
    'isDeleted': isDeleted,
    'damagedCount': damagedCount,
    'damageDetails': damageDetails,
    'createdAt': createdAt?.toIso8601String(),
    'lastEditedAt': lastEditedAt?.toIso8601String(),
    'transportMode': transportMode,
    'sourceLocation': sourceLocation,
    'destinationLocation': destinationLocation,
  };

  factory BoxItem.fromJson(Map<String, dynamic> json) {
    return BoxItem(
      consignmentNo: json['consignmentNo'] as String,
      companyName: json['companyName'] as String,
      expectedBoxes: json['expectedBoxes'] as int,
      receivedBoxes: json['receivedBoxes'] as int,
      isDamaged: json['isDamaged'] as bool,
      isDeleted: json['isDeleted'] as bool,
      damagedCount: json['damagedCount'] as int,
      damageDetails: json['damageDetails'] as String,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : null,
      lastEditedAt: json['lastEditedAt'] != null ? DateTime.parse(json['lastEditedAt'] as String) : null,
      transportMode: json['transportMode'] as String? ?? 'Surface',
      sourceLocation: json['sourceLocation'] as String? ?? '',
      destinationLocation: json['destinationLocation'] as String? ?? '',
    );
  }
}