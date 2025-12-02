// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'draw_shape.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DrawShapeAdapter extends TypeAdapter<DrawShape> {
  @override
  final int typeId = 6;

  @override
  DrawShape read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return DrawShape.point;
      case 1:
        return DrawShape.circle;
      case 2:
        return DrawShape.square;
      case 3:
        return DrawShape.star;
      case 4:
        return DrawShape.freehand;
      default:
        return DrawShape.point;
    }
  }

  @override
  void write(BinaryWriter writer, DrawShape obj) {
    switch (obj) {
      case DrawShape.point:
        writer.writeByte(0);
        break;
      case DrawShape.circle:
        writer.writeByte(1);
        break;
      case DrawShape.square:
        writer.writeByte(2);
        break;
      case DrawShape.star:
        writer.writeByte(3);
        break;
      case DrawShape.freehand:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DrawShapeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
