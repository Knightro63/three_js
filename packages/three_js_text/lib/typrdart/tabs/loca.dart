import 'dart:typed_data';
import '../bin.dart';

class Typr_LOCA {
  static List<int> parse(Uint8List data, int offset, int length, font) {
    List<int> obj = [];
    int ver = font["head"]["indexToLocFormat"];
    int len = font["maxp"]["numGlyphs"] + 1;

    if (ver == 0)
      for (int i = 0; i < len; i++)
        obj.add(TyprBin.readUshort(data, offset + (i << 1)) << 1);
    if (ver == 1)
      for (int i = 0; i < len; i++)
        obj.add(TyprBin.readUint(data, offset + (i << 2)));

    return obj;
  }
}
