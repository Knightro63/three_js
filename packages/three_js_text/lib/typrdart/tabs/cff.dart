import 'dart:typed_data';
import '../bin.dart';

class Typr_CFF {
  static Map<String,dynamic> parse(Uint8List buffer, int offset, int length) {
    final data = buffer.sublist(offset, offset + length);

    offset = 0;

    // Header
    offset++;
    offset++;
    offset++;
    offset++;

    // Name INDEX
    List<int> ninds = [];
    offset = readIndex(data, offset, ninds);
    var names = [];

    for (int i = 0; i < ninds.length - 1; i++){
      names.add(TyprBin.readASCII(data, offset + ninds[i], ninds[i + 1] - ninds[i]));
    }
    offset += ninds[ninds.length - 1];

    // Top DICT INDEX
    List<int> tdinds = [];
    offset = readIndex(data, offset, tdinds); //console.warn(tdinds);
    // Top DICT Data
    var topDicts = [];
    for (int i = 0; i < tdinds.length - 1; i++)
      topDicts.add(readDict(data, offset + tdinds[i], offset + tdinds[i + 1]));
    offset += tdinds[tdinds.length - 1];
    Map<String, dynamic> topdict = Map<String, dynamic>.from(topDicts[0]);
    //console.warn(topdict);

    // String INDEX
    List<int> sinds = [];
    offset = readIndex(data, offset, sinds);
    // String Data
    List<String> strings = [];
    for (int i = 0; i < sinds.length - 1; i++){
      strings.add(TyprBin.readASCII(data, offset + sinds[i], sinds[i + 1] - sinds[i]));
    }
    offset += sinds[sinds.length - 1];

    // Global Subr INDEX  (subroutines)
    readSubrs(data, offset, topdict);

    // charstrings
    if (topdict["CharStrings"] != null) {
      offset = topdict["CharStrings"];
      List<int> sinds = [];
      offset = readIndex(data, offset, sinds);

      List<List<int>> cstr = [];
      for (int i = 0; i < sinds.length - 1; i++){
        cstr.add(TyprBin.readBytes(
            data, offset + sinds[i], sinds[i + 1] - sinds[i]));
      }
      //offset += sinds[sinds.length-1];
      topdict["CharStrings"] = cstr;
      //console.warn(topdict.CharStrings);
    }

    // CID font
    if (topdict["ROS"] != null) {
      offset = topdict["FDArray"];
      List<int> fdind = [];
      offset = readIndex(data, offset, fdind);

      topdict["FDArray"] = [];
      for (int i = 0; i < fdind.length - 1; i++) {
        var dict = readDict(data, offset + fdind[i], offset + fdind[i + 1]);
        _readFDict(data, dict, strings);
        topdict["FDArray"].add(dict);
      }
      offset += fdind[fdind.length - 1];

      offset = topdict["FDSelect"];
      topdict["FDSelect"] = [];
      var fmt = data[offset];
      offset++;
      if (fmt == 3) {
        var rns = TyprBin.readUshort(data, offset);
        offset += 2;
        for (var i = 0; i < rns + 1; i++) {
          topdict["FDSelect"]
              .addAll([TyprBin.readUshort(data, offset), data[offset + 2]]);
          offset += 3;
        }
      } else
        throw fmt;
    }

    // Encoding
    if (topdict["Encoding"] != null) {
      topdict["Encoding"] = readEncoding(
          data, topdict["Encoding"], topdict["CharStrings"].length);
    }

    // charset
    if (topdict["charset"] != null) {
      topdict["charset"] =
          readCharset(data, topdict["charset"], topdict["CharStrings"].length);
    }

    _readFDict(data, topdict, strings);
    return topdict;
  }

  static void _readFDict(Uint8List data, Map<String,dynamic> dict, ss) {
    var offset;
    if (dict["Private"] != null) {
      offset = dict["Private"][1];
      dict["Private"] = readDict(data, offset, offset + dict["Private"][0]);
      if (dict["Private"]["Subrs"] != null) {
        readSubrs(data, offset + dict["Private"]["Subrs"], dict["Private"]);
      }
    }
    final l = [
      "FamilyName",
      "FontName",
      "FullName",
      "Notice",
      "version",
      "Copyright"
    ];
    for (final p in dict.keys) {
      if(l.indexOf(p) != -1) {
        dict[p] = ss[dict[p] - 426 + 35];
      }
    }
  }

  static void readSubrs(Uint8List data, int offset, Map obj) {
    List<int> gsubinds = [];
    offset = readIndex(data, offset, gsubinds);

    int bias, nSubrs = gsubinds.length;
    if (nSubrs < 1240)
      bias = 107;
    else if (nSubrs < 33900)
      bias = 1131;
    else
      bias = 32768;
    obj["Bias"] = bias;

    obj["Subrs"] = [];
    for (int i = 0; i < gsubinds.length - 1; i++){
      obj["Subrs"].add(
        TyprBin.readBytes(data, offset + gsubinds[i], gsubinds[i + 1] - gsubinds[i])
      );
    }
  }

  static List<int> tableSE = [
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    1,
    2,
    3,
    4,
    5,
    6,
    7,
    8,
    9,
    10,
    11,
    12,
    13,
    14,
    15,
    16,
    17,
    18,
    19,
    20,
    21,
    22,
    23,
    24,
    25,
    26,
    27,
    28,
    29,
    30,
    31,
    32,
    33,
    34,
    35,
    36,
    37,
    38,
    39,
    40,
    41,
    42,
    43,
    44,
    45,
    46,
    47,
    48,
    49,
    50,
    51,
    52,
    53,
    54,
    55,
    56,
    57,
    58,
    59,
    60,
    61,
    62,
    63,
    64,
    65,
    66,
    67,
    68,
    69,
    70,
    71,
    72,
    73,
    74,
    75,
    76,
    77,
    78,
    79,
    80,
    81,
    82,
    83,
    84,
    85,
    86,
    87,
    88,
    89,
    90,
    91,
    92,
    93,
    94,
    95,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    96,
    97,
    98,
    99,
    100,
    101,
    102,
    103,
    104,
    105,
    106,
    107,
    108,
    109,
    110,
    0,
    111,
    112,
    113,
    114,
    0,
    115,
    116,
    117,
    118,
    119,
    120,
    121,
    122,
    0,
    123,
    0,
    124,
    125,
    126,
    127,
    128,
    129,
    130,
    131,
    0,
    132,
    133,
    0,
    134,
    135,
    136,
    137,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    138,
    0,
    139,
    0,
    0,
    0,
    0,
    140,
    141,
    142,
    143,
    0,
    0,
    0,
    0,
    0,
    144,
    0,
    0,
    0,
    145,
    0,
    0,
    146,
    147,
    148,
    149,
    0,
    0,
    0,
    0
  ];

  static int glyphByUnicode(cff, int code) {
    for (int i = 0; i < cff.charset.length; i++)
      if (cff.charset[i] == code) return i;
    return -1;
  }

  static int glyphBySE(cff, int charcode){
    if (charcode < 0 || charcode > 255) return -1;
    return glyphByUnicode(cff, tableSE[charcode]);
  }

  static List readEncoding(Uint8List data, int offset, int len) {
    List array = ['.notdef'];
    final format = data[offset];
    offset++;

    if (format == 0) {
      final nCodes = data[offset];
      offset++;
      for (int i = 0; i < nCodes; i++){
        array.add(data[offset + i]);
      }
    }
    else
      throw "error: unknown encoding format: $format";

    return array;
  }

  static List readCharset(Uint8List data, int offset, int len) {
    List charset = ['.notdef'];
    int format = data[offset];
    offset++;

    if (format == 0) {
      for (int i = 0; i < len; i++) {
        int first = TyprBin.readUshort(data, offset);
        offset += 2;
        charset.add(first);
      }
    } else if (format == 1 || format == 2) {
      while (charset.length < len) {
        int first = TyprBin.readUshort(data, offset);
        offset += 2;
        int nLeft = 0;
        if (format == 1) {
          nLeft = data[offset];
          offset++;
        } else {
          nLeft = TyprBin.readUshort(data, offset);
          offset += 2;
        }
        for (int i = 0; i <= nLeft; i++) {
          charset.add(first);
          first++;
        }
      }
    } else
      throw "error: format: $format";

    return charset;
  }

  static int readIndex(Uint8List data, int offset, List<int> inds) {
    int count = TyprBin.readUshort(data, offset) + 1;
    offset += 2;
    int offsize = data[offset];
    offset++;

    if (offsize == 1)
      for (int i = 0; i < count; i++) inds.add(data[offset + i]);
    else if (offsize == 2)
      for (int i = 0; i < count; i++)
        inds.add(TyprBin.readUshort(data, offset + i * 2));
    else if (offsize == 3)
      for (int i = 0; i < count; i++)
        inds.add(TyprBin.readUint(data, offset + i * 3 - 1) & 0x00ffffff);
    else if (count != 1)
      throw "unsupported offset size: $offsize, count: $count";

    offset += count * offsize;
    return offset - 1;
  }

  static void getCharString(List<int> data, int offset, o) {
    int _len = data.length;
    int? b0 = null;
    if (offset < _len) {
      b0 = data[offset];
    }

    int _offset1 = offset + 1;

    int? b1 = null;
    if (_offset1 < _len) {
      b1 = data[_offset1];
    }

    int vs = 1;
    var op = null, val = null;
    // operand
    if (b0 != null && b0 <= 20) {
      op = b0;
      vs = 1;
    }
    if (b0 != null && b0 == 12) {
      op = b0 * 100 + b1!;
      vs = 2;
    }
    //if(b0==19 || b0==20) { op = b0/*+" "+b1*/;  vs=2; }
    if (b0 != null && 21 <= b0 && b0 <= 27) {
      op = b0;
      vs = 1;
    }
    if (b0 == 28) {
      val = TyprBin.readShort(data, offset + 1);
      vs = 3;
    }
    if (b0 != null && 29 <= b0 && b0 <= 31) {
      op = b0;
      vs = 1;
    }
    if (b0 != null && 32 <= b0 && b0 <= 246) {
      val = b0 - 139;
      vs = 1;
    }
    if (b0 != null && 247 <= b0 && b0 <= 250) {
      val = (b0 - 247) * 256 + b1! + 108;
      vs = 2;
    }
    if (b0 != null && 251 <= b0 && b0 <= 254) {
      val = -(b0 - 251) * 256 - b1! - 108;
      vs = 2;
    }
    if (b0 != null && b0 == 255) {
      val = TyprBin.readInt(data, offset + 1) / 0xffff;
      vs = 5;
    }

    o["val"] = val != null ? val : "o" + op.toString();
    o["size"] = vs;
  }

  static List readCharString(Uint8List data, int offset, int length) {
    int end = offset + length;
    List arr = [];
    int _len = data.length;

    while (offset < end) {
      int? b0 = null;
      if (offset < _len) {
        b0 = data[offset];
      }

      int _offset1 = offset + 1;

      int? b1 = null;
      if (_offset1 < _len) {
        b1 = data[_offset1];
      }

      int vs = 1;
      var op = null, val = null;
      // operand
      if (b0 != null && b0 <= 20) {
        op = b0;
        vs = 1;
      }
      if (b0 != null && b0 == 12) {
        op = b0 * 100 + b1!;
        vs = 2;
      }
      if (b0 != null && b0 == 19 || b0 == 20) {
        op = b0 /*+" "+b1*/;
        vs = 2;
      }
      if (b0 != null && 21 <= b0 && b0 <= 27) {
        op = b0;
        vs = 1;
      }
      if (b0 != null && b0 == 28) {
        val = TyprBin.readShort(data, offset + 1);
        vs = 3;
      }
      if (b0 != null && 29 <= b0 && b0 <= 31) {
        op = b0;
        vs = 1;
      }
      if (b0 != null && 32 <= b0 && b0 <= 246) {
        val = b0 - 139;
        vs = 1;
      }
      if (b0 != null && 247 <= b0 && b0 <= 250) {
        val = (b0 - 247) * 256 + b1! + 108;
        vs = 2;
      }
      if (b0 != null && 251 <= b0 && b0 <= 254) {
        val = -(b0 - 251) * 256 - b1! - 108;
        vs = 2;
      }
      if (b0 != null && b0 == 255) {
        val = TyprBin.readInt(data, offset + 1) / 0xffff;
        vs = 5;
      }

      arr.add(val != null ? val : "o$op");
      offset += vs;
    }
    return arr;
  }

  static readDict(Uint8List data, int offset, int end) {
    Map<String,dynamic> dict = {};
    var carr = [];
    int _len = data.length;

    while (offset < end) {
      int? b0 = null;
      if (offset < _len) {
        b0 = data[offset];
      }

      int _offset1 = offset + 1;

      int? b1 = null;
      if (_offset1 < _len) {
        b1 = data[_offset1];
      }

      int vs = 1;
      var key = null, val = null;
      // operand
      if (b0 == 28) {
        val = TyprBin.readShort(data, offset + 1);
        vs = 3;
      }
      if (b0 == 29) {
        val = TyprBin.readInt(data, offset + 1);
        vs = 5;
      }
      if (b0 != null && 32 <= b0 && b0 <= 246) {
        val = b0 - 139;
        vs = 1;
      }
      if (b0 != null && b1 != null && 247 <= b0 && b0 <= 250) {
        val = (b0 - 247) * 256 + b1 + 108;
        vs = 2;
      }
      if (b0 != null && b1 != null && 251 <= b0 && b0 <= 254) {
        val = -(b0 - 251) * 256 - b1 - 108;
        vs = 2;
      }
      if (b0 == 255) {
        val = TyprBin.readInt(data, offset + 1) / 0xffff;
        vs = 5;
        throw "unknown number";
      }

      if (b0 == 30) {
        var nibs = [];
        vs = 1;
        while (true) {
          int b = data[offset + vs];
          vs++;
          int nib0 = b >> 4, nib1 = b & 0xf;
          if (nib0 != 0xf) nibs.add(nib0);
          if (nib1 != 0xf) nibs.add(nib1);
          if (nib1 == 0xf) break;
        }
        String s = "";
        List chars = [
          0,
          1,
          2,
          3,
          4,
          5,
          6,
          7,
          8,
          9,
          ".",
          "e",
          "e-",
          "reserved",
          "-",
          "endOfNumber"
        ];
        for (int i = 0; i < nibs.length; i++) s += chars[nibs[i]].toString();
        //console.warn(nibs);
        val = double.parse(s);
      }

      if (b0 != null && b0 <= 21){
        List keys = [
          "version",
          "Notice",
          "FullName",
          "FamilyName",
          "Weight",
          "FontBBox",
          "BlueValues",
          "OtherBlues",
          "FamilyBlues",
          "FamilyOtherBlues",
          "StdHW",
          "StdVW",
          "escape",
          "UniqueID",
          "XUID",
          "charset",
          "Encoding",
          "CharStrings",
          "Private",
          "Subrs",
          "defaultWidthX",
          "nominalWidthX"
        ];

        key = keys[b0];
        vs = 1;
        if (b0 == 12) {
          List keys = [
            "Copyright",
            "isFixedPitch",
            "ItalicAngle",
            "UnderlinePosition",
            "UnderlineThickness",
            "PaintType",
            "CharstringType",
            "FontMatrix",
            "StrokeWidth",
            "BlueScale",
            "BlueShift",
            "BlueFuzz",
            "StemSnapH",
            "StemSnapV",
            "ForceBold",
            0,
            0,
            "LanguageGroup",
            "ExpansionFactor",
            "initialRandomSeed",
            "SyntheticBase",
            "PostScript",
            "BaseFontName",
            "BaseFontBlend",
            0,
            0,
            0,
            0,
            0,
            0,
            "ROS",
            "CIDFontVersion",
            "CIDFontRevision",
            "CIDFontType",
            "CIDCount",
            "UIDBase",
            "FDArray",
            "FDSelect",
            "FontName"
          ];
          key = keys[b1!];
          vs = 2;
        }
      }

      if (key != null) {
        dict[key] = carr.length == 1 ? carr[0] : carr;
        carr = [];
      } else
        carr.add(val);

      offset += vs;
    }
    return dict;
  }
}
