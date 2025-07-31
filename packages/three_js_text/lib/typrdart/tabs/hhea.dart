import 'dart:typed_data';

import '../bin.dart';

class Typr_HHEA {
  static Map<String, dynamic> parse(Uint8List data, int offset, int length) {
    Map<String, dynamic> obj = {};
    offset += 4;
    obj["ascender"] = TyprBin.readShort(data, offset);
    offset += 2;
    obj["descender"] = TyprBin.readShort(data, offset);
    offset += 2;
    obj["lineGap"] = TyprBin.readShort(data, offset);
    offset += 2;

    obj["advanceWidthMax"] = TyprBin.readUshort(data, offset);
    offset += 2;
    obj["minLeftSideBearing"] = TyprBin.readShort(data, offset);
    offset += 2;
    obj["minRightSideBearing"] = TyprBin.readShort(data, offset);
    offset += 2;
    obj["xMaxExtent"] = TyprBin.readShort(data, offset);
    offset += 2;

    obj["caretSlopeRise"] = TyprBin.readShort(data, offset);
    offset += 2;
    obj["caretSlopeRun"] = TyprBin.readShort(data, offset);
    offset += 2;
    obj["caretOffset"] = TyprBin.readShort(data, offset);
    offset += 2;

    offset += 4 * 2;

    obj["metricDataFormat"] = TyprBin.readShort(data, offset);
    offset += 2;
    obj["numberOfHMetrics"] = TyprBin.readUshort(data, offset);
    offset += 2;
    return obj;
  }
}
