import 'dart:typed_data';
import '../bin.dart';

class Typr_POST {
  static Map<String, dynamic> parse(Uint8List data, int offset, int length) {
    Map<String, dynamic> obj = {};

    obj["version"] = TyprBin.readFixed(data, offset);
    offset += 4;
    obj["italicAngle"] = TyprBin.readFixed(data, offset);
    offset += 4;
    obj["underlinePosition"] = TyprBin.readShort(data, offset);
    offset += 2;
    obj["underlineThickness"] = TyprBin.readShort(data, offset);
    offset += 2;

    return obj;
  }
}
