import 'dart:typed_data';
import '../bin.dart';

class Typr_OS2 {
  static Map<String, dynamic> parse(Uint8List data, int offset, int length) {
    int ver = TyprBin.readUshort(data, offset);
    offset += 2;

    Map<String, dynamic> obj = {};
    if (ver == 0)
      version0(data, offset, obj);
    else if (ver == 1)
      version1(data, offset, obj);
    else if (ver == 2 || ver == 3 || ver == 4)
      version2(data, offset, obj);
    else if (ver == 5)
      version5(data, offset, obj);
    else
      throw "unknown OS/2 table version: $ver";

    return obj;
  }

  static version0(Uint8List data, int offset, Map<String, dynamic> obj) {
    obj["xAvgCharWidth"] = TyprBin.readShort(data, offset);
    offset += 2;
    obj["usWeightClass"] = TyprBin.readUshort(data, offset);
    offset += 2;
    obj["usWidthClass"] = TyprBin.readUshort(data, offset);
    offset += 2;
    obj["fsType"] = TyprBin.readUshort(data, offset);
    offset += 2;
    obj["ySubscriptXSize"] = TyprBin.readShort(data, offset);
    offset += 2;
    obj["ySubscriptYSize"] = TyprBin.readShort(data, offset);
    offset += 2;
    obj["ySubscriptXOffset"] = TyprBin.readShort(data, offset);
    offset += 2;
    obj["ySubscriptYOffset"] = TyprBin.readShort(data, offset);
    offset += 2;
    obj["ySuperscriptXSize"] = TyprBin.readShort(data, offset);
    offset += 2;
    obj["ySuperscriptYSize"] = TyprBin.readShort(data, offset);
    offset += 2;
    obj["ySuperscriptXOffset"] = TyprBin.readShort(data, offset);
    offset += 2;
    obj["ySuperscriptYOffset"] = TyprBin.readShort(data, offset);
    offset += 2;
    obj["yStrikeoutSize"] = TyprBin.readShort(data, offset);
    offset += 2;
    obj["yStrikeoutPosition"] = TyprBin.readShort(data, offset);
    offset += 2;
    obj["sFamilyClass"] = TyprBin.readShort(data, offset);
    offset += 2;
    obj["panose"] = TyprBin.readBytes(data, offset, 10);
    offset += 10;
    obj["ulUnicodeRange1"] = TyprBin.readUint(data, offset);
    offset += 4;
    obj["ulUnicodeRange2"] = TyprBin.readUint(data, offset);
    offset += 4;
    obj["ulUnicodeRange3"] = TyprBin.readUint(data, offset);
    offset += 4;
    obj["ulUnicodeRange4"] = TyprBin.readUint(data, offset);
    offset += 4;
    obj["achVendID"] = [
      TyprBin.readInt8(data, offset),
      TyprBin.readInt8(data, offset + 1),
      TyprBin.readInt8(data, offset + 2),
      TyprBin.readInt8(data, offset + 3)
    ];
    offset += 4;
    obj["fsSelection"] = TyprBin.readUshort(data, offset);
    offset += 2;
    obj["usFirstCharIndex"] = TyprBin.readUshort(data, offset);
    offset += 2;
    obj["usLastCharIndex"] = TyprBin.readUshort(data, offset);
    offset += 2;
    obj["sTypoAscender"] = TyprBin.readShort(data, offset);
    offset += 2;
    obj["sTypoDescender"] = TyprBin.readShort(data, offset);
    offset += 2;
    obj["sTypoLineGap"] = TyprBin.readShort(data, offset);
    offset += 2;
    obj["usWinAscent"] = TyprBin.readUshort(data, offset);
    offset += 2;
    obj["usWinDescent"] = TyprBin.readUshort(data, offset);
    offset += 2;
    return offset;
  }

  static version1(Uint8List data, int offset, Map<String, dynamic> obj) {
    offset = version0(data, offset, obj);

    obj["ulCodePageRange1"] = TyprBin.readUint(data, offset);
    offset += 4;
    obj["ulCodePageRange2"] = TyprBin.readUint(data, offset);
    offset += 4;
    return offset;
  }

  static version2(Uint8List data, int offset, Map<String, dynamic> obj) {
    offset = version1(data, offset, obj);

    obj["sxHeight"] = TyprBin.readShort(data, offset);
    offset += 2;
    obj["sCapHeight"] = TyprBin.readShort(data, offset);
    offset += 2;
    obj["usDefault"] = TyprBin.readUshort(data, offset);
    offset += 2;
    obj["usBreak"] = TyprBin.readUshort(data, offset);
    offset += 2;
    obj["usMaxContext"] = TyprBin.readUshort(data, offset);
    offset += 2;
    return offset;
  }

  static version5(Uint8List data, int offset, Map<String, dynamic> obj) {
    offset = version2(data, offset, obj);

    obj["usLowerOpticalPointSize"] = TyprBin.readUshort(data, offset);
    offset += 2;
    obj["usUpperOpticalPointSize"] = TyprBin.readUshort(data, offset);
    offset += 2;
    return offset;
  }
}
