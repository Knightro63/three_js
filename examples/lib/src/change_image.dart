import 'dart:typed_data';

Uint8List rgba2bitmap(
  Uint8List content, 
  int width, 
  int height
) {
  const int headerSize = 122;
  final int contentSize = content.length;
  final int fileLength =  contentSize + headerSize;

  final Uint8List headerIntList = Uint8List(fileLength);

  final ByteData bd = headerIntList.buffer.asByteData();
  bd.setUint8(0x0, 0x42);
  bd.setUint8(0x1, 0x4d);
  bd.setInt32(0x2, fileLength, Endian.little);
  bd.setInt32(0xa, headerSize, Endian.little);
  bd.setUint32(0xe, 108, Endian.little);
  bd.setUint32(0x12, width, Endian.little);
  bd.setUint32(0x16, -height, Endian.little);//-height
  bd.setUint16(0x1a, 1, Endian.little);
  bd.setUint32(0x1c, 32, Endian.little); // pixel size
  bd.setUint32(0x1e, 3, Endian.little); //BI_BITFIELDS
  bd.setUint32(0x22, contentSize , Endian.little);
  bd.setUint32(0x36, 0x000000ff, Endian.little);
  bd.setUint32(0x3a, 0x0000ff00, Endian.little);
  bd.setUint32(0x3e, 0x00ff0000, Endian.little);
  bd.setUint32(0x42, 0xff000000, Endian.little);

  headerIntList.setRange(
    headerSize,
    fileLength,
    content,
  );

  return headerIntList;
}