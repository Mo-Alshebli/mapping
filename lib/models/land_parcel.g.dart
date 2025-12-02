// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'land_parcel.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LandParcelAdapter extends TypeAdapter<LandParcel> {
  @override
  final int typeId = 0;

  @override
  LandParcel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LandParcel(
      id: fields[0] as String,
      name: fields[1] as String,
      coordinates: (fields[2] as List).cast<LatLngPoint>(),
      centroid: fields[3] as LatLngPoint,
      area: fields[4] as double,
      cropType: fields[5] as String?,
      createdAt: fields[6] as DateTime,
      lastUpdated: fields[7] as DateTime?,
      statistics: fields[8] as CropStatistics?,
      ndviLayer: fields[9] as NDVILayer?,
      shape: fields[10] as DrawShape?,
      size: fields[11] as double?,
    );
  }

  @override
  void write(BinaryWriter writer, LandParcel obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.coordinates)
      ..writeByte(3)
      ..write(obj.centroid)
      ..writeByte(4)
      ..write(obj.area)
      ..writeByte(5)
      ..write(obj.cropType)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.lastUpdated)
      ..writeByte(8)
      ..write(obj.statistics)
      ..writeByte(9)
      ..write(obj.ndviLayer)
      ..writeByte(10)
      ..write(obj.shape)
      ..writeByte(11)
      ..write(obj.size);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LandParcelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class LatLngPointAdapter extends TypeAdapter<LatLngPoint> {
  @override
  final int typeId = 1;

  @override
  LatLngPoint read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LatLngPoint(
      latitude: fields[0] as double,
      longitude: fields[1] as double,
    );
  }

  @override
  void write(BinaryWriter writer, LatLngPoint obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.latitude)
      ..writeByte(1)
      ..write(obj.longitude);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LatLngPointAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
