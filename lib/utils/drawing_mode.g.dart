// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'drawing_mode.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DrawingModeAdapter extends TypeAdapter<DrawingMode> {
  @override
  final int typeId = 7;

  @override
  DrawingMode read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return DrawingMode.predefinedShape;
      case 1:
        return DrawingMode.customPoints;
      case 2:
        return DrawingMode.freehand;
      default:
        return DrawingMode.predefinedShape;
    }
  }

  @override
  void write(BinaryWriter writer, DrawingMode obj) {
    switch (obj) {
      case DrawingMode.predefinedShape:
        writer.writeByte(0);
        break;
      case DrawingMode.customPoints:
        writer.writeByte(1);
        break;
      case DrawingMode.freehand:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DrawingModeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PredefinedShapeAdapter extends TypeAdapter<PredefinedShape> {
  @override
  final int typeId = 8;

  @override
  PredefinedShape read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return PredefinedShape.circle;
      case 2:
        return PredefinedShape.square;
      case 4:
        return PredefinedShape.trapezoid;
      case 5:
        return PredefinedShape.ellipse;
      default:
        return PredefinedShape.circle;
    }
  }

  @override
  void write(BinaryWriter writer, PredefinedShape obj) {
    switch (obj) {
      case PredefinedShape.circle:
        writer.writeByte(0);
        break;
      case PredefinedShape.square:
        writer.writeByte(2);
        break;
      case PredefinedShape.trapezoid:
        writer.writeByte(4);
        break;
      case PredefinedShape.ellipse:
        writer.writeByte(5);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PredefinedShapeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class AreaUnitAdapter extends TypeAdapter<AreaUnit> {
  @override
  final int typeId = 9;

  @override
  AreaUnit read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return AreaUnit.squareMeters;
      case 1:
        return AreaUnit.donum;
      case 2:
        return AreaUnit.hectare;
      case 3:
        return AreaUnit.feddan;
      default:
        return AreaUnit.squareMeters;
    }
  }

  @override
  void write(BinaryWriter writer, AreaUnit obj) {
    switch (obj) {
      case AreaUnit.squareMeters:
        writer.writeByte(0);
        break;
      case AreaUnit.donum:
        writer.writeByte(1);
        break;
      case AreaUnit.hectare:
        writer.writeByte(2);
        break;
      case AreaUnit.feddan:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AreaUnitAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
