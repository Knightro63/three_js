import 'dart:typed_data';

class TyprBin {
  static num readFixed(List<int> data, int o) {
    return ((data[o] << 8) | data[o + 1]) +
        (((data[o + 2] << 8) | data[o + 3]) / (256 * 256 + 4));
  }

  static num readF2dot14(List<int> data, int o) {
    int num = readShort(data, o);
    return num / 16384;
  }

  static int readInt(List<int> buff, int p) {
    Uint8List a = BinT.uint8;
    a[0] = buff[p + 3];
    a[1] = buff[p + 2];
    a[2] = buff[p + 1];
    a[3] = buff[p];
    return BinT.int32[0];
  }

  static int readInt8(List<int> buff, int p) {
    Uint8List a = BinT.uint8;
    a[0] = buff[p];
    return BinT.int8[0];
  }

  static int readShort(List<int> buff, int p) {
    Uint8List a = BinT.uint8;
    a[1] = buff[p];
    a[0] = buff[p + 1];
    return BinT.int16[0];
  }

  static int readUshort(List<int> buff, int p) {
    return (buff[p] << 8) | buff[p + 1];
  }

  static List<int> readUshorts(List<int> buff, int p, int len) {
    final List<int> arr = [];
    for (int i = 0; i < len; i++){
      arr.add(readUshort(buff, p + i * 2));
    }
    return arr;
  }

  static int readUint(List<int> buff, int p) {
    Uint8List a = BinT.uint8;
    a[3] = buff[p];
    a[2] = buff[p + 1];
    a[1] = buff[p + 2];
    a[0] = buff[p + 3];
    return BinT.uint32[0];
  }

  static readUint64(buff, p) {
    return (readUint(buff, p) * (0xffffffff + 1)) + readUint(buff, p + 4);
  }

  static String readASCII(List<int> buff, int p, l){
    String s = "";
    for (int i = 0; i < l; i++){ 
      s += String.fromCharCode(buff[p + i]);
    }
    return s;
  }

  static String readUnicode(List<int> buff, int p, int l) {
    String s = "";
    for (int i = 0; i < l; i++) {
      int c = (buff[p++] << 8) | buff[p++];
      s += String.fromCharCode(c);
    }
    return s;
  }

  static String readUTF8(List<int> buff, int p, int l) {
    return readASCII(buff, p, l);
  }

  static List<int> readBytes(List<int> buff, int p, int l) {
    final List<int> arr = [];
    for (int i = 0; i < l; i++) arr.add(buff[p + i]);
    return arr;
  }

  static List<String> readASCIIArray(List<int> buff, int p, int l){
    final List<String> s = [];
    for (int i = 0; i < l; i++) s.add(String.fromCharCode(buff[p + i]));
    return s;
  }
}

class BinT {
  static ByteData buff = ByteData(8);

  static Int8List int8 = Int8List.view(buff.buffer);
  static Uint8List uint8 = Uint8List.view(buff.buffer);
  static Int16List int16 = Int16List.view(buff.buffer);
  static Uint16List uint16 = Uint16List.view(buff.buffer);
  static Int32List int32 = Int32List.view(buff.buffer);
  static Uint32List uint32 = Uint32List.view(buff.buffer);
}
