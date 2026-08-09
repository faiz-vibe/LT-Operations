// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'box_item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BoxItemAdapter extends TypeAdapter<BoxItem> {
  @override
  final int typeId = 1;

  @override
  BoxItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BoxItem(
      consignmentNo: fields[0] as String,
      companyName: fields[1] as String,
      expectedBoxes: fields[2] as int,
      receivedBoxes: fields[3] as int,
      isDamaged: fields[4] as bool,
      isDeleted: fields[5] as bool,
      damagedCount: fields[6] as int,
      damageDetails: fields[7] as String,
      damagePhotos: (fields[8] as List).cast<String>(),
      lastEditedAt: fields[9] as DateTime?,
      createdAt: fields[10] as DateTime?,
      transportMode: fields[11] as String,
    );
  }

  @override
  void write(BinaryWriter writer, BoxItem obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.consignmentNo)
      ..writeByte(1)
      ..write(obj.companyName)
      ..writeByte(2)
      ..write(obj.expectedBoxes)
      ..writeByte(3)
      ..write(obj.receivedBoxes)
      ..writeByte(4)
      ..write(obj.isDamaged)
      ..writeByte(5)
      ..write(obj.isDeleted)
      ..writeByte(6)
      ..write(obj.damagedCount)
      ..writeByte(7)
      ..write(obj.damageDetails)
      ..writeByte(8)
      ..write(obj.damagePhotos)
      ..writeByte(9)
      ..write(obj.lastEditedAt)
      ..writeByte(10)
      ..write(obj.createdAt)
      ..writeByte(11)
      ..write(obj.transportMode);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BoxItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
