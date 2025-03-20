import 'dart:typed_data';
import 'dart:math' as math;
import 'dart:convert';

extension Buffer on Uint8List{
  static final _supportedEncoding = [
    'ascii',
    'utf8',
    'utf16le',
    'utf16be',
    'ucs2',
    'base64',
    'latin1',
    'binary',
    'hex'
  ];

  bool hasNeededBits(int neededBits){
    return buffer.asUint8List().length >= -(-neededBits >> 3);
  }
  void checkBuffer(int neededBits){
    if(!hasNeededBits(neededBits)){
      throw("checkBuffer::missing bytes");
    }
  }
  int readBits(int start, int length){
    //shl fix: Henri Torgemane ~1996 (compressed by Jonas Raoni)
    int shl(a, b){
      for(++b; --b; a = ((a %= 0x7fffffff + 1) & 0x40000000) == 0x40000000 ? a * 2 : (a - 0x40000000) * 2 + 0x7fffffff + 1);
      return a;
    }
    if(start < 0 || length <= 0){
      return 0;
    }

    checkBuffer(start + length);

    int sum = 0;
    List<int> buf = this;
    for(int offsetLeft, offsetRight = start % 8, curByte = length - (start >> 3) - 1,
      lastByte = buf.length + (-(start + buf.length) >> 3), diff = curByte - lastByte,
      sum = ((buf[ curByte ] >> offsetRight) & ((1 << (diff > 0 ? 8 - offsetRight : length)) - 1))
      + (diff > 0 && (offsetLeft = (start + length) % 8) > 0 ? (buf[ lastByte++ ] & ((1 << offsetLeft) - 1))
      << (diff-- << 3) - offsetRight : 0); diff > 0; sum += shl(buf[ lastByte++ ], (diff-- << 3) - offsetRight)
    );
    return sum;
  }
  int decodeInt(data, int bits, bool signed){
    // final b = new this.Buffer(this.bigEndian, data), x = b.readBits(0, bits), max = Math.pow(2, bits);
    // return signed && x >= max / 2 ? x - max : x;
    final x = readBits(0, bits);
    final max = math.pow(2, bits).toInt();
    return signed && x >= max / 2 ? x - max : x;
  }
  int readIntBE(int offset,int byteLength) {
    switch(byteLength){
      case 1:
        return buffer.asByteData().getInt8(offset);
      case 2:
        return buffer.asByteData().getInt16(offset, Endian.big);
      case 4:
        return buffer.asByteData().getInt32(offset, Endian.big);
    }
    final data = sublist(offset, offset + byteLength);
    return decodeInt(data, byteLength * 8, true);
  }

  int readIntLE(int offset,int byteLength) {
    switch(byteLength){
      case 1:
        return buffer.asByteData().getInt8(offset);
      case 2:
        return buffer.asByteData().getInt16(offset, Endian.little);
      case 4:
        return buffer.asByteData().getInt32(offset, Endian.little);
    }
    final data = sublist(offset, offset + byteLength);
    return decodeInt(data, byteLength * 8, true);
  }
  int readUintBE(int offset,int byteLength) {
    switch(byteLength){
      case 1:
        return buffer.asByteData().getInt8(offset);
      case 2:
        return buffer.asByteData().getInt16(offset, Endian.big);
      case 4:
        return buffer.asByteData().getInt32(offset, Endian.big);
    }
    final data = sublist(offset, offset + byteLength);
    return decodeInt(data, byteLength * 8, false);
  }

  int readUintLE(int offset,int byteLength) {
    switch(byteLength){
      case 1:
        return buffer.asByteData().getInt8(offset);
      case 2:
        return buffer.asByteData().getInt16(offset, Endian.little);
      case 4:
        return buffer.asByteData().getInt32(offset, Endian.little);
    }
    final data = sublist(offset, offset + byteLength);
    return decodeInt(data, byteLength * 8, false);
  }

  double readFloatBE(int offset) {
    return buffer.asByteData().getFloat32(offset, Endian.big);
  }

  double readFloatLE(int offset) {
    return buffer.asByteData().getFloat32(offset, Endian.little);
  }

  double readDoubleBE(int offset) {
    return buffer.asByteData().getFloat64(offset, Endian.big);
  }

  double readDoubleLE(int offset) {
    return buffer.asByteData().getFloat64(offset, Endian.little);
  }

  static bool isEncoding(String encoding) {
    return _supportedEncoding.contains(encoding);
  }
  String _hexBE(data, usePercent) {
    List<String> hexArray = [];
    for(int i=0; i<length; i+=2){
      final num1 = data[i+1].toStringAsFixed(16);
      if(data[i+1]<16){
        hexArray.add('0$num1');
      }else{
        hexArray.add(num1);
      }
      final num2 = data[i].toStringAsFixed(16);
      if(data[i]<16){
        hexArray.add('0$num2');
      }else{
        hexArray.add(num2);
      }
    }
    String pad = '';
    if(usePercent){
      pad = '%';
    }
    return hexArray.join(pad);
  }
  String _hex(usePercent) {
    final hexArray = map((n){
      if(n < 16){
        return '0${n.toStringAsFixed(16)}';
      }
      return n.toStringAsFixed(16);
    });
    String pad = '';
    if(usePercent){
      pad = '%';
    }
    return hexArray.join(pad);
  }
  String toEncodedString(String encoding) {
    if(!Buffer.isEncoding(encoding)){
      throw('unsupported encoding: $encoding');
    }
    if(encoding == 'binary'){
      return String.fromCharCodes(this);
    }else if(encoding == 'ascii' || encoding == 'latin1'){
      final len = sublist(0,1)[0];
      final daa = sublist(0, len);
      return String.fromCharCodes(daa);
    }else if(encoding == 'hex'){
      return _hex(false);
    }else if(encoding == 'base64'){
      final str = String.fromCharCodes(this);
      return utf8.fuse(base64).encode(str);
      //throw ('needs atob() function to convert to base64');
    }

    String str = '';
    if(encoding == 'utf16be'){
      str = _hexBE(sublist(0),true);
    }else{
      str = _hex(true);
    }
    if(encoding == 'utf8'){
      return String.fromCharCodes(utf8.encode(str));
    }else if(encoding == 'utf16le' || encoding == 'utf16be' || encoding == 'ucs2'){
      return str;
    }
    throw ('unsupported encoding: $encoding');
  }
}

class BinaryReader {
  int _pos = 0;
  //bool _eof = true;
  bool bigEndian;
  String? encoding;
  late Uint8List buffer;

  BinaryReader(this.buffer, [this.bigEndian = false, this.encoding]);

  void skip(int length, [bool noAssert = false]) {
    _pos += length;
    if(!noAssert){
      _check();
    }
  }

  void seek(int pos) {
    if(pos < 0){
      _pos = buffer.length + pos;
    }else{
      _pos = pos;
    }

    if(_pos < 0){
      _pos = 0;
    }else if(_pos > buffer.length){
      _pos = buffer.length;
    }
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

  String readString(int length,[String? encoding]) {
    //final start = _pos;
    _pos += length;
    Uint8List plistString = buffer.sublist(0);
    if (encoding == 'utf16be') {
      plistString = swapBytes(plistString);
    }
    return String.fromCharCodes(plistString);
  }

  int readInteger(int length, [bool signed = false]) {
    final start = _pos;
    _pos += length;

    // big endian
    if(bigEndian){
      if(signed){
        return buffer.readIntBE(start, length);
      }
      return buffer.readUintBE(start, length);
    }

    // little endian
    if(signed){
      return buffer.readIntLE(start, length);
    }
    return buffer.readUintLE(start, length);
  }

  int readUnsignedByte() {
    return readInteger(1, false);
  }

  int readUnsignedShort() {
    return readInteger(2, false);
  }

  int readUnsignedInt() {
    return readInteger(4, false);
  }

  int readUnsignedLongLong() {
    return readInteger(8, false);
  }

  int readByte() {
    return readInteger(1, true);
  }

  int readShort() {
    return readInteger(2, true);
  }

  int readInt() {
    return readInteger(4, true);
  }

  int readLongLong() {
    return readInteger(8, true);
  }

  double readFloat() {
    final start = _pos;
    _pos += 4;
    if(bigEndian){
      return buffer.readFloatBE(start);
    }

    return buffer.readFloatLE(start);
  }

  double readDouble() {
    final start = _pos;
    _pos += 8;
    if(bigEndian){
      return buffer.readDoubleBE(start);
    }

    return buffer.readDoubleLE(start);
  }

  Uint8List readData(int length) {
    final start = _pos;
    _pos += length;
    return buffer.sublist(start, _pos);
  }

  void _check() {
    if(_pos >= buffer.length){
      throw('_BinaryReader: buffer out of range ($_pos >= ${buffer.length})');
    }
  }

  String _escapeLE(String data) {
    final length = data.length;
    String escapeString = '';
    for(int i=0; i<length; i++){
      final charCode = data[i].codeUnitAt(0);
      if(charCode == 0){
        break;
      }
      else if(charCode < 16){
        escapeString += '%0${charCode.toStringAsFixed(16)}';
      }else{
        escapeString += '%${charCode.toStringAsFixed(16)}';
      }
    }
    return escapeString;
  }

  String _escapeBE(String data) {
    final length = data.length;
    String escapeString = '';
    for(int i=0; i<length; i++){
      final charCode1 = data[i].codeUnitAt(0);
      if(charCode1 == 0){
        break;
      }
      String str1 = '';
      if(charCode1 < 16){
        str1 = '%0${charCode1.toStringAsFixed(16)}';
      }else{
        str1 = '%${charCode1.toStringAsFixed(16)}';
      }

      i++;
      final charCode2 = data[i].codeUnitAt(0);
      if(charCode2 == 0){
        break;
      }
      String str2 = '';
      if(charCode2 < 16){
        str2 = '%0${charCode2.toStringAsFixed(16)}';
      }else{
        str2 = '%${charCode2.toStringAsFixed(16)}';
      }
      escapeString += str1 + str2;
    }
    return escapeString;
  }

  _convert(String data, String encoding) {
    // String escapeString = '';
    // if(encoding == 'utf16be'){
    //   escapeString = _escapeBE(data);
    // }else{
    //   escapeString = _escapeLE(data);
    // }

    return data;
      
    // if(encoding == 'sjis'){
    //   return UnescapeSJIS(escapeString);
    // }else if(encoding == 'euc-jp'){
    //   return UnescapeEUCJP(escapeString);
    // }else if(encoding == 'jis-7'){
    //   return UnescapeJIS7(escapeString);
    // }else if(encoding == 'jis-8'){
    //   return UnescapeJIS8(escapeString);
    // }else if(encoding == 'unicode'){
    //   return UnescapeUnicode(escapeString);
    // }else if(encoding == 'utf7'){
    //   return UnescapeUTF7(escapeString);
    // }else if(encoding == 'utf-8'){
    //   return UnescapeUTF8(escapeString);
    // }else if(encoding == 'utf-16'){
    //   return UnescapeUTF16LE(escapeString);
    // }else if(encoding == 'utf16be'){
    //   return UnescapeUTF16LE(escapeString);
    // }


    //throw ('unsupported encoding: $encoding');
  }

  int getAvailableDataLength() {
    return buffer.length - _pos;
  }

  int get length => buffer.length;
}
