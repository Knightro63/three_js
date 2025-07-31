import 'dart:typed_data';
import 'dart:math' as math;
import 'package:three_js_core/three_js_core.dart';
import 'binary_reader.dart';

const debug = false;
//final Map<String,dynamic> _classForKey = {};

class BPlist{
  static late int uid;
  static const int maxObjectSize = 100 * 1000 * 1000; // 100Meg
  static const int maxObjectCount = 32768;

  // EPOCH = new SimpleDateFormat("yyyy MM dd zzz").parse("2001 01 01 GMT").getTime();
  // ...but that's annoying in a static initializer because it can throw exceptions, ick.
  // So we just hardcode the correct value.
  static const int epoc = 978307200000;

  static Map parseBuffer(Uint8List buffer) {
    // check header
    final header = String.fromCharCodes(buffer.sublist(0, 'bplist'.length));
    if (header != 'bplist') {
      throw("Invalid binary plist. Expected 'bplist' at offset 0.");
    }

    // Handle trailer, last 32 bytes of the file
    final trailer = buffer.sublist(buffer.length - 32, buffer.length);
    // 6 null bytes (index 0 to 5)
    final int offsetSize = trailer.readUintLE(6,1);
    if (debug) {
      console.info("offsetSize: $offsetSize");
    }
    final int objectRefSize = trailer.readUintLE(7,1);
    if (debug) {
      console.info("objectRefSize: $objectRefSize");
    }
    final numObjects = trailer.readUintBE(8,8);
    if (debug) {
      console.info("numObjects: $numObjects");
    }
    final topObject = trailer.readUintBE(16,8);
    if (debug) {
      console.info("topObject: $topObject");
    }
    final offsetTableOffset = trailer.readUintBE(24,8);
    if (debug) {
      console.info("offsetTableOffset: $offsetTableOffset");
    }

    if (numObjects > maxObjectCount) {
      throw("maxObjectCount exceeded");
    }

    // Handle offset table
    final List<int> offsetTable = [];

    for (int i = 0; i < numObjects; i++) {
      final offsetBytes = buffer.sublist(offsetTableOffset + i * offsetSize, offsetTableOffset + (i + 1) * offsetSize);
      offsetTable.add(readUInt(offsetBytes));
      if (debug) {
        console.info("Offset for Object #$i is ${offsetTable[i]} [${offsetTable[i].toStringAsFixed(16)}]");
      }
    }

    // Parses an object inside the currently parsed binary property list.
    // For the format specification check
    // <a href="https://www.opensource.apple.com/source/CF/CF-635/CFBinaryPList.c">
    // Apple's binary property list parser implementation</a>.
    dynamic parseObject(tableOffset) {
      final offset = offsetTable[tableOffset];
      final type = buffer[offset];
      final objType = (type & 0xF0) >> 4; //First  4 bits
      final objInfo = (type & 0x0F);      //Second 4 bits

      bool? parseSimple() {
        //Simple
        switch (objInfo) {
        case 0x0: // null
          return null;
        case 0x8: // false
          return false;
        case 0x9: // true
          return true;
        case 0xF: // filler byte
          return null;
        default:
          throw("Unhandled simple type 0x${objType.toStringAsFixed(16)}");
        }
      }

      String bufferToHexString(Uint8List buffer) {
        String str = '';
        int i;
        for (i = 0; i < buffer.length; i++) {
          if (buffer[i] != 0x00) {
            break;
          }
        }
        for (; i < buffer.length; i++) {
          final part = '00${buffer[i].toStringAsFixed(16)}';
          str += part.substring(part.length - 2);
        }
        return str;
      }

      int parseInteger() {
        final int length = math.pow(2, objInfo).toInt();
        if (length < maxObjectSize) {
          final data = buffer.sublist(offset + 1, offset + 1 + length);
          if (length == 16) {
            final str = bufferToHexString(data);
            return int.parse(str,radix: 16);
          }
          return data.reduce((acc, curr){
            acc <<= 8;
            acc |= curr & 255;
            return acc;
          });
        }
          throw("Too little heap space available! Wanted to read $length bytes, but only $maxObjectSize are available.");

      }

      int parseUID() {
        final int length = objInfo + 1;
        if (length < maxObjectSize) {
          uid = readUInt(buffer.sublist(offset + 1, offset + 1 + length));
          return uid;
        }
        throw ("Too little heap space available! Wanted to read $length bytes, but only $maxObjectSize are available.");
      }

      double? parseReal() {
        final int length = math.pow(2, objInfo).toInt();
        if (length < maxObjectSize) {
          final realBuffer = buffer.sublist(offset + 1, offset + 1 + length);
          if (length == 4) {
            return realBuffer.readFloatBE(0);
          }
          if (length == 8) {
            return realBuffer.readDoubleBE(0);
          }
        } else {
          throw ("Too little heap space available! Wanted to read $length bytes, but only $maxObjectSize are available.");
        }

        return null;
      }

      String parseDate() {
        if (objInfo != 0x3) {
          console.error("Unknown date type :$objInfo. Parsing anyway...");
        }
        final dateBuffer = buffer.sublist(offset + 1, offset + 9);
        return DateTime.fromMillisecondsSinceEpoch(epoc + (1000 * dateBuffer.readDoubleBE(0)).toInt()).toString();
      }

      Uint8List parseData() {
        int dataoffset = 1;
        int length = objInfo;
        if (objInfo == 0xF) {
          final intType_ = buffer[offset + 1];
          final intType = (intType_ & 0xF0) / 0x10;
          if (intType != 0x1) {
            console.error("0x4: UNEXPECTED LENGTH-INT TYPE! $intType");
          }
          final intInfo = intType_ & 0x0F;
          final intLength = math.pow(2, intInfo).toInt();
          dataoffset = 2 + intLength;
          if (intLength < 3) {
            length = readUInt(buffer.sublist(offset + 2, offset + 2 + intLength));
          } else {
            length = readUInt(buffer.sublist(offset + 2, offset + 2 + intLength));
          }
        }
        if (length < maxObjectSize) {
          return buffer.sublist(offset + dataoffset, offset + dataoffset + length);
        }
        throw ("Too little heap space available! Wanted to read $length bytes, but only $maxObjectSize are available.");
      }

      String parsePlistString ([bool isUtf16 = false]) {
        int utf16 = isUtf16?1:0;
        //String enc = "utf8";
        int length = objInfo;
        int stroffset = 1;
        if (objInfo == 0xF) {
          final intType_ = buffer[offset + 1];
          final intType = (intType_ & 0xF0) / 0x10;
          if (intType != 0x1) {
            console.error("UNEXPECTED LENGTH-INT TYPE! $intType");
          }
          final intInfo = intType_ & 0x0F;
          final intLength = math.pow(2, intInfo).toInt();
          stroffset = 2 + intLength;
          if (intLength < 3) {
            length = readUInt(buffer.sublist(offset + 2, offset + 2 + intLength));
          } else {
            length = readUInt(buffer.sublist(offset + 2, offset + 2 + intLength));
          }
        }
        // length is String length -> to get byte length multiply by 2, as 1 character takes 2 bytes in UTF-16
        length *= (utf16 + 1);
        if (length < maxObjectSize) {
          Uint8List plistString = buffer.sublist(offset + stroffset, offset + stroffset + length);
          if (isUtf16) {
            plistString = swapBytes(plistString);
            //enc = "ucs2";
          }
          return '"${String.fromCharCodes(plistString)}"';
        }
        throw ("Too little heap space available! Wanted to read $length bytes, but only $maxObjectSize are available.");
      }

      List parseArray() {
        int length = objInfo;
        int arrayoffset = 1;
        if (objInfo == 0xF) {
          final intType_ = buffer[offset + 1];
          final intType = (intType_ & 0xF0) ~/ 0x10;
          if (intType != 0x1) {
            console.error("0xa: UNEXPECTED LENGTH-INT TYPE! $intType");
          }
          final intInfo = intType_ & 0x0F;
          final intLength = math.pow(2, intInfo).toInt();
          arrayoffset = 2 + intLength;
          if (intLength < 3) {
            length = readUInt(buffer.sublist(offset + 2, offset + 2 + intLength));
          } else {
            length = readUInt(buffer.sublist(offset + 2, offset + 2 + intLength));
          }
        }
        if (length * objectRefSize > maxObjectSize) {
          throw("Too little heap space available!");
        }
        final array = [];
        for (int i = 0; i < length; i++) {
          final objRef = readUInt(buffer.sublist(offset + arrayoffset + i * objectRefSize, offset + arrayoffset + (i + 1) * objectRefSize));
          array.add(parseObject(objRef));
        }
        return array;
      }

      Map parseDictionary() {
        int length = objInfo;
        int dictoffset = 1;
        if (objInfo == 0xF) {
          final intType_ = buffer[offset + 1];
          final intType = (intType_ & 0xF0) ~/ 0x10;
          if (intType != 0x1) {
            console.error("0xD: UNEXPECTED LENGTH-INT TYPE! $intType");
          }
          final intInfo = intType_ & 0x0F;
          final intLength = math.pow(2, intInfo).toInt();
          dictoffset = 2 + intLength;
          if (intLength < 3) {
            length = readUInt(buffer.sublist(offset + 2, offset + 2 + intLength));
          } else {
            length = readUInt(buffer.sublist(offset + 2, offset + 2 + intLength));
          }
        }
        if (length * 2 * objectRefSize > maxObjectSize) {
          throw("Too little heap space available!");
        }
        if (debug) {
          console.info("Parsing dictionary #$tableOffset");
        }

        Map dict = {};
        for (int i = 0; i < length; i++) {
          final keyRef = readUInt(buffer.sublist(offset + dictoffset + i * objectRefSize, offset + dictoffset + (i + 1) * objectRefSize));
          final valRef = readUInt(buffer.sublist(offset + dictoffset + (length * objectRefSize) + i * objectRefSize, offset + dictoffset + (length * objectRefSize) + (i + 1) * objectRefSize));
          final key = parseObject(keyRef);
          final val = parseObject(valRef);
          if (debug) {
            console.info("  DICT #$tableOffset: Mapped $key to $val");
          }
          dict[key] = val;
        }
        return dict;
      }

      switch (objType) {
        case 0x0:
          return parseSimple();
        case 0x1:
          return parseInteger();
        case 0x8:
          return parseUID();
        case 0x2:
          return parseReal();
        case 0x3:
          return parseDate();
        case 0x4:
          return parseData();
        case 0x5: // ASCII
          return parsePlistString();
        case 0x6: // UTF-16
          return parsePlistString(true);
        case 0xA:
          return parseArray();
        case 0xD:
          return parseDictionary();
        default:
          throw("Unhandled type 0x${objType.toStringAsFixed(16)}");
      }
    }

    return parseObject(topObject);
  }

  static int readUInt(Uint8List buffer, [int? start]) {
    start = start ?? 0;

    int l = 0;
    for (int i = start; i < buffer.length; i++) {
      l <<= 8;
      l |= buffer[i] & 0xFF;
    }
    return l;
  }

  static Uint8List swapBytes(Uint8List buffer) {
    final len = buffer.length;
    for (int i = 0; i < len; i += 2) {
      final a = buffer[i];
      buffer[i] = buffer[i+1];
      buffer[i+1] = a;
    }
    return buffer;
  }

  // _parseClassAt(Map parsedObj,int index) async {
  //   final obj = parsedObj[r'$objects'][index];
  //   final data = _parseClass(obj);
  //   return data;
  // }

  // dynamic _parseClass(obj) {
  //   final className = obj[r'$class'].obj[r'$classname'];
  //   //print(`parseClass ${className}`)
  //   final classObj = classForClassName(className);
  //   if(classObj != null){
  //     final unarchiver = copy();
  //     unarchiver._refObj = obj;
  //     return classObj.initWithCoder(unarchiver);
  //   }
  //   return null;
  // }

  // static void setClassForClassName(cls, String codedName) {
  //   _classForKey[codedName] =  cls;
  // }

  // static dynamic classForClassName(codedName) {
  //   final classObj = _classForKey[codedName];
  //   if(classObj != null){
  //     return classObj;
  //   }
  //   //return _ClassList.get(codedName);
  // }
}