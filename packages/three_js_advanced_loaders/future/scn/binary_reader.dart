import 'dart:typed_data';

extension Buffer on Uint8List{
  int readIntBE(int offset,int byteLength) {
    switch(byteLength){
      case 1:
        return buffer.asByteData().getInt8(offset);
      case 2:
        return buffer.asByteData().getInt16(offset, Endian.big);
      case 4:
        return buffer.asByteData().getInt32(offset, Endian.big);
      case 8:
        return buffer.asByteData().getInt64(offset, Endian.big);
    }
    throw("readIntBE: Invalid type.");
  }

  int readIntLE(int offset,int byteLength) {
    switch(byteLength){
      case 1:
        return buffer.asByteData().getInt8(offset);
      case 2:
        return buffer.asByteData().getInt16(offset, Endian.little);
      case 4:
        return buffer.asByteData().getInt32(offset, Endian.little);
      case 8:
        return buffer.asByteData().getInt64(offset, Endian.little);
    }
    throw("readIntBE: Invalid type.");
  }
  int readUintBE(int offset,int byteLength) {
    switch(byteLength){
      case 1:
        return buffer.asByteData().getUint8(offset);
      case 2:
        return buffer.asByteData().getUint16(offset, Endian.big);
      case 4:
        return buffer.asByteData().getUint32(offset, Endian.big);
      case 8:
        return buffer.asByteData().getUint64(offset, Endian.big);
    }
    throw("readIntBE: Invalid type.");
  }

  int readUintLE(int offset,int byteLength) {
    switch(byteLength){
      case 1:
        return buffer.asByteData().getUint8(offset);
      case 2:
        return buffer.asByteData().getUint16(offset, Endian.little);
      case 4:
        return buffer.asByteData().getUint32(offset, Endian.little);
      case 8:
        return buffer.asByteData().getUint64(offset, Endian.little);
    }
    throw("readIntBE: Invalid type.");
  }

  double readFloatBE(int offset) {
    return buffer.asByteData().getFloat32(offset, Endian.big);
  }

  double readFloatLE(int offset) {
    return buffer.asByteData().getFloat32(offset, Endian.little);
  }

  double readDoubleBE(int offset) {
    return buffer.asByteData().getFloat64(offset, Endian.big);
  }

  double readDoubleLE(int offset) {
    return buffer.asByteData().getFloat64(offset, Endian.little);
  }
}