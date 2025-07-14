import 'dart:typed_data';
import '../bin.dart';

class Typr_NAME {
  static parse(Uint8List data, int offset, int length) {
    Map<String, dynamic> obj = {};
    offset += 2;
    int count = TyprBin.readUshort(data, offset);
    offset += 2;
    offset += 2;

    //console.warn(format,count);

    List<String> names = [
      "copyright",
      "fontFamily",
      "fontSubfamily",
      "ID",
      "fullName",
      "version",
      "postScriptName",
      "trademark",
      "manufacturer",
      "designer",
      "description",
      "urlVendor",
      "urlDesigner",
      "licence",
      "licenceURL",
      "---",
      "typoFamilyName",
      "typoSubfamilyName",
      "compatibleFull",
      "sampleText",
      "postScriptCID",
      "wwsFamilyName",
      "wwsSubfamilyName",
      "lightPalette",
      "darkPalette"
    ];

    int offset0 = offset;

    for (int i = 0; i < count; i++) {
      int platformID = TyprBin.readUshort(data, offset);
      offset += 2;
      int encodingID = TyprBin.readUshort(data, offset);
      offset += 2;
      int languageID = TyprBin.readUshort(data, offset);
      offset += 2;
      int nameID = TyprBin.readUshort(data, offset);
      offset += 2;
      int slen = TyprBin.readUshort(data, offset);
      offset += 2;
      int noffset = TyprBin.readUshort(data, offset);
      offset += 2;
      //console.warn(platformID, encodingID, languageID.toString(16), nameID, length, noffset);

      String? cname;
      if (nameID < names.length) {
        cname = names[nameID];
      }

      int soff = offset0 + count * 12 + noffset;
      String? str;
      if (platformID == 0)
        str = TyprBin.readUnicode(data, soff, slen ~/ 2);
      else if (platformID == 3 && encodingID == 0)
        str = TyprBin.readUnicode(data, soff, slen ~/ 2);
      else if (encodingID == 0)
        str = TyprBin.readASCII(data, soff, slen);
      else if (encodingID == 1)
        str = TyprBin.readUnicode(data, soff, slen ~/ 2);
      else if (encodingID == 3)
        str = TyprBin.readUnicode(data, soff, slen ~/ 2);
      else if (platformID == 1) {
        str = TyprBin.readASCII(data, soff, slen);
        print("reading unknown MAC encoding ${encodingID} as ASCII");
      } else {
        throw "unknown encoding ${encodingID}, platformID: ${platformID}";
      }

      String tid = "p${platformID},${languageID.toRadixString(16)}"; //Typr._platforms[platformID];
      if (obj[tid] == null) obj[tid] = {};
      obj[tid][cname != null ? cname : nameID] = str;
      obj[tid]["_lang"] = languageID;
    }

    for (final p in obj.keys) {
      if (obj[p]["postScriptName"] != null && obj[p]["_lang"] == 0x0409) {
        return obj[p];
      }
      // United States
    }
    for (final p in obj.keys)
      if (obj[p]["postScriptName"] != null && obj[p]["_lang"] == 0x0000) {
        return obj[p];
        // Universal
      }
    for (final p in obj.keys)
      if (obj[p]["postScriptName"] != null && obj[p]["_lang"] == 0x0c0c) {
        return obj[p]; // Canada
      }
    for (final p in obj.keys) {
      if (obj[p]["postScriptName"] != null) {
        return obj[p];
      }
    }

    String? tname;
    for (final p in obj.keys) {
      tname = p;
      break;
    }

    print("returning name table with languageID " + obj[tname]._lang);

    return obj[tname];
  }
}
