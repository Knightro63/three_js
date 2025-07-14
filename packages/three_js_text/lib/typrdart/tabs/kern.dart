import 'dart:typed_data';
import '../bin.dart';

class Typr_KERN {
  static Map<String,dynamic> parse(Uint8List data, int offset, int length, font) {
    int version = TyprBin.readUshort(data, offset);
    offset += 2;
    if (version == 1) return parseV1(data, offset - 2, length, font);
    int nTables = TyprBin.readUshort(data, offset);
    offset += 2;

    Map<String,dynamic> map = {"glyph1": [], "rval": []};
    for (int i = 0; i < nTables; i++) {
      offset += 2; // skip version
      offset += 2;
      int coverage = TyprBin.readUshort(data, offset);
      offset += 2;
      int format = coverage >> 8;
      /* I have seen format 128 once, that's why I do */ format &= 0xf;
      if (format == 0)
        offset = readFormat0(data, offset, map);
      else
        throw "unknown kern table format: ${format}";
    }
    return map;
  }

  static Map<String,dynamic> parseV1(Uint8List data, int offset, int length, font) {
    offset += 4;
    int nTables = TyprBin.readUint(data, offset);
    offset += 4;

     Map<String,dynamic> map = {"glyph1": [], "rval": []};
    for (int i = 0; i < nTables; i++) {
      offset += 4;
      int coverage = TyprBin.readUshort(data, offset);
      offset += 2;
      offset += 2;
      int format = coverage >> 8;
      /* I have seen format 128 once, that's why I do */ format &= 0xf;
      if (format == 0)
        offset = readFormat0(data, offset, map);
      else
        throw "unknown kern table format: $format";
    }
    return map;
  }

  static int readFormat0(Uint8List data, int offset, Map<String,dynamic> map) {
    int pleft = -1;
    int nPairs = TyprBin.readUshort(data, offset);
    offset += 2;
    offset += 2;
    offset += 2;
    offset += 2;
    for (int j = 0; j < nPairs; j++) {
      int left = TyprBin.readUshort(data, offset);
      offset += 2;
      int right = TyprBin.readUshort(data, offset);
      offset += 2;
      int value = TyprBin.readShort(data, offset);
      offset += 2;
      if (left != pleft) {
        map['glyph1'].add(left);
        map['rval'].add({"glyph2": [], "vals": []});
      }
      var rval = map['rval'][map['rval'].length - 1];
      rval.glyph2.add(right);
      rval.vals.add(value);
      pleft = left;
    }
    return offset;
  }
}
