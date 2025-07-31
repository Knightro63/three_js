import 'dart:typed_data';
import '../bin.dart';

class Typr_HEAD {
  static Map<String, dynamic> parse(Uint8List data, int offset, int length) {
    Map<String, dynamic> obj = {};
    offset += 4;
    obj["fontRevision"] = TyprBin.readFixed(data, offset);
    offset += 4;
    offset += 4;
    offset += 4;
    obj["flags"] = TyprBin.readUshort(data, offset);
    offset += 2;
    obj["unitsPerEm"] = TyprBin.readUshort(data, offset);
    offset += 2;
    obj["created"] = TyprBin.readUint64(data, offset);
    offset += 8;
    obj["modified"] = TyprBin.readUint64(data, offset);
    offset += 8;
    obj["xMin"] = TyprBin.readShort(data, offset);
    offset += 2;
    obj["yMin"] = TyprBin.readShort(data, offset);
    offset += 2;
    obj["xMax"] = TyprBin.readShort(data, offset);
    offset += 2;
    obj["yMax"] = TyprBin.readShort(data, offset);
    offset += 2;
    obj["macStyle"] = TyprBin.readUshort(data, offset);
    offset += 2;
    obj["lowestRecPPEM"] = TyprBin.readUshort(data, offset);
    offset += 2;
    obj["fontDirectionHint"] = TyprBin.readShort(data, offset);
    offset += 2;
    obj["indexToLocFormat"] = TyprBin.readShort(data, offset);
    offset += 2;
    obj["glyphDataFormat"] = TyprBin.readShort(data, offset);
    offset += 2;
    return obj;
  }
}
