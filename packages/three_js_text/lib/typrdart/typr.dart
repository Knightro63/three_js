import 'dart:typed_data';
import './bin.dart';
import './tabs/index.dart';

class Typr {
  static List<Map<String,dynamic>> parse(Uint8List buff) {
    final Uint8List data = buff;

    String tag = TyprBin.readASCII(data, 0, 4);
    if (tag == "ttcf") {
      int offset = 4;
      offset += 2;
      offset += 2;
      int numF = TyprBin.readUint(data, offset);
      offset += 4;
      final List<Map<String,dynamic>> fnts = [];
      for (int i = 0; i < numF; i++) {
        int foff = TyprBin.readUint(data, offset);
        offset += 4;
        fnts.add(Typr._readFont(data, foff));
      }
      return fnts;
    } 
    else {
      return [Typr._readFont(data, 0)];
    }
  }

  static Map<String, dynamic> _readFont(Uint8List data, int offset) {
    int ooff = offset;

    offset += 4;
    int numTables = TyprBin.readUshort(data, offset);
    offset += 2;
    offset += 2;
    offset += 2;
    offset += 2;

    final List<String> tags = [
      "cmap",
      "head",
      "hhea",
      "maxp",
      "hmtx",
      "name",
      "OS/2",
      "post",
      "loca",
      "glyf",
      "kern",
      "CFF ",
      "GPOS",
      "GSUB",
      "SVG "
    ];

    final Map<String,dynamic> obj = {"_data": data, "_offset": ooff};
    Map<String,dynamic> tabs = {};

    for (int i = 0; i < numTables; i++) {
      String tag = TyprBin.readASCII(data, offset, 4);
      offset += 4;
      offset += 4;
      int toffset = TyprBin.readUint(data, offset);
      offset += 4;
      int length = TyprBin.readUint(data, offset);
      offset += 4;
      tabs[tag] = {"offset": toffset, "length": length};
    }

    for (int i = 0; i < tags.length; i++) {
      String t = tags[i];
      if (tabs[t] != null) {
        String _t = t.trim();
        obj[_t] = whichParse(_t, data, tabs[t]["offset"], tabs[t]["length"], obj);
      }
    }

    return obj;
  }

  static whichParse(String tag, Uint8List data, int offset, int length, obj) {
    if (tag == "cmap") {
      return Typr_CMAP.parse(data, offset, length);
    } else if (tag == "head") {
      return Typr_HEAD.parse(data, offset, length);
    } else if (tag == "hhea") {
      return Typr_HHEA.parse(data, offset, length);
    } else if (tag == "maxp") {
      return Typr_MAXP.parse(data, offset, length);
    } else if (tag == "hmtx") {
      return Typr_HMTX.parse(data, offset, length, obj);
    } else if (tag == "name") {
      return Typr_NAME.parse(data, offset, length);
    } else if (tag == "OS/2") {
      return Typr_OS2.parse(data, offset, length);
    } else if (tag == "post") {
      return Typr_POST.parse(data, offset, length);
    } else if (tag == "loca") {
      return Typr_LOCA.parse(data, offset, length, obj);
    } else if (tag == "glyf") {
      return Typr_GLYF.parse(data, offset, length, obj);
    } else if (tag == "kern") {
      return Typr_KERN.parse(data, offset, length, obj);
    } else if (tag == "CFF") {
      return Typr_CFF.parse(data, offset, length);
    } else if (tag == "GPOS") {
      return Typr_GPOS.parse(data, offset, length, obj);
    } else if (tag == "GSUB") {
      return Typr_GSUB.parse(data, offset, length, obj);
    } else if (tag == "SVG") {
      return Typr_SVG.parse(data, offset, length);
    } else {
      throw ("whichParse tag is not support ${tag} ");
    }
  }

  static int tabOffset(Uint8List data, tab, int foff) {
    final numTables = TyprBin.readUshort(data, foff + 4);
    int offset = foff + 12;
    for (int i = 0; i < numTables; i++) {
      final tag = TyprBin.readASCII(data, offset, 4);
      offset += 4;
      offset += 4;
      final toffset = TyprBin.readUint(data, offset);
      offset += 4;
      offset += 4;
      if (tag == tab) return toffset;
    }
    return 0;
  }
}
