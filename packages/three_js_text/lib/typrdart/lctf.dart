import 'dart:typed_data';
import './bin.dart';

// OpenType Layout Common Table Formats

class Typr_LCTF {
  static Map<String, dynamic> parse(Uint8List data, int offset, int length, font, subt) {
    final Map<String, dynamic> obj = {};
    final offset0 = offset;
    offset += 4;

    final offScriptList = TyprBin.readUshort(data, offset);
    offset += 2;
    final offFeatureList = TyprBin.readUshort(data, offset);
    offset += 2;
    final offLookupList = TyprBin.readUshort(data, offset);
    offset += 2;

    obj["scriptList"] = readScriptList(data, offset0 + offScriptList);
    obj["featureList"] = readFeatureList(data, offset0 + offFeatureList);
    obj["lookupList"] = readLookupList(data, offset0 + offLookupList, subt);

    return obj;
  }

  static List<Map<String,dynamic>> readLookupList(Uint8List data, int offset, subt) {
    int offset0 = offset;
    List<Map<String,dynamic>> obj = [];
    int count = TyprBin.readUshort(data, offset);
    offset += 2;
    for (int i = 0; i < count; i++) {
      int noff = TyprBin.readUshort(data, offset);
      offset += 2;
      final lut = readLookupTable(data, offset0 + noff, subt);
      obj.add(lut);
    }
    return obj;
  }

  static Map<String, dynamic> readLookupTable(Uint8List data, int offset, subt) {
    //console.warn("Parsing lookup table", offset);

    int offset0 = offset;
    Map<String, dynamic> obj = {"tabs": []};

    obj["ltype"] = TyprBin.readUshort(data, offset);
    offset += 2;
    obj["flag"] = TyprBin.readUshort(data, offset);
    offset += 2;
    final cnt = TyprBin.readUshort(data, offset);
    offset += 2;

    final ltype = obj["ltype"]; // extension substitution can change this value
    for (int i = 0; i < cnt; i++) {
      final noff = TyprBin.readUshort(data, offset);
      offset += 2;
      final tab = subt(data, ltype, offset0 + noff, obj);
      //console.warn(obj.type, tab);
      obj["tabs"].add(tab);
    }
    return obj;
  }

  static int numOfOnes(int n) {
    int num = 0;
    for (int i = 0; i < 32; i++){ 
      if (((n >> i) & 1) != 0) num++;
    }
    return num;
  }

  static List<int> readClassDef(Uint8List data, int offset) {
    List<int> obj = [];
    final format = TyprBin.readUshort(data, offset);
    offset += 2;
    if (format == 1) {
      final startGlyph = TyprBin.readUshort(data, offset);
      offset += 2;
      final glyphCount = TyprBin.readUshort(data, offset);
      offset += 2;
      for (int i = 0; i < glyphCount; i++) {
        obj.add(startGlyph + i);
        obj.add(startGlyph + i);
        obj.add(TyprBin.readUshort(data, offset));
        offset += 2;
      }
    }
    if (format == 2) {
      final count = TyprBin.readUshort(data, offset);
      offset += 2;
      for (int i = 0; i < count; i++) {
        obj.add(TyprBin.readUshort(data, offset));
        offset += 2;
        obj.add(TyprBin.readUshort(data, offset));
        offset += 2;
        obj.add(TyprBin.readUshort(data, offset));
        offset += 2;
      }
    }
    return obj;
  }

  static int getInterval(tab, val) {
    for (int i = 0; i < tab.length; i += 3) {
      final start = tab[i];
      final end = tab[i + 1];
      if (start <= val && val <= end) return i;
    }
    return -1;
  }

  static Map<String, dynamic> readCoverage(Uint8List data, int offset) {
    Map<String, dynamic> cvg = {};
    cvg["fmt"] = TyprBin.readUshort(data, offset);
    offset += 2;
    final count = TyprBin.readUshort(data, offset);
    offset += 2;
    //console.warn("parsing coverage", offset-4, format, count);
    if (cvg["fmt"] == 1) cvg["tab"] = TyprBin.readUshorts(data, offset, count);
    if (cvg["fmt"] == 2)
      cvg["tab"] = TyprBin.readUshorts(data, offset, count * 3);
    return cvg;
  }

  static coverageIndex(Map<String, dynamic> cvg, val) {
    final tab = cvg["tab"];
    if (cvg["fmt"] == 1) return tab.indexOf(val);
    if (cvg["fmt"] == 2) {
      final ind = getInterval(tab, val);
      if (ind != -1) return tab[ind + 2] + (val - tab[ind]);
    }
    return -1;
  }

  static List<Map<String,dynamic>> readFeatureList(Uint8List data, int offset) {
    final offset0 = offset;
    List<Map<String,dynamic>> obj = [];

    final count = TyprBin.readUshort(data, offset);
    offset += 2;

    for (int i = 0; i < count; i++) {
      final tag = TyprBin.readASCII(data, offset, 4);
      offset += 4;
      final noff = TyprBin.readUshort(data, offset);
      offset += 2;
      final feat = readFeatureTable(data, offset0 + noff);
      feat["tag"] = tag.trim();
      obj.add(feat);
    }
    return obj;
  }

  static Map<String, dynamic> readFeatureTable(Uint8List data, int offset) {
    final offset0 = offset;
    Map<String, dynamic> feat = {};

    final featureParams = TyprBin.readUshort(data, offset);
    offset += 2;
    if (featureParams > 0) {
      feat["featureParams"] = offset0 + featureParams;
    }

    final lookupCount = TyprBin.readUshort(data, offset);
    offset += 2;
    feat["tab"] = [];
    for (int i = 0; i < lookupCount; i++)
      feat["tab"].add(TyprBin.readUshort(data, offset + 2 * i));
    return feat;
  }

  static Map<String,dynamic> readScriptList(Uint8List data, int offset) {
    final offset0 = offset;
    Map<String,dynamic> obj = {};

    final count = TyprBin.readUshort(data, offset);
    offset += 2;

    for (int i = 0; i < count; i++) {
      final tag = TyprBin.readASCII(data, offset, 4);
      offset += 4;
      final noff = TyprBin.readUshort(data, offset);
      offset += 2;
      obj[tag.trim()] = readScriptTable(data, offset0 + noff);
    }
    return obj;
  }

  static Map<String, dynamic> readScriptTable(Uint8List data, int offset) {
    int offset0 = offset;
    Map<String, dynamic> obj = {};

    int defLangSysOff = TyprBin.readUshort(data, offset);
    offset += 2;
    obj["default"] = readLangSysTable(data, offset0 + defLangSysOff);

    int langSysCount = TyprBin.readUshort(data, offset);
    offset += 2;

    for (int i = 0; i < langSysCount; i++) {
      String tag = TyprBin.readASCII(data, offset, 4);
      offset += 4;
      int langSysOff = TyprBin.readUshort(data, offset);
      offset += 2;
      obj[tag.trim()] = readLangSysTable(data, offset0 + langSysOff);
    }
    return obj;
  }

  static Map<String, dynamic> readLangSysTable(Uint8List data, int offset) {
    Map<String, dynamic> obj = {};

    offset += 2;
    obj["reqFeature"] = TyprBin.readUshort(data, offset);
    offset += 2;

    int featureCount = TyprBin.readUshort(data, offset);
    offset += 2;
    obj["features"] = TyprBin.readUshorts(data, offset, featureCount);
    return obj;
  }
}

class GSUBTable extends Typr_LCTF {}

class GPOSTable extends Typr_LCTF {}
