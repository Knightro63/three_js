import 'dart:typed_data';
import '../bin.dart';
import '../typr.dart';
import '../font.dart';

class Typr_GLYF {
  static List parse(Uint8List data, int offset, int length, font) {
    List obj = [];
    for (int g = 0; g < font["maxp"]["numGlyphs"]; g++){ 
      obj.add(null);
    }
    return obj;
  }

  static Map<String, dynamic>? parseGlyf(Font font, g) {
    Uint8List data = font.data;
    int offset = Typr.tabOffset(data, "glyf", font.offset) + font.loca[g] as int;

    if (font.loca[g] == font.loca[g + 1]) return null;

    Map<String, dynamic> gl = {};

    gl["noc"] = TyprBin.readShort(data, offset);
    offset += 2; // number of contours
    gl["xMin"] = TyprBin.readShort(data, offset);
    offset += 2;
    gl["yMin"] = TyprBin.readShort(data, offset);
    offset += 2;
    gl["xMax"] = TyprBin.readShort(data, offset);
    offset += 2;
    gl["yMax"] = TyprBin.readShort(data, offset);
    offset += 2;

    if (gl["xMin"] >= gl["xMax"] || gl["yMin"] >= gl["yMax"]) return null;

    if (gl["noc"] > 0) {
      gl["endPts"] = [];
      for (int i = 0; i < gl["noc"]; i++) {
        gl["endPts"].add(TyprBin.readUshort(data, offset));
        offset += 2;
      }

      int instructionLength = TyprBin.readUshort(data, offset);
      offset += 2;
      if ((data.length - offset) < instructionLength) return null;
      gl["instructions"] = TyprBin.readBytes(data, offset, instructionLength);
      offset += instructionLength;

      int crdnum = gl["endPts"][gl["noc"] - 1] + 1;
      gl["flags"] = [];
      for (int i = 0; i < crdnum; i++) {
        int flag = data[offset];
        offset++;
        gl["flags"].add(flag);
        if ((flag & 8) != 0) {
          int rep = data[offset];
          offset++;
          for (int j = 0; j < rep; j++) {
            gl["flags"].add(flag);
            i++;
          }
        }
      }
      gl["xs"] = List<int>.empty(growable: true);
      for (int i = 0; i < crdnum; i++) {
        bool i8 = ((gl["flags"][i] & 2) != 0),
            same = ((gl["flags"][i] & 16) != 0);
        if (i8) {
          gl["xs"].add(same ? data[offset] : -data[offset]);
          offset++;
        } else {
          if (same)
            gl["xs"].add(0);
          else {
            gl["xs"].add(TyprBin.readShort(data, offset));
            offset += 2;
          }
        }
      }
      gl["ys"] = List<int>.empty(growable: true);
      for (int i = 0; i < crdnum; i++) {
        bool i8 = ((gl["flags"][i] & 4) != 0),
            same = ((gl["flags"][i] & 32) != 0);
        if (i8) {
          gl["ys"].add(same ? data[offset] : -data[offset]);
          offset++;
        } else {
          if (same)
            gl["ys"].add(0);
          else {
            gl["ys"].add(TyprBin.readShort(data, offset));
            offset += 2;
          }
        }
      }
      int x = 0, y = 0;
      for (int i = 0; i < crdnum; i++) {
        int _xsi = gl["xs"][i];
        int _ysi = gl["ys"][i];
        x += _xsi;
        y += _ysi;
        gl["xs"][i] = x;
        gl["ys"][i] = y;
      }
      //console.warn(endPtsOfContours, instructionLength, instructions, flags, xCoordinates, yCoordinates);
    } else {
      int ARG_1_AND_2_ARE_WORDS = 1 << 0;
      int ARGS_ARE_XY_VALUES = 1 << 1;
      int WE_HAVE_A_SCALE = 1 << 3;
      int MORE_COMPONENTS = 1 << 5;
      int WE_HAVE_AN_X_AND_Y_SCALE = 1 << 6;
      int WE_HAVE_A_TWO_BY_TWO = 1 << 7;
      int WE_HAVE_INSTRUCTIONS = 1 << 8;

      gl["parts"] = [];
      int flags;
      do {
        flags = TyprBin.readUshort(data, offset);
        offset += 2;
        Map<String, dynamic> part = {
          "m": {"a": 1, "b": 0, "c": 0, "d": 1, "tx": 0, "ty": 0},
          "p1": -1,
          "p2": -1
        };
        gl["parts"].add(part);
        part["glyphIndex"] = TyprBin.readUshort(data, offset);
        offset += 2;

        int arg1;
        int arg2;

        if (flags & ARG_1_AND_2_ARE_WORDS != 0) {
          arg1 = TyprBin.readShort(data, offset);
          offset += 2;
          arg2 = TyprBin.readShort(data, offset);
          offset += 2;
        } else {
          arg1 = TyprBin.readInt8(data, offset);
          offset++;
          arg2 = TyprBin.readInt8(data, offset);
          offset++;
        }

        if (flags & ARGS_ARE_XY_VALUES != 0) {
          final _pm = part["m"];
          _pm["tx"] = arg1;
          _pm["ty"] = arg2;
        } else {
          part["p1"] = arg1;
          part["p2"] = arg2;
        }
        //part.m.tx = arg1;  part.m.ty = arg2;
        //else { throw "params are not XY values"; }

        if (flags & WE_HAVE_A_SCALE != 0) {
          part["m"]["a"] = part["m"]["d"] = TyprBin.readF2dot14(data, offset);
          offset += 2;
        } else if (flags & WE_HAVE_AN_X_AND_Y_SCALE != 0) {
          part["m"]["a"] = TyprBin.readF2dot14(data, offset);
          offset += 2;
          part["m"]["d"] = TyprBin.readF2dot14(data, offset);
          offset += 2;
        } else if (flags & WE_HAVE_A_TWO_BY_TWO != 0) {
          part["m"]["a"] = TyprBin.readF2dot14(data, offset);
          offset += 2;
          part["m"]["b"] = TyprBin.readF2dot14(data, offset);
          offset += 2;
          part["m"]["c"] = TyprBin.readF2dot14(data, offset);
          offset += 2;
          part["m"]["d"] = TyprBin.readF2dot14(data, offset);
          offset += 2;
        }
      } while (flags & MORE_COMPONENTS != 0);

      if (flags & WE_HAVE_INSTRUCTIONS != 0) {
        int numInstr = TyprBin.readUshort(data, offset);
        offset += 2;
        gl["instr"] = [];
        for (int i = 0; i < numInstr; i++) {
          gl["instr"].add(data[offset]);
          offset++;
        }
      }
    }
    return gl;
  }
}
