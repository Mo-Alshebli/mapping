// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'crop_statistics.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CropStatisticsAdapter extends TypeAdapter<CropStatistics> {
  @override
  final int typeId = 2;

  @override
  CropStatistics read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CropStatistics(
      healthPercentage: fields[0] as double,
      moistureLevel: fields[1] as double,
      lastIrrigationDate: fields[2] as DateTime?,
      ndviValue: fields[3] as double,
      distribution: (fields[4] as Map).cast<String, double>(),
      history: (fields[5] as List?)?.cast<HistoricalData>(),
    );
  }

  @override
  void write(BinaryWriter writer, CropStatistics obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.healthPercentage)
      ..writeByte(1)
      ..write(obj.moistureLevel)
      ..writeByte(2)
      ..write(obj.lastIrrigationDate)
      ..writeByte(3)
      ..write(obj.ndviValue)
      ..writeByte(4)
      ..write(obj.distribution)
      ..writeByte(5)
      ..write(obj.history);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CropStatisticsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class HistoricalDataAdapter extends TypeAdapter<HistoricalData> {
  @override
  final int typeId = 3;

  @override
  HistoricalData read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HistoricalData(
      date: fields[0] as DateTime,
      value: fields[1] as double,
      type: fields[2] as String,
    );
  }

  @override
  void write(BinaryWriter writer, HistoricalData obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.date)
      ..writeByte(1)
      ..write(obj.value)
      ..writeByte(2)
      ..write(obj.type);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HistoricalDataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
