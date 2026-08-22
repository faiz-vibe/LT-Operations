// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vehicle_entry.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class VehicleEntryAdapter extends TypeAdapter<VehicleEntry> {
  @override
  final int typeId = 0;

  @override
  VehicleEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return VehicleEntry(
      vehicleNumber: fields[0] as String,
      driverName: fields[1] as String,
      driverMobile: fields[2] as String,
      boxes: (fields[3] as List).cast<BoxItem>(),
      entryDate: fields[4] as DateTime,
      isCompleted: fields[5] as bool,
      signaturePath: fields[6] as String?,
      vehicleStatus: fields[7] as String,
      isDeleted: fields[8] as bool,
      gateNumber: fields[9] as String,
      lastEditedAt: fields[10] as DateTime?,
      startPhotos: (fields[11] as List).cast<String>(),
      endPhotos: (fields[12] as List).cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, VehicleEntry obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.vehicleNumber)
      ..writeByte(1)
      ..write(obj.driverName)
      ..writeByte(2)
      ..write(obj.driverMobile)
      ..writeByte(3)
      ..write(obj.boxes)
      ..writeByte(4)
      ..write(obj.entryDate)
      ..writeByte(5)
      ..write(obj.isCompleted)
      ..writeByte(6)
      ..write(obj.signaturePath)
      ..writeByte(7)
      ..write(obj.vehicleStatus)
      ..writeByte(8)
      ..write(obj.isDeleted)
      ..writeByte(9)
      ..write(obj.gateNumber)
      ..writeByte(10)
      ..write(obj.lastEditedAt)
      ..writeByte(11)
      ..write(obj.startPhotos)
      ..writeByte(12)
      ..write(obj.endPhotos);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VehicleEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
