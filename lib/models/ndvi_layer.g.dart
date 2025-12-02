// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ndvi_layer.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class NDVILayerAdapter extends TypeAdapter<NDVILayer> {
  @override
  final int typeId = 4;

  @override
  NDVILayer read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return NDVILayer(
      id: fields[0] as String,
      overlayUrl: fields[1] as String,
      bounds: fields[2] as NDVIBounds,
      opacity: fields[3] as double,
      isVisible: fields[4] as bool,
      captureDate: fields[5] as DateTime,
      source: fields[6] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, NDVILayer obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.overlayUrl)
      ..writeByte(2)
      ..write(obj.bounds)
      ..writeByte(3)
      ..write(obj.opacity)
      ..writeByte(4)
      ..write(obj.isVisible)
      ..writeByte(5)
      ..write(obj.captureDate)
      ..writeByte(6)
      ..write(obj.source);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NDVILayerAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class NDVIBoundsAdapter extends TypeAdapter<NDVIBounds> {
  @override
  final int typeId = 5;

  @override
  NDVIBounds read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return NDVIBounds(
      north: fields[0] as double,
      south: fields[1] as double,
      east: fields[2] as double,
      west: fields[3] as double,
    );
  }

  @override
  void write(BinaryWriter writer, NDVIBounds obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.north)
      ..writeByte(1)
      ..write(obj.south)
      ..writeByte(2)
      ..write(obj.east)
      ..writeByte(3)
      ..write(obj.west);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NDVIBoundsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
