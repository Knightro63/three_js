import 'dart:typed_data';

import 'package:three_js_core/three_js_core.dart';

import '../bin.dart';
import '../lctf.dart';

class Typr_GSUB {
  static parse(Uint8List data, int offset, length, font) {
    return Typr_LCTF.parse(data, offset, length, font, subt);
  }

  static Map<String, dynamic>? subt(Uint8List data, ltype, int offset, ltable){
    int offset0 = offset;
    Map<String,dynamic> tab = {};

    tab["fmt"] = TyprBin.readUshort(data, offset);
    offset += 2;

    if (ltype != 1 && ltype != 4 && ltype != 5 && ltype != 6) return null;

    if (ltype == 1 ||
        ltype == 4 ||
        (ltype == 5 && tab["fmt"] <= 2) ||
        (ltype == 6 && tab["fmt"] <= 2)) {
      int covOff = TyprBin.readUshort(data, offset);
      offset += 2;
      tab["coverage"] = Typr_LCTF.readCoverage(
          data, offset0 + covOff); // not always is coverage here
    }

    if (ltype == 1 && tab["fmt"] >= 1 && tab["fmt"] <= 2) {
      if (tab["fmt"] == 1) {
        tab["delta"] = TyprBin.readShort(data, offset);
        offset += 2;
      } 
      else if (tab["fmt"] == 2) {
        int cnt = TyprBin.readUshort(data, offset);
        offset += 2;
        tab["newg"] = TyprBin.readUshorts(data, offset, cnt);
        offset += (tab["newg"].length as int) * 2;
      }
    }
    //  Ligature Substitution Subtable
    else if (ltype == 4) {
      tab["vals"] = [];
      int cnt = TyprBin.readUshort(data, offset);
      offset += 2;
      for (int i = 0; i < cnt; i++) {
        int loff = TyprBin.readUshort(data, offset);
        offset += 2;
        tab["vals"].add(readLigatureSet(data, offset0 + loff));
      }
      //console.warn(tab.coverage);
      //console.warn(tab.vals);
    }
    //  Contextual Substitution Subtable
    else if (ltype == 5 && tab["fmt"] == 2) {
      if (tab["fmt"] == 2) {
        int cDefOffset = TyprBin.readUshort(data, offset);
        offset += 2;
        tab["cDef"] = Typr_LCTF.readClassDef(data, offset0 + cDefOffset);
        tab["scset"] = [];
        int subClassSetCount = TyprBin.readUshort(data, offset);
        offset += 2;
        for (int i = 0; i < subClassSetCount; i++) {
          int scsOff = TyprBin.readUshort(data, offset);
          offset += 2;
          tab["scset"].add(
              scsOff == 0 ? null : readSubClassSet(data, offset0 + scsOff));
        }
      }
      //else console.warn("unknown table format", tab.fmt);
    }
    //*
    else if (ltype == 6 && tab["fmt"] == 3) {
      if (tab["fmt"] == 3) {
        for (int i = 0; i < 3; i++) {
          int cnt = TyprBin.readUshort(data, offset);
          offset += 2;
          List<Map<String, dynamic>> cvgs = [];
          for (int j = 0; j < cnt; j++){
            cvgs.add(Typr_LCTF.readCoverage(
                data, offset0 + TyprBin.readUshort(data, offset + j * 2)));
          }
          offset += cnt * 2;
          if (i == 0) tab["backCvg"] = cvgs;
          if (i == 1) tab["inptCvg"] = cvgs;
          if (i == 2) tab["ahedCvg"] = cvgs;
        }
        int cnt = TyprBin.readUshort(data, offset);
        offset += 2;
        tab["lookupRec"] = readSubstLookupRecords(data, offset, cnt);
      }
      //console.warn(tab);
    } //*/
    else if (ltype == 7 && tab["fmt"] == 1) {
      int extType = TyprBin.readUshort(data, offset);
      offset += 2;
      int extOffset = TyprBin.readUint(data, offset);
      offset += 4;
      if (ltable.ltype == 9) {
        ltable.ltype = extType;
      } else if (ltable.ltype != extType) {
        throw "invalid extension substitution"; // all subtables must be the same type
      }
      return subt(data, ltable.ltype, offset0 + extOffset, null);
    } else {
      console.warning("unsupported GSUB table LookupType: ${ltype} format ${tab["fmt"]} ");
    }

    return tab;
  }

  static List<Map<String, dynamic>> readSubClassSet(Uint8List data, int offset) {
    int Function(Uint8List,int) rUs = TyprBin.readUshort;
    int offset0 = offset;
    List<Map<String, dynamic>> lset = [];
    int cnt = rUs(data, offset);
    offset += 2;
    for (int i = 0; i < cnt; i++) {
      int loff = rUs(data, offset);
      offset += 2;
      lset.add(readSubClassRule(data, offset0 + loff));
    }
    return lset;
  }

  static Map<String, dynamic> readSubClassRule(Uint8List data, int offset) {
    int Function(Uint8List,int) rUs = TyprBin.readUshort;
    Map<String, dynamic> rule = {};
    int gcount = rUs(data, offset);
    offset += 2;
    int scount = rUs(data, offset);
    offset += 2;
    rule["input"] = [];
    for (int i = 0; i < gcount - 1; i++) {
      rule["input"].add(rUs(data, offset));
      offset += 2;
    }
    rule["substLookupRecords"] = readSubstLookupRecords(data, offset, scount);
    return rule;
  }

  static List<int> readSubstLookupRecords(Uint8List data, int offset, cnt) {
    int Function(Uint8List,int) rUs = TyprBin.readUshort;
    List<int> out = [];
    for (int i = 0; i < cnt; i++) {
      out.addAll([rUs(data, offset), rUs(data, offset + 2)]);
      offset += 4;
    }
    return out;
  }

  static List<Map<String, dynamic>> readChainSubClassSet(Uint8List data, int offset) {
    int offset0 = offset;
    List<Map<String, dynamic>> lset = [];
    int cnt = TyprBin.readUshort(data, offset);
    offset += 2;
    for (int i = 0; i < cnt; i++) {
      int loff = TyprBin.readUshort(data, offset);
      offset += 2;
      lset.add(readChainSubClassRule(data, offset0 + loff));
    }
    return lset;
  }

  static Map<String,dynamic> readChainSubClassRule(Uint8List data, int offset) {
    Map<String,dynamic> rule = {};
    List<String> pps = ["backtrack", "input", "lookahead"];
    for (int pi = 0; pi < pps.length; pi++) {
      int cnt = TyprBin.readUshort(data, offset);
      offset += 2;
      if (pi == 1) cnt--;
      rule[pps[pi]] = TyprBin.readUshorts(data, offset, cnt);
      offset += (rule[pps[pi]].length as int) * 2;
    }
    int cnt = TyprBin.readUshort(data, offset);
    offset += 2;
    rule["subst"] = TyprBin.readUshorts(data, offset, cnt * 2);
    offset += (rule["subst"].length as int) * 2;
    return rule;
  }

  static List<Map<String, dynamic>> readLigatureSet(Uint8List data, int offset) {
    int offset0 = offset;
    List<Map<String, dynamic>> lset = [];
    int lcnt = TyprBin.readUshort(data, offset);
    offset += 2;
    for (int j = 0; j < lcnt; j++) {
      int loff = TyprBin.readUshort(data, offset);
      offset += 2;
      lset.add(readLigature(data, offset0 + loff));
    }
    return lset;
  }

  static Map<String,dynamic> readLigature(Uint8List data, int offset) {
    Map<String, dynamic> lig = {"chain": []};
    lig["nglyph"] = TyprBin.readUshort(data, offset);
    offset += 2;
    int ccnt = TyprBin.readUshort(data, offset);
    offset += 2;
    for (int k = 0; k < ccnt - 1; k++) {
      lig["chain"].add(TyprBin.readUshort(data, offset));
      offset += 2;
    }
    return lig;
  }
}
