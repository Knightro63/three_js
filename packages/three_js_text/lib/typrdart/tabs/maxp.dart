import 'dart:typed_data';
import '../bin.dart';

class Typr_MAXP {
  static Map<String, dynamic> parse(Uint8List data, int offset, int length) {
    //console.warn(data.length, offset, length);
    Map<String, dynamic> obj = {};

    // both versions 0.5 and 1.0
    int ver = TyprBin.readUint(data, offset);
    offset += 4;
    obj["numGlyphs"] = TyprBin.readUshort(data, offset);
    offset += 2;

    // only 1.0
    if (ver == 0x00010000) {
      obj["maxPoints"] = TyprBin.readUshort(data, offset);
      offset += 2;
      obj["maxContours"] = TyprBin.readUshort(data, offset);
      offset += 2;
      obj["maxCompositePoints"] = TyprBin.readUshort(data, offset);
      offset += 2;
      obj["maxCompositeContours"] = TyprBin.readUshort(data, offset);
      offset += 2;
      obj["maxZones"] = TyprBin.readUshort(data, offset);
      offset += 2;
      obj["maxTwilightPoints"] = TyprBin.readUshort(data, offset);
      offset += 2;
      obj["maxStorage"] = TyprBin.readUshort(data, offset);
      offset += 2;
      obj["maxFunctionDefs"] = TyprBin.readUshort(data, offset);
      offset += 2;
      obj["maxInstructionDefs"] = TyprBin.readUshort(data, offset);
      offset += 2;
      obj["maxStackElements"] = TyprBin.readUshort(data, offset);
      offset += 2;
      obj["maxSizeOfInstructions"] = TyprBin.readUshort(data, offset);
      offset += 2;
      obj["maxComponentElements"] = TyprBin.readUshort(data, offset);
      offset += 2;
      obj["maxComponentDepth"] = TyprBin.readUshort(data, offset);
      offset += 2;
    }

    return obj;
  }
}
