import 'dart:typed_data';
import 'package:three_js_core/three_js_core.dart';

import '../bin.dart';

class Typr_CMAP {
  static Map<String, dynamic> parse(Uint8List buffer, int offset, int length) {
    Uint8List data = buffer.sublist(offset, offset + length);
    offset = 0;

    Map<String, dynamic> obj = {};
    offset += 2;
    int numTables = TyprBin.readUshort(data, offset);
    offset += 2;

    //console.warn(version, numTables);

    final List<int> offs = [];
    obj["tables"] = [];

    for (int i = 0; i < numTables; i++) {
      int platformID = TyprBin.readUshort(data, offset);
      offset += 2;
      int encodingID = TyprBin.readUshort(data, offset);
      offset += 2;
      int noffset = TyprBin.readUint(data, offset);
      offset += 4;

      String id = "p${platformID}e${encodingID}";

      //console.warn("cmap subtable", platformID, encodingID, noffset);

      int tind = offs.indexOf(noffset);

      if (tind == -1) {
        tind = obj["tables"].length;
        Map<String, dynamic>? subt;
        offs.add(noffset);
        int format = TyprBin.readUshort(data, noffset);
        if (format == 0)
          subt = parse0(data, noffset);
        else if (format == 4)
          subt = parse4(data, noffset);
        else if (format == 6)
          subt = parse6(data, noffset);
        else if (format == 12)
          subt = parse12(data, noffset);
        else
          console.warning("unknown format: ${format} platformID: ${platformID} encodingID: ${encodingID} noffset: ${noffset}");
        obj["tables"].add(subt);
      }

      if (obj[id] != null) throw "multiple tables for one platform+encoding";
      obj[id] = tind;
    }
    return obj;
  }

  static Map<String, dynamic> parse0(Uint8List data, int offset) {
    Map<String, dynamic> obj = {};
    obj["format"] = TyprBin.readUshort(data, offset);
    offset += 2;
    int len = TyprBin.readUshort(data, offset);
    offset += 2;
    offset += 2;
    obj["map"] = [];
    for (int i = 0; i < len - 6; i++) obj["map"].add(data[offset + i]);
    return obj;
  }

  static Map<String, dynamic> parse4(Uint8List data, int offset) {
    int offset0 = offset;
    Map<String, dynamic> obj = {};

    obj["format"] = TyprBin.readUshort(data, offset);
    offset += 2;
    int length = TyprBin.readUshort(data, offset);
    offset += 2;
    offset += 2;
    int segCountX2 = TyprBin.readUshort(data, offset);
    offset += 2;
    int segCount = (segCountX2 / 2).toInt();
    obj["searchRange"] = TyprBin.readUshort(data, offset);
    offset += 2;
    obj["entrySelector"] = TyprBin.readUshort(data, offset);
    offset += 2;
    obj["rangeShift"] = TyprBin.readUshort(data, offset);
    offset += 2;
    obj["endCount"] = TyprBin.readUshorts(data, offset, segCount);
    offset += segCount * 2;
    offset += 2;
    obj["startCount"] = TyprBin.readUshorts(data, offset, segCount);
    offset += segCount * 2;
    obj["idDelta"] = [];
    for (int i = 0; i < segCount; i++) {
      obj["idDelta"].add(TyprBin.readShort(data, offset));
      offset += 2;
    }
    obj["idRangeOffset"] = TyprBin.readUshorts(data, offset, segCount);
    offset += segCount * 2;
    obj["glyphIdArray"] = [];
    while (offset < offset0 + length) {
      obj["glyphIdArray"].add(TyprBin.readUshort(data, offset));
      offset += 2;
    }
    return obj;
  }

  static Map<String, dynamic> parse6(Uint8List data, int offset) {
    Map<String, dynamic> obj = {};

    obj["format"] = TyprBin.readUshort(data, offset);
    offset += 2;
    offset += 2;
    offset += 2;
    obj["firstCode"] = TyprBin.readUshort(data, offset);
    offset += 2;
    int entryCount = TyprBin.readUshort(data, offset);
    offset += 2;
    obj["glyphIdArray"] = [];
    for (int i = 0; i < entryCount; i++) {
      obj["glyphIdArray"].add(TyprBin.readUshort(data, offset));
      offset += 2;
    }

    return obj;
  }

  static Map<String, dynamic> parse12(Uint8List data, int offset) {
    Map<String, dynamic> obj = {};

    obj["format"] = TyprBin.readUshort(data, offset);
    offset += 2;
    offset += 2;
    offset += 4;
    offset += 4;
    int nGroups = TyprBin.readUint(data, offset);
    offset += 4;
    obj["groups"] = [];

    for (int i = 0; i < nGroups; i++) {
      int off = offset + i * 12;
      int startCharCode = TyprBin.readUint(data, off + 0);
      int endCharCode = TyprBin.readUint(data, off + 4);
      int startGlyphID = TyprBin.readUint(data, off + 8);
      obj["groups"].add([startCharCode, endCharCode, startGlyphID]);
    }
    return obj;
  }
}
