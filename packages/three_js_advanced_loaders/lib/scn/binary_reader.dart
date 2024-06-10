

import 'dart:typed_data';

class BinaryReader {
  int _pos = 0;
  bool _eof = true;
  bool bigEndian;
  String encoding;
  late ByteBuffer buffer;

  BinaryReader(this.buffer, [this.bigEndian = false, this.encoding = '']);

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

  String readString(int length,[String? encoding]) {
    final start = _pos;
    _pos += length;
    final _encoding = encoding ?? this.encoding ?? 'sjis';
    //if(_Buffer.isEncoding(_encoding)){
    if(Buffer.isEncoding(_encoding)){
      return buffer.toString(_encoding, start, _pos);
    }

    final data = buffer.toString('binary', start, _pos);
    return _convert(data, _encoding);
  }

  int readInteger(int length, bool signed) {
    final start = _pos;
    _pos += length;

    // big endian
    if(bigEndian){
      if(signed){
        return buffer.readIntBE(start, length);
      }
      return buffer.readUIntBE(start, length);
    }

    // little endian
    if(signed){
      return buffer.readIntLE(start, length);
    }
    return buffer.readUIntLE(start, length);
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

  ByteBuffer readData(int length) {
    final start = _pos;
    _pos += length;
    return buffer.slice(start, _pos);
  }

  void _check() {
    if(_pos >= buffer.length){
      throw('_BinaryReader: buffer out of range ($_pos >= ${buffer.length})');
    }
  }

  String _escapeLE(Uint8List data) {
    final length = data.length;
    String escapeString = '';
    for(int i=0; i<length; i++){
      final charCode = data.charCodeAt(i);
      if(charCode == 0){
        break;
      }
      else if(charCode < 16){
        escapeString += '%0' + charCode.toString(16);
      }else{
        escapeString += '%' + charCode.toString(16);
      }
    }
    return escapeString;
  }

  String _escapeBE(data) {
    final length = data.length;
    String escapeString = '';
    for(int i=0; i<length; i++){
      final charCode1 = data.charCodeAt(i);
      if(charCode1 == 0){
        break;
      }
      String str1 = '';
      if(charCode1 < 16){
        str1 = '%0' + charCode1.toString(16);
      }else{
        str1 = '%' + charCode1.toString(16);
      }

      i++;
      final charCode2 = data.charCodeAt(i);
      if(charCode2 == 0){
        break;
      }
      String str2 = '';
      if(charCode2 < 16){
        str2 = '%0' + charCode2.toString(16);
      }else{
        str2 = '%' + charCode2.toString(16);
      }
      escapeString += str1 + str2;
    }
    return escapeString;
  }

  _convert(data, String encoding) {
    String escapeString = '';
    if(encoding == 'utf16be'){
      escapeString = _escapeBE(data);
    }else{
      escapeString = _escapeLE(data);
    }
      
    if(encoding == 'sjis'){
      return UnescapeSJIS(escapeString);
    }else if(encoding == 'euc-jp'){
      return UnescapeEUCJP(escapeString);
    }else if(encoding == 'jis-7'){
      return UnescapeJIS7(escapeString);
    }else if(encoding == 'jis-8'){
      return UnescapeJIS8(escapeString);
    }else if(encoding == 'unicode'){
      return UnescapeUnicode(escapeString);
    }else if(encoding == 'utf7'){
      return UnescapeUTF7(escapeString);
    }else if(encoding == 'utf-8'){
      return UnescapeUTF8(escapeString);
    }else if(encoding == 'utf-16'){
      return UnescapeUTF16LE(escapeString);
    }else if(encoding == 'utf16be'){
      return UnescapeUTF16LE(escapeString);
    }

    throw ('unsupported encoding: $encoding');
  }

  int getAvailableDataLength() {
    return buffer.length - _pos;
  }

  int get length => buffer.length;
}
